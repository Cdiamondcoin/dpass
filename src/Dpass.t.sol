pragma solidity ^0.5.4;

import "ds-test/test.sol";

import "./Dpass.sol";

contract DpassTest is DSTest {
    Dpass dpass;

    function setUp() public {
        dpass = new Dpass();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
