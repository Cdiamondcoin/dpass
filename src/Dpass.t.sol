pragma solidity ^0.5.11;

import "ds-test/test.sol";
import "./Dpass.sol";


contract DpassTester {
    Dpass public _dpass;

    constructor(Dpass dpass) public {
        _dpass = dpass;
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

    function doSetCustodian(uint tokenId, address newCustodian) public {
        _dpass.setCustodian(tokenId, newCustodian);
    }

    function doTransferFrom(address from, address to, uint256 tokenId) public {
        _dpass.transferFrom(from, to, tokenId);
    }

    function doSafeTransferFrom(address from, address to, uint256 tokenId) public {
        _dpass.safeTransferFrom(from, to, tokenId);
    }
}

contract DpassTest is DSTest {
    Dpass dpass;
    DpassTester user;
    bytes32[] attributes = new bytes32[](4);
    bytes8 hashingAlgorithm = "20190101";
    bytes32 attributesHash;
    address custodian;

    function setUp() public {
        dpass = new Dpass();
        user = new DpassTester(dpass);

        attributes[0] = "Round";
        attributes[1] = "0.71";
        attributes[2] = "F";
        attributes[3] = "IF";

        attributesHash = 0x9694b695489e1bc02e6a2358e56ac5c59c26e2ebe2fffffb7859c842f692e763;
        custodian = address(0xf);

        dpass.mintDiamondTo(
            address(user), custodian, "GIA", "01", "init", attributes, attributesHash, hashingAlgorithm
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
            address(user), custodian, "GIA", "02", "sale", attributes, attributesHash, hashingAlgorithm
        );
    }

    function testOwnershipOfNewDiamond() public {
        assertEq(dpass.ownerOf(1), address(user));
    }

    function testSaleStatusChange() public {
        user.doSetSaleStatus(1);
        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, state, attrs, attrsHash) = dpass.getDiamond(1);
        assertEq32(state, "sale");
        assertEq32(attrsHash, attributesHash);
    }

    function testRedeemStatusChange() public {
        user.doRedeem(1);
        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, state, attrs, attrsHash) = dpass.getDiamond(1);
        assertEq32(state, "redeemed");
        assertEq(dpass.ownerOf(1), dpass.owner());
    }

    function testAttributeValue() public {
        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report, state, attrs, attrsHash) = dpass.getDiamond(1);

        // Values
        assertEq(attrs[0], "Round");
        assertEq(attrs[1], "0.71");
        assertEq(attrs[2], "F");
        assertEq(attrs[3], "IF");
    }

    function testFailGetNonExistDiamond() public view {
        dpass.getDiamond(1000);
    }

    function testFailMintNonUniqDiamond() public {
        dpass.mintDiamondTo(
            address(user), custodian, "GIA", "01", "init", attributes, attributesHash, hashingAlgorithm
        );
    }

    function testLinkOldToNewToken() public {
        dpass.mintDiamondTo(
            address(user), custodian, "GIA", "02", "init", attributes, attributesHash, hashingAlgorithm
        );
        dpass.linkOldToNewToken(1, 2);
    }

    function testFailNotExistLinkOldToNewToken() public {
        dpass.mintDiamondTo(
            address(user), custodian, "GIA", "02", "init", attributes, attributesHash, hashingAlgorithm
        );
        dpass.linkOldToNewToken(1, 100);
    }

    function testChangeState() public {
        dpass.changeStateTo("new_state", 1);

        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32[] memory attrs;
        bytes32 attrsHash;

        (issuer, report,  state, attrs, attrsHash) = dpass.getDiamond(1);
        assertEq(state, "new_state");
    }

    function testFailNonOwnerChangeState() public {
        user.doChangeStateTo("new_state", 1);
    }

    function testSetCustodian() public {
        dpass.setCustodian(1, address(0xee));
        assertEq(dpass.getCustodian(1), address(0xee));
    }

    function testFailNonAuthSetCustodian() public {
        user.doSetCustodian(1, address(0xee));
    }

    function testTransfer() public {
        dpass.setCustodian(1, address(0xee));
        user.doTransferFrom(address(user), address(0xee), 1);
    }

    function testSafeTransfer() public {
        dpass.setCustodian(1, address(0xee));
        user.doSafeTransferFrom(address(user), address(0xee), 1);
    }
}
