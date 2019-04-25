pragma solidity ^0.5.4;

import "ds-test/test.sol";

import "./Dpass.sol";

contract DpassTester {
    Dpass public _dpass;

    constructor(Dpass dpass) public {
        _dpass = dpass;
    }

    function doSetPrice(uint256 token_id, uint price) public {
        _dpass.setPrice(token_id, price);
    }

    function doSetSaleStatus(uint256 token_id, bool sale) public {
        _dpass.setSaleStatus(token_id, sale);
    }

    function doRedeem(uint token_id) public {
        _dpass.redeem(token_id);
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
        assertEq0(bytes(dpass.symbol()), bytes("CDC PASS"));
    }

    function test_diamond_balance() public {
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
        assertEq(dpass.balanceOf(address(user)), 1);
    }

    function test_diamond_gia() public {
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
        assertEq0(bytes(dpass.getDiamondGia(0)), bytes("GIA1"));
    }

    function testFail_non_owner() public {
        dpass.setOwner(address(0));
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
    }

    function test_ownership_of_new_diamond() public {
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
        assertEq(dpass.ownerOf(0), address(user));
    }

    function test_price_change() public {
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
        user.doSetPrice(0, 2 ether);
        assertEq(dpass.getPrice(0), 2 ether);
    }

    function test_sale_status_change() public {
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
        user.doSetSaleStatus(0, false);
        bytes memory gia;
        uint256 carat;
        uint256 price;
        bool sale;
        bool redeemed;
        (gia, carat, price, sale, redeemed) = dpass.getDiamond(0);
        assertTrue(!sale);
    }

    function test_redeem_status_change() public {
        dpass.mintDiamondTo(address(user), "GIA1", 7100, 1 ether, true);
        user.doRedeem(0);
        bytes memory gia;
        uint256 carat;
        uint256 price;
        bool sale;
        bool redeemed;
        (gia, carat, price, sale, redeemed) = dpass.getDiamond(0);
        assertTrue(redeemed);
        assertEq(dpass.ownerOf(0), dpass.owner());
    }
}
