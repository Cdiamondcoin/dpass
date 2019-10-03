pragma solidity ^0.5.10;

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
    function getPrice(address erc721, uint id721) external view returns(uint);
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
    event LogStateChanged(uint indexed tokenId, bytes32 state);
    event LogSale(uint indexed tokenId);
    event LogRedeem(uint indexed tokenId);
    event LogSetAttributeNameListAddress(address priceFeed);
    event LogSetTrustedAssetManagement(address asm);
    event LogHashingAlgorithmChange(bytes8 name);
    event LogDiamondAttributesHashChange(uint indexed tokenId, bytes8 hashAlgorithm);
}


contract Dpass is DSAuth, ERC721Full, DpassEvents {
    string private _name = "Diamond Passport";
    string private _symbol = "Dpass";

    TrustedAssetManagement public asm;                          // Asset Management contract

    struct Diamond {
        bytes32 issuer;
        bytes32 report;
        uint ownerPrice;
        uint marketplacePrice;
        bytes32 state;
        bytes32[] attributeNames;                               // List of Rapaport calc required attributes names
        bytes32[] attributeValues;                              // List of Rapaport calc required attributes values
        bytes8 currentHashingAlgorithm;                         // Current hashing algorithm to check in the proof mapping
    }
    Diamond[] diamonds;                                         // List of Dpasses

    AttributeNameList public attributeNameListAddress;          // List of Diamond main parameters. Rapaport price depends on it

    mapping (uint => mapping(bytes32 => bytes32)) public proof;  // Prof of attributes integrity [tokenId][hasningAlgorithm] => hash
    mapping (bytes32 => mapping (bytes32 => uint)) diamondIndex; // List of dpasses by issuer and report number [issuer][number]
    mapping (uint256 => uint256) public recreated;               // List of recreated tokens. old tokenId => new tokenId


    constructor () public ERC721Full(_name, _symbol) {
        // Create dummy diamond to start real diamond minting from 1
        Diamond memory _diamond = Diamond({
            issuer: "Self",
            report: "0",
            ownerPrice: uint(-1),
            marketplacePrice: uint(-1),
            state: "invalid",
            attributeNames: new bytes32[](1),
            attributeValues: new bytes32[](1),
            currentHashingAlgorithm: ""
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
    * @param _currentHashingAlgorithm name of hasning algorithm (ex. 20190101)
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
        bytes32 _attributesHash,
        bytes8 _currentHashingAlgorithm
    )
        public auth
    {
        _addToDiamondIndex(_issuer, _report);

        Diamond memory _diamond = Diamond({
            issuer: _issuer,
            report: _report,
            ownerPrice: _ownerPrice,
            marketplacePrice: _marketplacePrice,
            state: _state,
            attributeNames: getAttributeNames(),
            attributeValues: _attributes,
            currentHashingAlgorithm: _currentHashingAlgorithm
        });
        uint _tokenId = diamonds.push(_diamond) - 1;
        proof[_tokenId][_currentHashingAlgorithm] = _attributesHash;

        _mint(_to, _tokenId);
        emit LogDiamondMinted(_to, _tokenId, _issuer, _report, _ownerPrice, _marketplacePrice, _state);
    }

    /**
    * @dev Update _tokenId attributes
    * @param _attributesHash new attibutes hash value
    * @param _currentHashingAlgorithm name of hasning algorithm (ex. 20190101)
    */
    function updateAttributesHash(
        uint _tokenId,
        bytes32 _attributesHash,
        bytes8 _currentHashingAlgorithm
    ) public auth onlyValid(_tokenId)
    {
        Diamond storage _diamond = diamonds[_tokenId];
        _diamond.currentHashingAlgorithm = _currentHashingAlgorithm;

        proof[_tokenId][_currentHashingAlgorithm] = _attributesHash;

        emit LogDiamondAttributesHashChange(_tokenId, _currentHashingAlgorithm);
    }

    /**
    * @dev Link old and the same new dpass
    */
    function linkOldToNewToken(uint _tokenId, uint _newTokenId) public auth {
        require(_exists(_tokenId), "Old diamond does not exist");
        require(_exists(_newTokenId), "New diamond does not exist");
        recreated[_tokenId] = _newTokenId;
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
            bytes32[] memory attributeNames,
            bytes32[] memory attributeValues,
            bytes32 attributesHash
        )
    {
        Diamond storage _diamond = diamonds[_tokenId];
        attributesHash = proof[_tokenId][_diamond.currentHashingAlgorithm];

        return (
            _diamond.issuer,
            _diamond.report,
            getOwnerPrice(_tokenId),
            getMarketplacePrice(_tokenId),
            _diamond.state,
            _diamond.attributeNames,
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
     * @dev Return default diamond attribute names as string
     * @return commaseperated string
     */
    function getAttributeNamesAsString() public view returns(string memory) {
        bytes32[] memory data = getAttributeNames();
        return _bytes32ArrayToSemicolonString(data);
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
    function setMarketplacePrice(uint _tokenId, uint _newPrice) public auth ifExist(_tokenId) {
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
     * @dev Set Diamond invalid status
     * @param _tokenId uint representing the index to be accessed of the diamonds list
     */
    function setInvalidStatus(uint _tokenId) public ifExist(_tokenId) onlyOwnerOf(_tokenId) {
        _changeStateTo("invalid", _tokenId);
        _removeDiamondFromIndex(_tokenId);
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
            require(address(asm) != address(0), "TrustedAssetManagement contract address not defined");
            return asm.getPrice(address(this), _tokenId);
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

    /**
     * @dev Change diamond status.
     * @param _newState new token state
     * @param _tokenId represent the index of diamond
     */
    function changeStateTo(bytes32 _newState, uint _tokenId) public auth ifExist(_tokenId) {
        _changeStateTo(_newState, _tokenId);
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
     * @dev Add Issuer and report with validation to uniqueness. Revert on invalid existance
     * @param _issuer issuer like GIA
     * @param _report issuer unique nr.
     */
    function _addToDiamondIndex(bytes32 _issuer, bytes32 _report) internal {
        require(diamondIndex[_issuer][_report] != 1, "Issuer and report not unique.");
        diamondIndex[_issuer][_report] = 1;
    }

    function _removeDiamondFromIndex(uint _tokenId) internal {
        Diamond storage _diamond = diamonds[_tokenId];
        diamondIndex[_diamond.issuer][_diamond.report] = 0;
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

    /**
     * @dev Convert bytes32 array to ; seperated string
     * @return semicolon seperated string
     */
    function _bytes32ArrayToSemicolonString(bytes32[] memory data) internal pure returns(string memory) {
        bytes memory bytesString = new bytes(data.length * 32 + data.length);
        uint attribLength;

        for (uint i = 0; i < data.length; i++) {
            for (uint j = 0; j < 32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[attribLength] = char;
                    attribLength += 1;
                }
            }
            // add semicolumn
            bytesString[attribLength] = byte(";");
            attribLength += 1;
        }

        bytes memory bytesStringTrimmed = new bytes(attribLength);
        for (uint i = 0; i < attribLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }

}
