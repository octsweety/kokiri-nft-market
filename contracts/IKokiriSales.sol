//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

struct Token {
    address owner;
    uint price;
}

// Market contract for users to buy and sell their NFTs
interface IKokiriSales {
    // NFT owner add their token to sell into the market with _tokenId and _price
    // Should approve Sales contract for the _tokenId before calling this function
    function wantSale(uint256 _tokenId, uint256 _price) external;
    // NFT owner or granted admin can remove already existing any token on the market
    function removeSale(uint _tokenId) external;
    // NFT owner can update its price
    function setTokenPrice(uint256 _tokenId, uint256 _tokenPrice) external;
    // Someone can purchase listed any token from the market.
    // At that time, user need to pay MAGI or GYA token according to the price
    function purchaseToken(uint256 _tokenId) external;
    // Someone can check the price of any NFT
    function tokenPrice(uint256 _tokenId) external returns (uint256);
    // Someone can check owner and price of any token
    function tokenInfo(uint256 _tokenId) external returns (Token memory);
    // Someone can list all of the NFTs
    function salesList(address _seller) external returns (Token[] memory);
    function salesListAll() external returns (Token[] memory);
    function count(address _seller) external view returns (uint);
    function countAll() external view returns (uint);
    function salesIdList(address _seller) external view returns (uint[] memory);
    function salesIdListAll() external view returns (uint[] memory);
}