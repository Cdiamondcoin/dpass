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
        string gia,
        uint carat_weight,
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
        string gia;
        uint carat_weight;
        uint price;
        bool sale;
        bool redeemed;
    }

    Diamond[] diamonds;

    constructor () public ERC721Full(_name, _symbol) {
        // pass
    }

    /**
    * @dev Custom accessor to create a unique token
    * @param _to address of diamond owner
    * @param _gia string diamond GIA agency unique Nr.
    * @param _carat_weight uint diamond carat weight (4 decimals) format 10**4 (ex 0.71 carat is 71000)
    * @param _price uint diamond price
    * @param _sale bool is diamond can be purched
    * @return Return Diamond tokenId of the diamonds list
    */
    function mintDiamondTo(
        address _to,
        string memory _gia,
        uint _carat_weight,
        uint _price,
        bool _sale
    )
        public auth
    {
        uint256 _tokenId = _createDiamond(_gia, _carat_weight, _price, _sale);

        super._mint(_to, _tokenId);
        emit LogDiamondMinted(_to, _tokenId, _gia, _carat_weight, _price, _sale);
    }

    function _createDiamond(
        string memory _gia,
        uint _carat_weight,
        uint _price,
        bool _sale
    )
        internal
        returns (uint)
    {
        Diamond memory _diamond = Diamond({
            gia: _gia,
            carat_weight: _carat_weight,
            price: _price,
            sale: _sale,
            redeemed: false
        });

        uint256 newDiamondId = diamonds.push(_diamond) - 1;

        return newDiamondId;
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
        returns (string memory gia, uint carat_weight, uint price, bool sale, bool redeemed)
    {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        gia = _diamond.gia;
        carat_weight = _diamond.carat_weight;
        price = _diamond.price;
        sale = _diamond.sale;
        redeemed = _diamond.redeemed;
    }

    /**
     * @dev Gets the Diamond gia number at a given _tokenId of all the diamonds in this contract
     * Reverts if the _tokenId is greater or equal to the total number of diamonds
     * @param _tokenId uint256 representing the index to be accessed of the diamonds list
     * @return Gia information about a specific diamond
     */
    function getDiamondGia(uint256 _tokenId) public view returns (string memory) {
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
