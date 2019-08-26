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

    function doSetSaleStatus(uint256 token_id) public {
        _dpass.setSaleStatus(token_id);
    }

    function doRedeem(uint token_id) public {
        _dpass.redeem(token_id);
    }
}

contract DpassTest is DSTest {
    Dpass dpass;
    DpassTester user;

    bytes32[] attributes = new bytes32[](2);


    function setUp() public {
        dpass = new Dpass();
        user = new DpassTester(dpass);

        attributes[0] = "0.71";
        attributes[1] = "8.06 - 8.17 x 5.10 mm";
        // attributes[2] = "F";
        // attributes[3] = "Internally Flawless";
        // attributes[4] = "Excellent";
        // attributes[5] = "62.8%";
        // attributes[6] = "57%";
        // attributes[7] = "36.5 °";
        // attributes[8] = "16.0%";
        // attributes[9] = "41.2°";
        // attributes[10] = "43.5%";
        // attributes[11] = "50%";
        // attributes[12] = "80%";
        // attributes[13] = "Medium to Slightly Thick, 3.5%";
        // attributes[14] = "Very small";

        dpass.mintDiamondTo(address(user), "GIA", "01", 1 ether, "sale", attributes);
    }

    function testFailBasicSanity() public {
        assertTrue(false);
    }

    function testBasicSanity() public {
        assertTrue(true);
    }

    function testSymbolFunc() public {
        assertEq0(bytes(dpass.symbol()), bytes("CDC PASS"));
    }

    function testDiamondBalance() public {
        assertEq(dpass.balanceOf(address(user)), 1);
    }

    function testDiamondIssuerAndReport() public {
        bytes32 issuer;
        bytes32 report;
        (issuer, report) = dpass.getDiamondIssuerAndReport(0);
        assertEq32(issuer, "GIA");
        assertEq32(report, "01");
    }

    function testFailNonOwnerMintDiamond() public {
        dpass.setOwner(address(0));
        dpass.mintDiamondTo(address(user), "GIA", "02", 1 ether, "sale", attributes);
    }

    function testOwnershipOfNewDiamond() public {
        assertEq(dpass.ownerOf(0), address(user));
    }

    function testPriceChange() public {
        user.doSetPrice(0, 2 ether);
        assertEq(dpass.getPrice(0), 2 ether);
    }

    function testSaleStatusChange() public {
        user.doSetSaleStatus(0);
        bytes32 issuer;
        bytes32 report;
        uint256 price;
        bytes32 state;
        bytes32[] memory attrs;

        (issuer, report, price, state, attrs) = dpass.getDiamond(0);
        assertEq32(state, "sale");
    }

    function testRedeemStatusChange() public {
        user.doRedeem(0);
        bytes32 issuer;
        bytes32 report;
        uint256 price;
        bytes32 state;
        bytes32[] memory attrs;

        (issuer, report, price, state, attrs) = dpass.getDiamond(0);
        assertEq32(state, "redeemed");
        assertEq(dpass.ownerOf(0), dpass.owner());
    }
}
