pragma solidity ^0.5.4;

import "ds-test/test.sol";

import "./Dpass.sol";

contract DpassTester {
    Dpass public _dpass;

    constructor(Dpass dpass) public {
        _dpass = dpass;
    }
}

contract DpassTest is DSTest {
    Dpass dpass;
    DpassTester user;

    function setUp() public {
        dpass = new Dpass();
        user = new DpassTester(dpass);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    // function test_symbol_func() public {
    //     // dpass.symbol();
    //     string memory r = dpass.symbol();
    //     assertEq0(r, "DP");
    // }

    function test_diamond_balance() public {
        dpass.mintDiamondTo(address(user), "7296159262", 710000000000000000, "");
        assertEq(dpass.balanceOf(address(user)), 1);
    }

    function test_diamond_cart_weight() public {
        dpass.mintDiamondTo(address(user), "7296159262", 710000000000000000, "");
        assertEq(dpass.diamondCaratByIndex(0), 710000000000000000);
    }
}
