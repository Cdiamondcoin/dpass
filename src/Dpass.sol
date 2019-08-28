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
    event LogDiamondMinted(
        address owner,
        uint indexed tokenId,
        bytes32 issuer,
        bytes32 report,
        uint price,
        bytes32 state
    );

    event LogPriceChanged(uint indexed tokenId, uint price);
    event LogSale(uint indexed tokenId);
    event LogStateChanged(uint indexed tokenId, bytes32 state);
    event LogRedeem(uint indexed tokenId);
    event LogSetAttributeNameListAddress(address priceFeed);
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
    mapping (bytes32 => mapping (bytes32=> uint256)) diamondDb;

    Diamond[] diamonds;
    AttributeNameList public attributeNameListAddress;

    constructor () public ERC721Full(_name, _symbol) {
        // pass
    }

    modifier onlyOwnerOf(uint _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Access denied");
        _;
    }

    modifier ifExist(uint _tokenId) {
        require(_tokenId < totalSupply(), "Diamond does not exist");
        _;
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
        _validateUniquness(_issuer, _report);

        bytes32[] memory _attributeNames = getAttributeNames();
        bytes32[] memory _attributeValues = new bytes32[](_attributeNames.length);
        for (uint i = 0; i < _attributeNames.length; i++) {
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
        ifExist(_tokenId)
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
    function getAttributeNames() public view returns(bytes32[] memory) {
        if (attributeNameListAddress == AttributeNameList(0)) {
            return _getDefaultAttributeNameList();
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
    function getDiamondIssuerAndReport(uint256 _tokenId) public view ifExist(_tokenId) returns(bytes32, bytes32) {
        Diamond storage _diamond = diamonds[_tokenId];
        return (_diamond.issuer, _diamond.report);
    }

    /**
     * @dev Gets the Diamond price at a given _tokenId
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @return specific diamond price
     */
    function getPrice(uint256 _tokenId) public view ifExist(_tokenId) returns(uint) {
        Diamond storage _diamond = diamonds[_tokenId];
        return _diamond.price;
    }

    /**
     * @dev Set new attributeNameListAddress contract address
     * Reverts if invalid address
     * @param _newAddress new address of AttributeNameList contract
     */
    function setAttributeNameListAddress(address _newAddress) public auth {
        require(_newAddress != address(0), "Wrong address");
        attributeNameListAddress = AttributeNameList(_newAddress);
        emit LogSetAttributeNameListAddress(_newAddress);
    }

    /**
     * @dev Set Diamond price
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @param _price uint256 new price of diamond
     */
    function setPrice(uint256 _tokenId, uint _price) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
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
    function setSaleStatus(uint256 _tokenId) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        _changeStateTo("sale", _tokenId);
        emit LogSale(_tokenId);
    }

    /**
     * @dev Make diamond status as redeemed, change owner to contract owner
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     */
    function redeem(uint256 _tokenId) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        _changeStateTo("redeemed", _tokenId);
        _transferFrom(msg.sender, owner, _tokenId);
        emit LogRedeem(_tokenId);
    }



    // Private functions

    /**
     * @dev Return default diamond attribute names
     * @return array of attrubutes names
     */
    function _getDefaultAttributeNameList() internal pure returns (bytes32[] memory) {
        bytes32[] memory names = new bytes32[](15);
        names[0] = "carat_weight";
        names[1] = "measurment";
        names[2] = "color_grade";
        names[3] = "clarity_grade";
        names[4] = "cut_grade";
        names[5] = "depth";
        names[6] = "table";
        names[7] = "crown_angle";
        names[8] = "crown_height";
        names[9] = "pavilion_angle";
        names[10] = "pavilion_depth";
        names[11] = "star_length";
        names[12] = "lower_half";
        names[13] = "girdle";
        names[14] = "culet";
        return names;
    }

    /**
     * @dev Validate transiton from currentState to newState. Revert on invalid transition
     * @param _currentState current diamond state
     * @param _newState new diamond state
     */
    function _validateStateTransitionTo(bytes32 _currentState, bytes32 _newState) internal pure {
        require(_currentState != _newState, "Already in that state");
    }

    /**
     * @dev Validate Issuer and report together uniqueness. Revert on invalid existance
     * @param _issuer issuer like GIA
     * @param _report issuer unique nr.
     */
    function _validateUniquness(bytes32 _issuer, bytes32 _report) internal {
        require(diamondDb[_issuer][_report] != 1, "Issuer and report not unique.");
        // TODO: should we move to another function?
        diamondDb[_issuer][_report] = 1;
    }

    /**
     * @dev Change diamond status with logging. Revert on invalid transition
     * @param _newState new token state
     * @param _tokenId represent the index of diamond
     */
    function _changeStateTo(bytes32 _newState, uint256 _tokenId) internal {
        Diamond storage _diamond = diamonds[_tokenId];
        _validateStateTransitionTo(_diamond.state, _newState);
        _diamond.state = _newState;
        emit LogStateChanged(_tokenId, _newState);
    }
}
