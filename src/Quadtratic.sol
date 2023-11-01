// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Quadratic {
    bool public ok = true;

    function notOkay(int x) external {
        if ((x - 11111) * (x - 11113) < 0) {
            ok = false;
        }
    }
}

contract Handler_2 is Test {
    Quadratic quadratic;

    constructor(Quadratic _quadratic) {
        quadratic = _quadratic;
    }

    function notOkay(int x) external {
        x = bound(x, 10_000, 100_000);
        quadratic.notOkay(x);
    }
}

contract InvariantQuadratic is Test {
    Quadratic quadratic;
    Handler_2 handler;

    function setUp() external {
        quadratic = new Quadratic();
        handler = new Handler_2(quadratic);

        targetContract(address(handler));
    }

    function invariant_NotOkay() external {
        assertTrue(quadratic.ok());
    }
}