pragma solidity ^0.5.4;

// /**
//  * How to use dapp and openzeppelin-solidity https://github.com/dapphub/dapp/issues/70
//  * ERC-721 standart: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
//  *
//  */

import "ds-auth/auth.sol";
import "openzeppelin-solidity/token/ERC721/ERC721Full.sol";

/**
* @dev Contract to get Diamond actual attributes list
*/
contract AttributeNameList {
    function get() external view returns (bytes32[] memory);
}


contract DpassEvents {
    event LogPriceChanged(
        uint tokenId,
        uint price
    );

    event LogSaleStatusChanged(
        uint tokenId,
        bytes32 state
    );

    event LogDiamondMinted(
        address owner,
        uint indexed tokenId,
        bytes32 issuer,
        bytes32 report,
        uint price,
        bytes32 state
    );

    event LogRedeem(
        uint tokenId
    );
}


contract Dpass is DSAuth, ERC721Full, DpassEvents {
    string private _name = "CDC Passport";
    string private _symbol = "CDC PASS";

    struct Diamond {
        bytes32 issuer;
        bytes32 report;
        uint price;
        bytes32 state;

        bytes32[] attributeNames;
        bytes32[] attributeValues;
    }

    Diamond[] diamonds;
    AttributeNameList public attributeNameListAddress;

    constructor () public ERC721Full(_name, _symbol) {
        // pass
    }

    /**
    * @dev Custom accessor to create a unique token
    * @param _to address of diamond owner
    * @param _issuer string the issuer agency name
    * @param _report string the issuer agency unique Nr.
    * @param _price uint diamond price
    * @param _state diamond state, "sale" is the init status
    * @return Return Diamond tokenId of the diamonds list
    */
    function mintDiamondTo(
        address _to,
        bytes32 _issuer,
        bytes32 _report,
        uint _price,
        bytes32 _state,
        bytes32[] memory _attributes
    )
        public auth
    {
        bytes32[] memory _attributeNames = getAttributeNames();
        bytes32[] memory _attributeValues = new bytes32[](_attributeNames.length);

        for (uint i = 0; i < _attributeNames.length; i++) {
            // _attributeValues.push(_attributes[i]);
            _attributeValues[i] = _attributes[i];
        }

        Diamond memory _diamond = Diamond({
            issuer: _issuer,
            report: _report,
            price: _price,
            state: _state,
            attributeNames: _attributeNames,
            attributeValues: _attributeValues
        });
        uint256 _tokenId = diamonds.push(_diamond) - 1;

        super._mint(_to, _tokenId);
        emit LogDiamondMinted(_to, _tokenId, _issuer, _report, _price, _state);
    }

    /**
     * @dev Gets the Diamond at a given _tokenId of all the diamonds in this contract
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @return Returns all the relevant information about a specific diamond
     */
    function getDiamond(uint256 _tokenId)
        public
        view
        returns (
            bytes32 issuer,
            bytes32 report,
            uint price,
            bytes32 state,
            bytes32[] memory attrib
        )
    {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        return (
            _diamond.issuer,
            _diamond.report,
            _diamond.price,
            _diamond.state,
            _diamond.attributeValues
        );
    }

    /**
     * @dev Return default diamond attribute names or from external contract
     * @return array of names
     */
    function getAttributeNames() public view returns (bytes32[] memory) {
        if (attributeNameListAddress == AttributeNameList(0)) {
            bytes32[] memory names = new bytes32[](2);
            names[0] = "carat_weight";
            names[1] = "measurment";
            return names;
        } else {
            return attributeNameListAddress.get();
        }
    }

    /**
     * @dev Gets the Diamond issuer and it unique nr at a given _tokenId of all the diamonds in this contract
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @return Issuer and unique Nr. a specific diamond
     */
    function getDiamondIssuerAndReport(uint256 _tokenId) public view returns (bytes32, bytes32) {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        return (_diamond.issuer, _diamond.report);
    }

    /**
     * @dev Gets the Diamond price at a given _tokenId
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @return specific diamond price
     */
    function getPrice(uint256 _tokenId) public view returns (uint) {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        return _diamond.price;
    }

    /**
     * @dev Set Diamond price
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @param _price uint256 new price of diamond
     */
    function setPrice(uint256 _tokenId, uint _price) public {
        require(ownerOf(_tokenId) == msg.sender, "Access denied");
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];

        uint old_price = _diamond.price;
        _diamond.price = _price;

        if (old_price != _price) {
            emit LogPriceChanged(_tokenId, _price);
        }
    }

    /**
     * @dev Set Diamond sale status
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     */
    function setSaleStatus(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Access denied");
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        bytes32 old_state = _diamond.state;
        _diamond.state = "sale";

        if (old_state != _diamond.state) {
            emit LogSaleStatusChanged(_tokenId, _diamond.state);
        }
    }

    /**
     * @dev Make diamond status as redeemed, change owner to contract owner
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     */
    function redeem(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Access denied");

        Diamond storage _diamond = diamonds[_tokenId];
        _diamond.state = "redeemed";

        _transferFrom(msg.sender, owner, _tokenId);
        emit LogRedeem(_tokenId);
    }
}
