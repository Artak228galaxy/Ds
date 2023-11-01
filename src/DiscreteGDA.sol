// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { Test }        from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "./utils/Console.sol";
import {PRBMathSD59x18} from "./utils/PRBMathSD59x18.sol";
import {Strings} from "./utils/Strings.sol";
import {ERC721} from "./utils/ERC721.sol";

//common utilities for forge tests
contract Utilities is Test {
    Vm internal immutable vmInstance = Vm(HEVM_ADDRESS);
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() external returns (address payable) {
        //bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    //create users with 100 ether balance
    function createUsers(uint256 userNum)
        external
        returns (address payable[] memory)
    {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddress();
            vmInstance.deal(user, 100 ether);
            users[i] = user;
        }
        return users;
    }

    //assert that two uints are approximately equal. tolerance in 1/10th of a percent
    function assertApproxEqual(
        uint256 expected,
        uint256 actual,
        uint256 tolerance
    ) public {
        uint256 leftBound = (expected * (1000 - tolerance)) / 1000;
        uint256 rightBound = (expected * (1000 + tolerance)) / 1000;
        assertTrue(leftBound <= actual && actual <= rightBound);
    }

    //move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vmInstance.roll(targetBlock);
    }
}

///@notice Implementation of Discrete GDA with exponential price decay for ERC721
abstract contract DiscreteGDA is ERC721 {
    using PRBMathSD59x18 for int256;

    ///@notice id of current ERC721 being minted
    uint256 public currentId = 0;

    /// -----------------------------
    /// ---- Pricing Parameters -----
    /// -----------------------------

    ///@notice parameter that controls initial price, stored as a 59x18 fixed precision number
    int256 internal immutable initialPrice;

    ///@notice parameter that controls how much the starting price of each successive auction increases by,
    /// stored as a 59x18 fixed precision number
    int256 internal immutable scaleFactor;

    ///@notice parameter that controls price decay, stored as a 59x18 fixed precision number
    int256 internal immutable decayConstant;

    ///@notice start time for all auctions, stored as a 59x18 fixed precision number
    int256 internal immutable auctionStartTime;

    error InsufficientPayment();

    error UnableToRefund();

    constructor(
        string memory _name,
        string memory _symbol,
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant
    ) ERC721(_name, _symbol) {
        initialPrice = _initialPrice;
        scaleFactor = _scaleFactor;
        decayConstant = _decayConstant;
        auctionStartTime = int256(block.timestamp).fromInt();
    }

    ///@notice purchase a specific number of tokens from the GDA
    function purchaseTokens(uint256 numTokens, address to) public payable {
        uint256 cost = purchasePrice(numTokens);
        if (msg.value < cost) {
            revert InsufficientPayment();
        }
        //mint all tokens
        for (uint256 i = 0; i < numTokens; i++) {
            _mint(to, ++currentId);
        }
        //refund extra payment
        uint256 refund = msg.value - cost;
        (bool sent, ) = msg.sender.call{value: refund}("");
        if (!sent) {
            revert UnableToRefund();
        }
    }

    ///@notice calculate purchase price using exponential discrete GDA formula
    function purchasePrice(uint256 numTokens) public view returns (uint256) {
        int256 quantity = int256(numTokens).fromInt();
        int256 numSold = int256(currentId).fromInt();
        int256 timeSinceStart = int256(block.timestamp).fromInt() -
            auctionStartTime;

        int256 num1 = initialPrice.mul(scaleFactor.pow(numSold));
        int256 num2 = scaleFactor.pow(quantity) - PRBMathSD59x18.fromInt(1);
        int256 den1 = decayConstant.mul(timeSinceStart).exp();
        int256 den2 = scaleFactor - PRBMathSD59x18.fromInt(1);
        int256 totalCost = num1.mul(num2).div(den1.mul(den2));
        //total cost is already in terms of wei so no need to scale down before
        //conversion to uint. This is due to the fact that the original formula gives
        //price in terms of ether but we scale up by 10^18 during computation
        //in order to do fixed point math.
        return uint256(totalCost);
    }
}

contract MockDiscreteGDA is DiscreteGDA {
    constructor(
        string memory _name,
        string memory _symbol,
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant
    )
        DiscreteGDA(_name, _symbol, _initialPrice, _scaleFactor, _decayConstant)
    {}

    function tokenURI(uint256)
        public
        pure
        virtual
        override
        returns (string memory)
    {}
}

///@notice test discrete GDA behaviour
///@dev run with --ffi flag to enable correctness tests
contract DiscreteGDATest is Test {
    using PRBMathSD59x18 for int256;
    using Strings for uint256;

    Vm internal immutable testVmInstance = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    MockDiscreteGDA internal gda;

    int256 public initialPrice = PRBMathSD59x18.fromInt(1000);
    int256 public decayConstant =
        PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(2));
    int256 public scaleFactor =
        PRBMathSD59x18.fromInt(11).div(PRBMathSD59x18.fromInt(10));

    //encodings for revert tests
    bytes insufficientPayment =
        abi.encodeWithSignature("InsufficientPayment()");

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        gda = new MockDiscreteGDA(
            "Token",
            "TKN",
            initialPrice,
            scaleFactor,
            decayConstant
        );
    }

    function testInitialPrice() public {
        //initialPrice should be price scale
        uint256 initial = uint256(initialPrice);
        uint256 purchasePrice = gda.purchasePrice(1);
        utils.assertApproxEqual(purchasePrice, initial, 1);
    }

    function testInsuffientPayment() public {
        uint256 purchasePrice = gda.purchasePrice(1);
        testVmInstance.deal(address(this), purchasePrice);
        testVmInstance.expectRevert(insufficientPayment);
        gda.purchaseTokens{value: purchasePrice - 1}(1, address(this));
    }

    function testMintCorrectly() public {
        assertTrue(gda.ownerOf(1) != address(this));
        uint256 purchasePrice = gda.purchasePrice(1);
        testVmInstance.deal(address(this), purchasePrice);
        gda.purchaseTokens{value: purchasePrice}(1, address(this));
        assertTrue(gda.ownerOf(1) == address(this));
    }

    function testRefund() public {
        uint256 purchasePrice = gda.purchasePrice(1);
        testVmInstance.deal(address(this), 2 * purchasePrice);
        //pay twice the purchase price
        gda.purchaseTokens{value: 2 * purchasePrice}(1, address(this));
        //purchase price should have been refunded
        assertTrue(address(this).balance == purchasePrice);
    }

    function testFFICorrectnessOne() public {
        uint256 numTotalPurchases = 1;
        uint256 timeSinceStart = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    function testFFICorrectnessTwo() public {
        uint256 numTotalPurchases = 2;
        uint256 timeSinceStart = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    function testFFICorrectnessThree() public {
        uint256 numTotalPurchases = 4;
        uint256 timeSinceStart = 10;
        uint256 quantity = 9;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    function testFFICorrectnessFour() public {
        uint256 numTotalPurchases = 20;
        uint256 timeSinceStart = 100;
        uint256 quantity = 1;
        checkPriceWithParameters(
            initialPrice,
            scaleFactor,
            decayConstant,
            numTotalPurchases,
            timeSinceStart,
            quantity
        );
    }

    //parametrized test helper
    function checkPriceWithParameters(
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant,
        uint256 _numTotalPurchases,
        uint256 _timeSinceStart,
        uint256 _quantity
    ) private {
        MockDiscreteGDA _gda = new MockDiscreteGDA(
            "Token",
            "TKN",
            _initialPrice,
            _scaleFactor,
            _decayConstant
        );

        //make past pruchases
        uint256 purchasePrice = _gda.purchasePrice(_numTotalPurchases);
        testVmInstance.deal(address(this), purchasePrice);
        _gda.purchaseTokens{value: purchasePrice}(
            _numTotalPurchases,
            address(this)
        );

        //move time forward
        testVmInstance.warp(block.timestamp + _timeSinceStart);
        //calculate actual price from gda
        uint256 actualPrice = _gda.purchasePrice(_quantity);
        //calculate expected price from python script
        uint256 expectedPrice = calculatePrice(
            _initialPrice,
            _scaleFactor,
            _decayConstant,
            _numTotalPurchases,
            _timeSinceStart,
            _quantity
        );
        //equal within 0.1%
        utils.assertApproxEqual(actualPrice, expectedPrice, 1);
    }

    //call out to python script for price computation
    function calculatePrice(
        int256 _initialPrice,
        int256 _scaleFactor,
        int256 _decayConstant,
        uint256 _numTotalPurchases,
        uint256 _timeSinceStart,
        uint256 _quantity
    ) private returns (uint256) {
        string[] memory inputs = new string[](15);
        inputs[0] = "python3";
        inputs[1] = "analysis/compute_price.py";
        inputs[2] = "exp_discrete";
        inputs[3] = "--initial_price";
        inputs[4] = uint256(_initialPrice).toString();
        inputs[5] = "--scale_factor";
        inputs[6] = uint256(_scaleFactor).toString();
        inputs[7] = "--decay_constant";
        inputs[8] = uint256(_decayConstant).toString();
        inputs[9] = "--num_total_purchases";
        inputs[10] = _numTotalPurchases.toString();
        inputs[11] = "--time_since_start";
        inputs[12] = _timeSinceStart.toString();
        inputs[13] = "--quantity";
        inputs[14] = _quantity.toString();
        bytes memory res = vm.ffi(inputs);
        uint256 price = abi.decode(res, (uint256));
        return price;
    }

    //make payable
    fallback() external payable {}
}