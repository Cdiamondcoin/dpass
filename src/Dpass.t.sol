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

    function test_symbol_func() public {
        assertEq0(bytes(dpass.symbol()), bytes("DP"));
    }

    function test_diamond_balance() public {
        dpass.mintDiamondTo(address(user), "7296159262", 710000000000000000, 1 ether);
        assertEq(dpass.balanceOf(address(user)), 1);
    }

    function test_diamond_gia() public {
        dpass.mintDiamondTo(address(user), "7296159262", 710000000000000000, 1 ether);
        assertEq0(bytes(dpass.getDiamondGia(0)), bytes("7296159262"));
    }

    function testFail_non_owner() public {
        dpass.setOwner(address(0));
        dpass.mintDiamondTo(address(user), "7296159262", 710000000000000000, 1 ether);
    }
}
