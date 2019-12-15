pragma solidity ^0.5.11;

import "ds-test/test.sol";
import "./Dpass.sol";


contract DpassTester {
    Dpass public _dpass;

    constructor(Dpass dpass) public {
        _dpass = dpass;
    }

    function doSetSaleState(uint tokenId) public {
        _dpass.setSaleState(tokenId);
    }

    function doRedeem(uint tokenId) public {
        _dpass.redeem(tokenId);
    }

    function doSetState(bytes8 state, uint tokenId) public {
        _dpass.setState(state, tokenId);
    }

    function doSetCustodian(uint tokenId, address newCustodian) public {
        _dpass.setCustodian(tokenId, newCustodian);
    }

    function doSetAllowedCccc(bytes32 _cccc, bool allow) public {
        _dpass.setCccc(_cccc, allow);
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
    address user;
    bytes20 cccc;
    uint24 carat;
    bytes8 hashingAlgorithm = "20190101";
    bytes32 attributesHash;
    address custodian; 

    event LogTest(uint256 what);
    event LogTest(bool what);
    event LogTest(address what);
    event LogTest(bytes32 what);
    
    function setUp() public {
        dpass = new Dpass();
        user = address(new DpassTester(dpass));
        custodian = address(new DpassTester(dpass));

        cccc = "BR,IF,F,0004";
        carat = 7;

        attributesHash = 0x9694b695489e1bc02e6a2358e56ac5c59c26e2ebe2fffffb7859c842f692e763;
        dpass.setCccc(cccc, true);
        dpass.mintDiamondTo(
            user, custodian, "GIA", "01", "valid", cccc, carat, attributesHash, hashingAlgorithm
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
        assertEq(dpass.balanceOf(user), 1);
    }

    function testOwnerMintDiamond() public logs_gas {
        uint gas = gasleft();
        dpass.mintDiamondTo(
            user, custodian, "GIA", "02", "sale", cccc, carat, attributesHash, hashingAlgorithm
        );
        emit LogTest(gas - gasleft());
    }

    function testFailNonOwnerMintDiamond() public {
        dpass.setOwner(address(0));
        dpass.mintDiamondTo(
            user, custodian, "GIA", "02", "sale", cccc, carat, attributesHash, hashingAlgorithm
        );
    }

    function testGetDiamondAll() public {
        address[2] memory ownerCustodian;
        bytes32[6] memory attrs;
        uint24 carat_;
        (ownerCustodian, attrs, carat_) = dpass.getDiamondInfo(1);

        assertEq(attrs[0], "GIA");
        assertEq(attrs[1], "01");
        assertEq(attrs[2], "valid");
        assertEq(attrs[3], cccc);
        assertEq(attrs[4], attributesHash);
        assertEq(attrs[5], hashingAlgorithm);

        assertEq(ownerCustodian[0], user);
        assertEq(ownerCustodian[1], custodian);

        assertEq(uint(carat_), uint(carat));
    }

    function testOwnershipOfNewDiamond() public {
        assertEq(dpass.ownerOf(1), user);
    }

    function testSetSaleState() public {
        DpassTester(user).doSetSaleState(1);
        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32 _cccc;
        uint24 _carat;
        bytes32 attrsHash;

        (issuer, report, state, _cccc, _carat, attrsHash) = dpass.getDiamond(1);
        assertEq32(state, "sale");
        assertEq32(attrsHash, attributesHash);
    }

    function testSetRedeemState() public {
        DpassTester(user).doRedeem(1);
        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32 _cccc;
        uint24 _carat;
        bytes32 attrsHash;

        (issuer, report, state, _cccc, _carat, attrsHash) = dpass.getDiamond(1);
        assertEq32(state, "redeemed");
        assertEq(dpass.ownerOf(1), user);
    }

    function testAttributeValue() public {
        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32 _cccc;
        uint24 _carat;
        bytes32 attrsHash;

        (issuer, report, state, _cccc, _carat, attrsHash) = dpass.getDiamond(1);

        // Values
        assertEq(_cccc, "BR,IF,F,0004");
        assertEq(uint(_carat), 7);
    }

    function testFailGetNonExistDiamond() public view {
        dpass.getDiamond(1000);
    }

    function testFailMintNonUniqDiamond() public {
        dpass.mintDiamondTo(
            user, custodian, "GIA", "01", "valid", cccc, carat, attributesHash, hashingAlgorithm
        );
    }

    function testLinkOldToNewToken() public {
        dpass.mintDiamondTo(
            user, custodian, "GIA", "02", "valid", cccc, carat, attributesHash, hashingAlgorithm
        );
        dpass.linkOldToNewToken(1, 2);
    }

    function testFailNotExistLinkOldToNewToken() public {
        dpass.mintDiamondTo(
            user, custodian, "GIA", "02", "valid", cccc, carat, attributesHash, hashingAlgorithm
        );
        dpass.linkOldToNewToken(1, 100);
    }

    function testSetState() public {
        DpassTester(user).doSetState("sale", 1);

        bytes32 issuer;
        bytes32 report;
        bytes32 state;
        bytes32 _cccc;
        uint24 _carat;
        bytes32 attrsHash;

        (issuer, report,  state, _cccc, _carat, attrsHash) = dpass.getDiamond(1);
        assertEq(state, "sale");
    }

    function testFailNonOwnerChangeState() public {
        DpassTester(custodian).doSetState("sale", 1);
    }

    function testFailContractOwnerChangeState() public {
        dpass.setState("sale", 1);
    }

    function testNewTransition() public {
        DpassTester(user).doTransferFrom(user, address(this), 1); // this contract must become owner to be able to change state
        bytes8 newState = "newState";
        dpass.enableTransition("valid", newState);
        dpass.setState(newState, 1);

        bytes3 issuer;
        bytes16 report;
        bytes8 state;
        bytes20 _cccc;
        uint24 _carat;
        bytes32 attrsHash;

        (issuer, report, state, _cccc, _carat, attrsHash) = dpass.getDiamond(1);
        assertEq(state, newState);
    }

    function testFailDisabledTransition() public {
        dpass.disableTransition("valid", "sale");
        dpass.setState("sale", 1);
    }

    function testSetCustodian() public {
        dpass.setCustodian(1, address(0xee));
        assertEq(dpass.getCustodian(1), address(0xee));
    }

    function testFailNonAuthSetCustodian() public {
        DpassTester(user).doSetCustodian(1, address(0xee));
    }

    function testTransfer() public {
        dpass.setCustodian(1, address(0xee));
        DpassTester(user).doTransferFrom(user, address(0xee), 1);
    }

    function testSafeTransfer() public {
        dpass.setCustodian(1, address(0xee));
        DpassTester(user).doSafeTransferFrom(user, address(0xee), 1);
    }
}
