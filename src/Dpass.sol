pragma solidity ^0.5.6;

// /**
//  * How to use dapp and openzeppelin-solidity https://github.com/dapphub/dapp/issues/70
//  * ERC-721 standart: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
//  *
//  */

import "ds-auth/auth.sol";
import "openzeppelin-solidity/token/ERC721/ERC721Full.sol";


/**
* @dev AssetManagement contract interface
*/
contract TrustedAssetManagement {
    function getPrice(ERC721Full erc721, uint id721) external view returns(uint);
    // TODO: Will Robert implement this function?
    function isAssetManager(address sender) external view returns(uint);
}


/**
* @dev Contract to get Diamond actual attributes list
*/
contract AttributeNameList {
    // TODO: still needed?
    function get() external view returns (bytes32[] memory);
}


contract DpassEvents {
    event LogDiamondMinted(
        address owner,
        uint indexed tokenId,
        bytes32 issuer,
        bytes32 report,
        uint ownerPrice,
        uint marketplacePrice,
        bytes32 state
    );

    event LogOwnerPriceChanged(uint indexed tokenId, uint price);
    event LogMarketplacePriceChanged(uint indexed tokenId, uint price);
    event LogSale(uint indexed tokenId);
    event LogStateChanged(uint indexed tokenId, bytes32 state);
    event LogRedeem(uint indexed tokenId);
    event LogSetAttributeNameListAddress(address priceFeed);
    event LogSetTrustedAssetManagement(address asm);
    event LogHashingAlgorithmChange(bytes8 name);
}


contract Dpass is DSAuth, ERC721Full, DpassEvents {
    string private _name = "CDC Passport";
    string private _symbol = "CDC PASS";

    TrustedAssetManagement public asm;      // Asset Management contract

    struct Diamond {
        bytes32 issuer;
        bytes32 report;
        uint ownerPrice;
        uint marketplacePrice;
        bytes32 state;
        bytes32[] attributeNames;
        bytes32[] attributeValues;
    }
    Diamond[] diamonds;                                         // List of Dpasses

    AttributeNameList public attributeNameListAddress;          // List of Diamond main parameters. Rapaport price depends on it
    // TODO: Save to Diamond structure?
    mapping (uint => mapping(bytes32 => bytes32)) public proof; // Prof of attributes integrity [tokenId][hashingAlgorithm] => hash
    mapping (bytes32 => mapping (bytes32 => uint)) diamondDb;   // List of dpasses by issuer and report number [issuer][number]
    bytes8 public hashingAlgorithm = "20191001";                // Actual hasning algorithm name in format yyyymmdd
    mapping(uint256 => uint256) public recreatedDiamonds;       // List of recreated tokens. old tokenId => new tokenId


    constructor () public ERC721Full(_name, _symbol) {
        // Create dummy diamond to start real diamond minting from 1
        Diamond memory _diamond = Diamond({
            issuer: "Self",
            report: "0",
            ownerPrice: uint(-1),
            marketplacePrice: uint(-1),
            state: "invalid",
            attributeNames: new bytes32[](1),
            attributeValues: new bytes32[](1)
        });

        diamonds.push(_diamond);
        _mint(address(this), 0);
    }

    modifier onlyOwnerOf(uint _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Access denied");
        _;
    }

    modifier ifExist(uint _tokenId) {
        require(_exists(_tokenId), "Diamond does not exist");
        _;
    }

    // TODO: Validate sender for permissions
    modifier onlyAssetManager() {
        require(msg.sender == msg.sender, "Only Asset manager");
        _;
    }

    modifier onlyValid(uint _tokenId) {
        // TODO: DRY, _exists already check
        require(_exists(_tokenId), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        require(_diamond.state != "invalid", "Diamond is invalid");
        _;
    }

    /**
    * @dev Custom accessor to create a unique token
    * @param _to address of diamond owner
    * @param _issuer string the issuer agency name
    * @param _report string the issuer agency unique Nr.
    * @param _ownerPrice uint diamond price
    * @param _marketplacePrice uint diamond price
    * @param _state diamond state, "sale" is the init status
    * @param _attributes diamond Rapaport attributes
    * @return Return Diamond tokenId of the diamonds list
    */
    function mintDiamondTo(
        address _to,
        bytes32 _issuer,
        bytes32 _report,
        uint _ownerPrice,
        uint _marketplacePrice,
        bytes32 _state,
        bytes32[] memory _attributes,
        bytes32 _attributesHash
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
            ownerPrice: _ownerPrice,
            marketplacePrice: _marketplacePrice,
            state: _state,
            attributeNames: _attributeNames,
            attributeValues: _attributeValues
        });
        uint _tokenId = diamonds.push(_diamond) - 1;
        proof[_tokenId][hashingAlgorithm] = _attributesHash;

        super._mint(_to, _tokenId);
        emit LogDiamondMinted(_to, _tokenId, _issuer, _report, _ownerPrice, _marketplacePrice, _state);
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg.sender to be the owner, approved, or operator and not invalid token
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public onlyValid(_tokenId) {
        super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev Gets the Diamond at a given _tokenId of all the diamonds in this contract
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     * @return Returns all the relevant information about a specific diamond
     */
    function getDiamond(uint _tokenId)
        public
        view
        ifExist(_tokenId)
        returns (
            bytes32 issuer,
            bytes32 report,
            uint ownerPrice,
            uint marketplacePrice,
            bytes32 state,
            bytes32[] memory attrib,
            bytes32 attributesHash
        )
    {
        Diamond storage _diamond = diamonds[_tokenId];
        attributesHash = proof[_tokenId][hashingAlgorithm];

        return (
            _diamond.issuer,
            _diamond.report,
            getOwnerPrice(_tokenId),
            getMarketplacePrice(_tokenId),
            _diamond.state,
            _diamond.attributeValues,
            attributesHash
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
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     * @return Issuer and unique Nr. a specific diamond
     */
    function getDiamondIssuerAndReport(uint _tokenId) public view ifExist(_tokenId) returns(bytes32, bytes32) {
        Diamond storage _diamond = diamonds[_tokenId];
        return (_diamond.issuer, _diamond.report);
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
     * @dev Set Diamond owner price
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     * @param _newPrice uint new price of diamond
     */
    function setOwnerPrice(uint _tokenId, uint _newPrice) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        Diamond storage _diamond = diamonds[_tokenId];

        uint oldPrice = _diamond.ownerPrice;
        _diamond.ownerPrice = _newPrice;

        if (oldPrice != _newPrice) {
            emit LogOwnerPriceChanged(_tokenId, _newPrice);
        }
    }

    /**
     * @dev Set Diamond marketplace price
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     * @param _newPrice uint new price of diamond
     */
    function setMarketplacePrice(uint _tokenId, uint _newPrice) public onlyAssetManager ifExist(_tokenId) {
        Diamond storage _diamond = diamonds[_tokenId];

        uint oldPrice = _diamond.marketplacePrice;
        _diamond.marketplacePrice = _newPrice;

        if (oldPrice != _newPrice) {
            emit LogMarketplacePriceChanged(_tokenId, _newPrice);
        }
    }


    /**
     * @dev Set Diamond sale status
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     */
    function setSaleStatus(uint _tokenId) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        _changeStateTo("sale", _tokenId);
        emit LogSale(_tokenId);
    }

    /**
     * @dev Set new hashing Algorithm for dpass attributes hash
     */
    function setHashingAlgorithm(bytes8 _newHashingAlgorithm) public auth {
        hashingAlgorithm = _newHashingAlgorithm;
        emit LogHashingAlgorithmChange(_newHashingAlgorithm);
    }

    /**
     * @dev Make diamond status as redeemed, change owner to contract owner
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     */
    function redeem(uint _tokenId) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        _changeStateTo("redeemed", _tokenId);
        // TODO: move to safeTransfer?
        transferFrom(msg.sender, owner, _tokenId);
        emit LogRedeem(_tokenId);
    }

    /**
     * @dev Return manually setted price if 0 then by Rapaport
     */
    function getMarketplacePrice(uint _tokenId) public view ifExist(_tokenId) returns(uint) {
        Diamond storage _diamond = diamonds[_tokenId];
        if (_diamond.marketplacePrice == 0) {
            return asm.getPrice(ERC721Full(this), _tokenId);
        } else {
            return _diamond.marketplacePrice;
        }
    }

    /**
     * @dev Return manually setted price if 0 then return marketplace price
     */
    function getOwnerPrice(uint _tokenId) public view ifExist(_tokenId) returns(uint) {
        Diamond storage _diamond = diamonds[_tokenId];
        if (_diamond.ownerPrice == 0) {
            return getMarketplacePrice(_tokenId);
        } else {
            return _diamond.ownerPrice;
        }
    }

    /**
     * @dev Gets the Diamond price at a given _tokenId
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     * @return specific diamond price
     */
    function getPrice(uint _tokenId) public view ifExist(_tokenId) returns(uint) {
        return getOwnerPrice(_tokenId);
    }

    // Private functions

    /**
     * @dev Return default diamond attribute names
     * @return array of attrubutes names
     */
    function _getDefaultAttributeNameList() internal pure returns (bytes32[] memory) {
        bytes32[] memory names = new bytes32[](5);
        names[0] = "shape";
        names[1] = "weight";
        names[2] = "color";
        names[3] = "clarity";
        names[4] = "cut";
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
    function _changeStateTo(bytes32 _newState, uint _tokenId) internal {
        Diamond storage _diamond = diamonds[_tokenId];
        _validateStateTransitionTo(_diamond.state, _newState);
        _diamond.state = _newState;
        emit LogStateChanged(_tokenId, _newState);
    }
}
