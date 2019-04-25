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

    bytes32[] attributes = new bytes32[](15);


    function setUp() public {
        dpass = new Dpass();
        user = new DpassTester(dpass);

        attributes[0] = "0.71";
        attributes[1] = "8.06 - 8.17 x 5.10 mm";
        attributes[2] = "F";
        attributes[3] = "Internally Flawless";
        attributes[4] = "Excellent";
        attributes[5] = "62.8%";
        attributes[6] = "57%";
        attributes[7] = "36.5 °";
        attributes[8] = "16.0%";
        attributes[9] = "41.2°";
        attributes[10] = "43.5%";
        attributes[11] = "50%";
        attributes[12] = "80%";
        attributes[13] = "Medium to Slightly Thick, 3.5%";
        attributes[14] = "Very small";
        dpass.mintDiamondTo(address(user), "GIA1", 1 ether, true, attributes);
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
        assertEq(dpass.balanceOf(address(user)), 1);
    }

    function test_diamond_gia() public {
        assertEq32(dpass.getDiamondGia(0), "GIA1");
    }

    function testFail_non_owner_mint_diamond() public {
        dpass.setOwner(address(0));
        dpass.mintDiamondTo(address(user), "GIA1", 1 ether, true, attributes);
    }

    function test_ownership_of_new_diamond() public {
        assertEq(dpass.ownerOf(0), address(user));
    }

    function test_price_change() public {
        user.doSetPrice(0, 2 ether);
        assertEq(dpass.getPrice(0), 2 ether);
    }

    function test_sale_status_change() public {
        user.doSetSaleStatus(0, false);
        bytes32 gia;
        uint256 price;
        bool sale;
        bool redeemed;
        (gia, price, sale, redeemed) = dpass.getDiamond(0);
        assertTrue(!sale);
    }

    function test_redeem_status_change() public {
        user.doRedeem(0);
        bytes32 gia;
        uint256 price;
        bool sale;
        bool redeemed;
        (gia, price, sale, redeemed) = dpass.getDiamond(0);
        assertTrue(redeemed);
        assertEq(dpass.ownerOf(0), dpass.owner());
    }
}
