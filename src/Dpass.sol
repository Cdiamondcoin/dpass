pragma solidity ^0.5.4;

// /**
//  * How to use dapp and openzeppelin-solidity https://github.com/dapphub/dapp/issues/70
//  * ERC-721 standart: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
//  *
//  */

import "ds-auth/auth.sol";
import "openzeppelin-solidity/token/ERC721/ERC721Full.sol";


contract Dpass is DSAuth, ERC721Full {
    string private _name = "CDC Passport";
    string private _symbol = "CDC PASS";

    struct Diamond {
        string gia;
        uint carat_weight;
        uint price;
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
    * @return Return Diamond tokenId of the diamonds list
    */
    function mintDiamondTo(address _to, string memory _gia, uint _carat_weight, uint _price) public auth {
        uint256 _tokenId = _createDiamond(_gia, _carat_weight, _price);

        super._mint(_to, _tokenId);
        // super._setTokenURI(_tokenId, _uri);
    }

    function _createDiamond(string memory _gia, uint _carat_weight, uint _price) internal returns (uint) {
        Diamond memory _diamond = Diamond({
            gia: _gia,
            carat_weight: _carat_weight,
            price: _price
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
    function getDiamond(uint256 _tokenId) public view returns (string memory gia, uint carat_weight, uint price) {
        require(_tokenId < totalSupply(), "Diamond does not exist");

        Diamond storage _diamond = diamonds[_tokenId];
        gia = _diamond.gia;
        carat_weight = _diamond.carat_weight;
        price = _diamond.price;
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
}
