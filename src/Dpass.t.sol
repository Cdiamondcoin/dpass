pragma solidity ^0.5.10;

import "ds-test/test.sol";
import "./Dpass.sol";


contract DpassTester {
    Dpass public _dpass;

    constructor(Dpass dpass) public {
        _dpass = dpass;
    }

    function doSetOwnerPrice(uint tokenId, uint price) public {
        _dpass.setOwnerPrice(tokenId, price);
    }

    function doSetSaleStatus(uint tokenId) public {
        _dpass.setSaleStatus(tokenId);
    }

    function doRedeem(uint tokenId) public {
        _dpass.redeem(tokenId);
    }

    function doChangeStateTo(bytes32 state, uint tokenId) public {
        _dpass.changeStateTo(state, tokenId);
    }
}

contract DpassTest is DSTest {
    Dpass dpass;
    DpassTester user;
    bytes32[] attributes = new bytes32[](5);
    bytes8 hasningAlgorithm = "20190101";
    bytes32 attributesHash;

    function setUp() public {
        dpass = new Dpass();
        user = new DpassTester(dpass);

        attributes[0] = "Round";
        attributes[1] = "0.71";
        attributes[2] = "F";
        attributes[3] = "IF";
        attributes[4] = "Flawless";

        attributesHash = 0x9694b695489e1bc02e6a2358e56ac5c59c26e2ebe2fffffb7859c842f692e763;

        dpass.mintDiamondTo(
            address(user), "GIA", "01", 1 ether, 1 ether, "init", attributes, attributesHash, hasningAlgorithm
        );
    }

    function testFailBasicSanity() public {
        assertTrue(false);
    }

    function testBasicSanity() public {
        assertTrue(true);
    }

    function testSymbolFunc() public {
        assertEq0(bytes(dpass.symbol()), bytes("Dpass"));
    }

    function testDiamondBalance() public {
        assertEq(dpass.balanceOf(address(user)), 1);
    }

    function testDiamondIssuerAndReport() public {
        bytes32 issuer;
        bytes32 report;
        (issuer, report) = dpass.getDiamondIssuerAndReport(1);
        assertEq32(issuer, "GIA");
        assertEq32(report, "01");
    }

    function testFailNonOwnerMintDiamond() public {
        dpass.setOwner(address(0));
        dpass.mintDiamondTo(
            address(user), "GIA", "02", 1 ether, 1 ether, "sale", attributes, attributesHash, hasningAlgorithm
        );
    }

    function testOwnershipOfNewDiamond() public {
        assertEq(dpass.ownerOf(1), address(user));
    }

    function testPriceChange() public {
        user.doSetOwnerPrice(1, 2 ether);
        assertEq(dpass.getPrice(1), 2 ether);
    }

    function testSaleStatusChange() public {
        user.doSetSaleStatus(1);
        bytes32 issuer;
        bytes32 report;
        uint ownerPrice;
        uint marketplacePrice;
        bytes32 state;
        bytes32[] memory names;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, ownerPrice, marketplacePrice, state, names, attrs, attrsHash) = dpass.getDiamond(1);
        assertEq32(state, "sale");
        assertEq32(attrsHash, attributesHash);
    }

    function testRedeemStatusChange() public {
        user.doRedeem(1);
        bytes32 issuer;
        bytes32 report;
        uint ownerPrice;
        uint marketplacePrice;
        bytes32 state;
        bytes32[] memory names;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, ownerPrice, marketplacePrice, state, names, attrs, attrsHash) = dpass.getDiamond(1);
        assertEq32(state, "redeemed");
        assertEq(dpass.ownerOf(1), dpass.owner());
    }

    function testAttributeValue() public {
        bytes32 issuer;
        bytes32 report;
        uint ownerPrice;
        uint marketplacePrice;
        bytes32 state;
        bytes32[] memory names;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, ownerPrice, marketplacePrice, state, names, attrs, attrsHash) = dpass.getDiamond(1);
        bytes32[] memory defaultNames = dpass.getAttributeNames();

        // Values
        assertEq(attrs[0], "Round");
        assertEq(attrs[1], "0.71");
        assertEq(attrs[2], "F");
        assertEq(attrs[3], "IF");

        // Names
        assertEq(names[0], defaultNames[0]);
        assertEq(names[1], defaultNames[1]);
        assertEq(names[2], defaultNames[2]);
        assertEq(names[3], defaultNames[3]);
    }

    function testFailGetNonExistDiamond() public view {
        dpass.getDiamond(1000);
    }

    function testFailMintNonUniqDiamond() public {
        dpass.mintDiamondTo(
            address(user), "GIA", "01", 1 ether, 1 ether, "init", attributes, attributesHash, hasningAlgorithm
        );
    }

    function testLinkOldToNewToken() public {
        dpass.mintDiamondTo(
            address(user), "GIA", "02", 1 ether, 1 ether, "init", attributes, attributesHash, hasningAlgorithm
        );
        dpass.linkOldToNewToken(1, 2);
    }

    function testFailNotExistLinkOldToNewToken() public {
        dpass.mintDiamondTo(
            address(user), "GIA", "02", 1 ether, 1 ether, "init", attributes, attributesHash, hasningAlgorithm
        );
        dpass.linkOldToNewToken(1, 100);
    }

    function testChangeState() public {
        dpass.changeStateTo("new_state", 1);

        bytes32 issuer;
        bytes32 report;
        uint ownerPrice;
        uint marketplacePrice;
        bytes32 state;
        bytes32[] memory names;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, ownerPrice, marketplacePrice, state, names, attrs, attrsHash) = dpass.getDiamond(1);
        assertEq(state, "new_state");
    }

    function testFailNonOwnerChangeState() public {
        user.doChangeStateTo("new_state", 1);
    }

    function testgetAttributeNamesAsString() public {
        string memory names;
        names = dpass.getAttributeNamesAsString();
        assertEq0(bytes(names), bytes("shape;weight;color;clarity;cut;"));
    }
}
