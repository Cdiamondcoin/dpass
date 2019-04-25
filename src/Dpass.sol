pragma solidity ^0.5.4;

// /**
//  * How to use dapp and openzeppelin-solidity https://github.com/dapphub/dapp/issues/70
//  * ERC-721 standart: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
//  *
//  */

import "ds-auth/auth.sol";
import "openzeppelin-solidity/token/ERC721/ERC721Full.sol";


contract DpassEvents {
    event LogPriceChanged(
        uint token_id,
        uint price
    );

    event LogSaleStatusChanged(
        uint token_id,
        bool sale
    );

    event LogDiamondMinted(
        address owner,
        uint token_id,
        bytes32 gia,
        uint price,
        bool sale
    );

    event LogRedeem(
        uint token_id
    );
}


contract Dpass is DSAuth, ERC721Full, DpassEvents {
    string private _name = "CDC Passport";
    string private _symbol = "CDC PASS";

    struct Diamond {
        bytes32 gia;
        uint price;
        bool sale;
        bool redeemed;
        bytes32 carat_weight;
        bytes32 measurements;
        bytes32 color_grade;
        bytes32 clarity_grade;
        bytes32 cut_grade;
        bytes32 depth;
        bytes32 table;
        bytes32 crown_angle;
        bytes32 crown_height;
        bytes32 pavilion_angle;
        bytes32 pavilion_depth;
        bytes32 star_length;
        bytes32 lower_half;
        bytes32 girdle;
        bytes32 culet;
    }

    Diamond[] diamonds;

    constructor () public ERC721Full(_name, _symbol) {
        // pass
    }

    /**
    * @dev Custom accessor to create a unique token
    * @param _to address of diamond owner
    * @param _gia string diamond GIA agency unique Nr.
    * @param _price uint diamond price
    * @param _sale bool is diamond can be purched
    * @return Return Diamond tokenId of the diamonds list
    */
    function mintDiamondTo(
        address _to,
        bytes32 _gia,
        uint _price,
        bool _sale,
        bytes32[] memory attributes
    )
        public auth
    {
        Diamond memory _diamond = Diamond({
            gia: _gia,
            price: _price,
            sale: _sale,
            redeemed: false,
            carat_weight: attributes[0],
            measurements: attributes[1],
            color_grade: attributes[2],
            clarity_grade: attributes[3],
            cut_grade: attributes[4],
            depth: attributes[5],
            table: attributes[6],
            crown_angle: attributes[7],
            crown_height: attributes[8],
            pavilion_angle: attributes[9],
            pavilion_depth: attributes[10],
            star_length: attributes[11],
            lower_half: attributes[12],
            girdle: attributes[13],
            culet: attributes[14]
        });
        uint256 _tokenId = diamonds.push(_diamond) - 1;

        super._mint(_to, _tokenId);
        emit LogDiamondMinted(_to, _tokenId, _gia, _price, _sale);
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
        returns (bytes32 gia, uint price, bool sale, bool redeemed)
    {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        return (
            _diamond.gia,
            _diamond.price,
            _diamond.sale,
            _diamond.redeemed
        );
    }

    /**
     * @dev Gets the Diamond gia number at a given _tokenId of all the diamonds in this contract
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @return Gia information about a specific diamond
     */
    function getDiamondGia(uint256 _tokenId) public view returns (bytes32) {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        return _diamond.gia;
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
     * @param _sale bool new diamond sale status
     */
    function setSaleStatus(uint256 _tokenId, bool _sale) public {
        require(ownerOf(_tokenId) == msg.sender, "Access denied");
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        bool old_sale = _diamond.sale;
        _diamond.sale = _sale;

        if (old_sale != _sale) {
            emit LogSaleStatusChanged(_tokenId, _sale);
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
        _diamond.redeemed = true;

        _transferFrom(msg.sender, owner, _tokenId);
        emit LogRedeem(_tokenId);
    }
}
