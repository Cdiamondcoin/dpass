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
        bytes gia,
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
        bytes gia;
        uint price;
        bool sale;
        bool redeemed;
        bytes carat_weight;
        bytes measurements;
        bytes color_grade;
        bytes clarity_grade;
        bytes cut_grade;
        bytes depth;
        bytes table;
        bytes crown_angle;
        bytes crown_height;
        bytes pavilion_angle;
        bytes pavilion_depth;
        bytes star_length;
        bytes lower_half;
        bytes girdle;
        bytes culet;
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
        bytes memory _gia,
        uint _price,
        bool _sale,
        bytes[] attributes
    )
        public auth
    {
        Diamond memory _diamond = Diamond({
            gia: _gia,
            price: _price,
            sale: _sale,
            redeemed: false,
            carat_weight: "",
            measurements: "",
            color_grade: "",
            clarity_grade: "",
            cut_grade: "",
            depth: "",
            table: "",
            crown_angle: "",
            crown_height: "",
            pavilion_angle: "",
            pavilion_depth: "",
            star_length: "",
            lower_half: "",
            girdle: "",
            culet: ""
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
        returns (bytes memory gia, uint price, bool sale, bool redeemed)
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
    function getDiamondGia(uint256 _tokenId) public view returns (bytes memory) {
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
