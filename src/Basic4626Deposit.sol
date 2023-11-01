// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { console }       from "forge-std/console.sol";
import { Test }        from "forge-std/Test.sol";
import { StdUtils } from "forge-std/StdUtils.sol";
import { Vm }       from "forge-std/Vm.sol";

interface IERC20 {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when one account has set the allowance of another account over their tokens.
     *  @param owner_   Account that tokens are approved from.
     *  @param spender_ Account that tokens are approved for.
     *  @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
     *  @dev   Emitted when tokens have moved from one account to another.
     *  @param owner_     Account that tokens have moved from.
     *  @param recipient_ Account that tokens have moved to.
     *  @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Function that allows one account to set the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_ Account that tokens are approved for.
     *  @param  amount_  Amount of tokens that have been approved.
     *  @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to decrease the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_          Account that tokens are approved for.
     *  @param  subtractedAmount_ Amount to decrease approval by.
     *  @return success_          Boolean indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to increase the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_     Account that tokens are approved for.
     *  @param  addedAmount_ Amount to increase approval by.
     *  @return success_     Boolean indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_);

    /**
     *  @dev   Approve by signature.
     *  @param owner_    Owner address that signed the permit.
     *  @param spender_  Spender of the permit.
     *  @param amount_   Permit approval spend limit.
     *  @param deadline_ Deadline after which the permit is invalid.
     *  @param v_        ECDSA signature v component.
     *  @param r_        ECDSA signature r component.
     *  @param s_        ECDSA signature s component.
     */
    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     *  @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *          Emits a {Transfer} event.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *          Emits a {Transfer} event.
     *          Emits an {Approval} event.
     *  @param  owner_     Account that tokens are moving from.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the allowance that one account has given another over their tokens.
     *  @param  owner_     Account that tokens are approved from.
     *  @param  spender_   Account that tokens are approved for.
     *  @return allowance_ Allowance that one account has given another over their tokens.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     *  @dev    Returns the amount of tokens owned by a given account.
     *  @param  account_ Account that owns the tokens.
     *  @return balance_ Amount of tokens owned by a given account.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     *  @dev    Returns the decimal precision used by the token.
     *  @return decimals_ The decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domainSeparator_ The signature domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator_);

    /**
     *  @dev    Returns the name of the token.
     *  @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
      *  @dev    Returns the nonce for the given owner.
      *  @param  owner_  The address of the owner account.
      *  @return nonce_ The nonce for the given owner.
     */
    function nonces(address owner_) external view returns (uint256 nonce_);

    /**
     *  @dev    Returns the permit type hash.
     *  @return permitTypehash_ The permit type hash.
     */
    function PERMIT_TYPEHASH() external view returns (bytes32 permitTypehash_);

    /**
     *  @dev    Returns the symbol of the token.
     *  @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     *  @dev    Returns the total amount of tokens in existence.
     *  @return totalSupply_ The total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

}

contract ERC20 is IERC20 {

    /**************************************************************************************************************************************/
    /*** ERC-20                                                                                                                         ***/
    /**************************************************************************************************************************************/

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /**************************************************************************************************************************************/
    /*** ERC-2612                                                                                                                       ***/
    /**************************************************************************************************************************************/

    // PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public override nonces;

    /**
     *  @param name_     The name of the token.
     *  @param symbol_   The symbol of the token.
     *  @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function approve(address spender_, uint256 amount_) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) public virtual override returns (bool success_) {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function permit(address owner_, address spender_, uint256 amount_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        public virtual override
    {
        require(deadline_ >= block.timestamp, "ERC20:P:EXPIRED");

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(
            uint256(s_) <= uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) &&
            (v_ == 27 || v_ == 28),
            "ERC20:P:MALLEABLE"
        );

        // Nonce realistically cannot overflow.
        unchecked {
            bytes32 digest_ = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonces[owner_]++, deadline_))
                )
            );

            address recoveredAddress_ = ecrecover(digest_, v_, r_, s_);

            require(recoveredAddress_ == owner_ && owner_ != address(0), "ERC20:P:INVALID_SIGNATURE");
        }

        _approve(owner_, spender_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) public virtual override returns (bool success_) {
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function DOMAIN_SEPARATOR() public view override returns (bytes32 domainSeparator_) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked { totalSupply -= amount_; }

        emit Transfer(owner_, address(0), amount_);
    }

    function _decreaseAllowance(address owner_, address spender_, uint256 subtractedAmount_) internal {
        uint256 spenderAllowance = allowance[owner_][spender_];  // Cache to memory.

        if (spenderAllowance != type(uint256).max) {
            _approve(owner_, spender_, spenderAllowance - subtractedAmount_);
        }
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply += amount_;

        // Cannot overflow because totalSupply would first overflow in the statement above.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(address owner_, address recipient_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot overflow because minting prevents overflow of totalSupply, and sum of user balances == totalSupply.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(owner_, recipient_, amount_);
    }

}

contract MockERC20 is ERC20 {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_, decimals_) {}

    function mint(address recipient_, uint256 amount_) external {
        _mint(recipient_, amount_);
    }

    function burn(address owner_, uint256 amount_) external {
        _burn(owner_, amount_);
    }

}

interface IERC20Like {

    function balanceOf(address owner_) external view returns (uint256 balance_);

    function transferFrom(
        address owner_,
        address recipient_,
        uint256 amount_
    ) external returns (bool success_);

}

interface ILpHandlerLike {

    function lps(uint256 i) external view returns (address);

    function numCalls(bytes32 name) external view returns (uint256);

    function numLps() external view returns (uint256);

    function sumBalance() external view returns (uint256);

}

interface ITransferHandlerLike {

    function numCalls(bytes32 name) external view returns (uint256);

}

contract Basic4626Deposit {

    /**********************************************************************************************/
    /*** Storage                                                                                ***/
    /**********************************************************************************************/

    address public immutable asset;

    string public name;
    string public symbol;

    uint8 public immutable decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    /**********************************************************************************************/
    /*** Constructor                                                                            ***/
    /**********************************************************************************************/

    constructor(address asset_, string memory name_, string memory symbol_, uint8 decimals_) {
        asset    = asset_;
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

    /**********************************************************************************************/
    /*** External Functions                                                                     ***/
    /**********************************************************************************************/

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_) {
        shares_ = convertToShares(assets_);

        require(receiver_ != address(0), "ZERO_RECEIVER");
        require(shares_   != uint256(0), "ZERO_SHARES");
        require(assets_   != uint256(0), "ZERO_ASSETS");

        totalSupply += shares_;

        // Cannot overflow because totalSupply would first overflow in the statement above.
        unchecked { balanceOf[receiver_] += shares_; }

        require(
            IERC20Like(asset).transferFrom(msg.sender, address(this), assets_),
            "TRANSFER_FROM"
        );
    }

    function transfer(address recipient_, uint256 amount_) external returns (bool success_) {
        balanceOf[msg.sender] -= amount_;

        // Cannot overflow because minting prevents overflow of totalSupply,
        // and sum of user balances == totalSupply.
        unchecked { balanceOf[recipient_] += amount_; }

        return true;
    }

    /**********************************************************************************************/
    /*** Public View Functions                                                                  ***/
    /**********************************************************************************************/

    function convertToAssets(uint256 shares_) public view returns (uint256 assets_) {
        uint256 supply_ = totalSupply;  // Cache to stack.

        assets_ = supply_ == 0 ? shares_ : (shares_ * totalAssets()) / supply_;
    }

    function convertToShares(uint256 assets_) public view returns (uint256 shares_) {
        uint256 supply_ = totalSupply;  // Cache to stack.

        shares_ = supply_ == 0 ? assets_ : (assets_ * supply_) / totalAssets();
    }

    function totalAssets() public view returns (uint256 assets_) {
        assets_ = IERC20Like(asset).balanceOf(address(this));
    }

}

contract UnboundedLpHandler is StdUtils {

    address public currentLp;

    uint256 public numLps;
    uint256 public maxLps;

    address[] public lps;

    mapping(address => bool) public isLp;

    mapping(bytes32 => uint256) public numCalls;

    Basic4626Deposit public token;

    MockERC20 public asset;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 public sumBalance;

    modifier useRandomLp(uint256 lpIndex) {
        currentLp = lps[bound(lpIndex, 0, lps.length - 1)];

        vm.startPrank(currentLp);
        _;
        vm.stopPrank();
    }

    constructor(address asset_, address token_, uint256 maxLps_) {
        asset = MockERC20(asset_);
        token = Basic4626Deposit(token_);

        lps.push(address(1));
        numLps = 1;
        isLp[address(1)] = true;

        maxLps = maxLps_;
    }

    function addLp(address lp) public virtual {
        numCalls["unboundedLp.addLp"]++;

        // If the max has been reached, don't add LP.
        if (numLps == maxLps) {
            numCalls["unboundedLp.addLp.maxReached"]++;
            return;
        }

        // If the LP address is a duplicate, don't add LP.
        if (isLp[lp]) {
            numCalls["unboundedLp.addLp.duplicateLp"]++;
            return;
        }

        lps.push(lp);
        numLps++;

        isLp[lp] = true;  // Prevent duplicate LP addresses in array
    }

    function deposit(uint256 assets, uint256 lpIndex) useRandomLp(lpIndex) public virtual {
        numCalls["unboundedLp.deposit"]++;

        asset.mint(currentLp, assets);

        asset.approve(address(token), assets);

        uint256 shares = token.deposit(assets, currentLp);

        sumBalance += shares;
    }

    function transfer(uint256 assets, address receiver, uint256 lpIndex, uint256 receiverLpIndex) useRandomLp(lpIndex) public virtual {
        numCalls["unboundedLp.transfer"]++;

        // If the max has been reached, or the address is a duplicate, use an existing LP.
        // Else, add a new LP.
        if (numLps == maxLps || isLp[receiver]) {
            receiver = lps[bound(receiverLpIndex, 0, lps.length - 1)];
        } else {
            lps.push(receiver);
            isLp[receiver] = true;
            numLps++;
        }

        token.transfer(receiver, assets);
    }

}

contract BoundedLpHandler is UnboundedLpHandler {

    constructor(address asset_, address token_, uint256 maxLps_) UnboundedLpHandler(asset_, token_, maxLps_) { }

    function addLp(address lp) public override {
        numCalls["boundedLp.addLp"]++;

        if (lp == address(0)) {
            numCalls["boundedLp.addLp.zeroAddress"]++;
            return;
        }

        super.addLp(lp);
    }

    function deposit(uint256 assets, uint256 lpIndex) public override {
        numCalls["boundedLp.deposit"]++;

        uint256 totalSupply = token.totalSupply();

        uint256 minDeposit = totalSupply == 0 ? 1 : token.totalAssets() / totalSupply + 1;

        assets = bound(assets, minDeposit, 1e36);

        super.deposit(assets, lpIndex);
    }

    function transfer(uint256 assets, address receiver, uint256 lpIndex, uint256 receiverLpIndex) public override {
        numCalls["boundedLp.transfer"]++;

        // If receiver is address(0), use an existing LP address.
        if (receiver == address(0)) {
            receiver = lps[bound(receiverLpIndex, 0, lps.length - 1)];
        }

        // Calculate current LP that will be used in unbounded transfer.
        address currentLp = lps[bound(lpIndex, 0, lps.length - 1)];

        assets = bound(assets, 0, token.balanceOf(currentLp));

        super.transfer(assets, receiver, lpIndex, receiverLpIndex);
    }

}

contract UnboundedTransferHandler is StdUtils {

    mapping(bytes32 => uint256) public numCalls;

    Basic4626Deposit public token;

    MockERC20 public asset;

    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 public sumBalance;

    constructor(address asset_, address token_) {
        asset = MockERC20(asset_);
        token = Basic4626Deposit(token_);
    }

    function transferAssetToToken(address owner, uint256 assets) public virtual {
        numCalls["unboundedTransfer.transfer"]++;

        asset.mint(owner, assets);

        vm.prank(owner);
        asset.transfer(address(token), assets);
    }

}

contract BoundedTransferHandler is UnboundedTransferHandler {

    constructor(address asset_, address token_) UnboundedTransferHandler(asset_, token_) { }

    function transferAssetToToken(address owner, uint256 assets) public override {
        numCalls["boundedTransfer.transfer"]++;

        assets = bound(assets, 0, token.totalAssets() / 100);

        super.transferAssetToToken(owner, assets);
    }

}

contract Basic4626InvariantBase is Test {

    Basic4626Deposit public token;

    MockERC20 public asset;  // ERC-20 exposing `_mint` function

    ILpHandlerLike       public lpHandler;
    ITransferHandlerLike public transferHandler;

    function assert_invariant_A() public {
        assertGe(token.totalAssets(), token.totalSupply());
    }

    function assert_invariant_B() public {
        assertEq(token.totalAssets(), asset.balanceOf(address(token)));
    }

    function assert_invariant_C() public {
        assertEq(lpHandler.sumBalance(), token.totalSupply());
    }

    function assert_invariant_D_E_F() public {
        uint256 sumAssets;

        uint256 numLps      = lpHandler.numLps();
        uint256 totalAssets = token.totalAssets();
        uint256 totalSupply = token.totalSupply();

        if (totalAssets == 0 || totalSupply == 0) return;

        for (uint256 i = 0; i < numLps; i++) {
            address lp = lpHandler.lps(i);

            uint256 assetBalance = token.convertToAssets(token.balanceOf(lp));

            assertGe(assetBalance, token.balanceOf(lp));

            sumAssets += assetBalance;
        }

        assertGe(numLps, (token.totalAssets() - sumAssets));
    }

}

contract BoundedInvariants is Basic4626InvariantBase {

    function setUp() external {
        asset = new MockERC20("Asset", "ASSET", 18);

        token = new Basic4626Deposit(address(asset), "Token", "TOKEN", 18);

        lpHandler = ILpHandlerLike(address(new BoundedLpHandler(address(asset), address(token), 50)));

        transferHandler = ITransferHandlerLike(address(new BoundedTransferHandler(address(asset), address(token))));

        excludeContract(address(asset));
        excludeContract(address(token));
    }

    function invariant_A() external { assert_invariant_A(); }
    function invariant_B() external { assert_invariant_B(); }
    function invariant_C() external { assert_invariant_C(); }

    function invariant_D_E_F() external {
        assert_invariant_D_E_F();
    }

    function invariant_call_summary() external view {
        console.log("\nCall Summary\n");
        console.log("boundedLp.addLp         ", lpHandler.numCalls("boundedLp.addLp"));
        console.log("boundedLp.deposit       ", lpHandler.numCalls("boundedLp.deposit"));
        console.log("boundedLp.transfer      ", lpHandler.numCalls("boundedLp.transfer"));
        console.log("boundedTransfer.transfer", transferHandler.numCalls("boundedTransfer.transfer"));
        console.log("------------------");
        console.log(
            "Sum",
            lpHandler.numCalls("boundedLp.addLp") +
            lpHandler.numCalls("boundedLp.deposit") +
            lpHandler.numCalls("boundedLp.transfer") +
            transferHandler.numCalls("boundedTransfer.transfer")
        );
    }

}

contract UnboundedInvariants is Basic4626InvariantBase {

    function setUp() external {
        asset = new MockERC20("Asset", "ASSET", 18);

        token = new Basic4626Deposit(address(asset), "Token", "TOKEN", 18);

        lpHandler = ILpHandlerLike(address(new UnboundedLpHandler(address(asset), address(token), 50)));

        transferHandler = ITransferHandlerLike(address(new UnboundedTransferHandler(address(asset), address(token))));

        excludeContract(address(asset));
        excludeContract(address(token));
    }

    function invariant_A() external { assert_invariant_A(); }
    function invariant_B() external { assert_invariant_B(); }
    function invariant_C() external { assert_invariant_C(); }

    function invariant_call_summary() external view {
        console.log("\nCall Summary\n");
        console.log("unboundedLp.addLp         ", lpHandler.numCalls("unboundedLp.addLp"));
        console.log("unboundedLp.deposit       ", lpHandler.numCalls("unboundedLp.deposit"));
        console.log("unboundedLp.transfer      ", lpHandler.numCalls("unboundedLp.transfer"));
        console.log("unboundedTransfer.transfer", transferHandler.numCalls("unboundedTransfer.transfer"));
        console.log("------------------");
        console.log(
            "Sum",
            lpHandler.numCalls("unboundedLp.addLp") +
            lpHandler.numCalls("unboundedLp.deposit") +
            lpHandler.numCalls("unboundedLp.transfer") +
            transferHandler.numCalls("unboundedTransfer.transfer")
        );
    }

}

contract OpenInvariants is Basic4626InvariantBase {

    function setUp() external {
        asset = new MockERC20("Asset", "ASSET", 18);

        token = new Basic4626Deposit(address(asset), "Token", "TOKEN", 18);
    }

    function invariant_A() external { assert_invariant_A(); }
    function invariant_B() external { assert_invariant_B(); }

    function invariant_resulting_state() external view {
        console.log("\nResulting State\n");
        console.log("token.totalAssets", token.totalAssets());
        console.log("token.totalSupply", token.totalSupply());
        console.log("asset.totalSupply", asset.totalSupply());
    }

}