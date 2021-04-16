//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./IKokiriNFT.sol";

/**
 * @title CryptoArteSales
 * CryptoArteSales - a sales contract for CryptoArte non-fungible tokens 
 * corresponding to paintings from the www.cryptoarte.io collection
 */
contract KokiriSales is Ownable, Pausable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    ERC721 public nftAddress;
    IERC20 public buyToken;

    struct Token {
        uint id;
        address owner;
        uint price;
    }

    mapping(uint256 => uint256) public tokenPrices;
    mapping(uint256 => Token) public tokenSales;
    mapping(address => EnumerableSet.UintSet) internal sellerTokens;
    EnumerableSet.UintSet internal tokenIds;
    
    address public feeAddress = address(0xC627D743B1BfF30f853AE218396e6d47a4f34ceA);
    address public admin = address(0xC627D743B1BfF30f853AE218396e6d47a4f34ceA);

    uint public fee = 0;
    uint public FEE_MAX = 10000;

    event Purchased(address seller, address buyer, uint _tokenId, uint price);

    modifier onlyByOwner {
        require(msg.sender == owner() || msg.sender == admin, "!authorized");
        _;
    }

    /**
    * @dev Contract Constructor
    * @param _nftAddress address for Crypto Arte non-fungible token contract 
    */
    constructor(address _nftAddress, address _buyToken) public {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        nftAddress = ERC721(_nftAddress);
        buyToken = IERC20(_buyToken);
    }

    function setBuyToken(address _buyToken) external onlyByOwner {
        buyToken = IERC20(_buyToken);
    }

    function setFeeAddress(address _addr) external onlyByOwner {
        feeAddress = _addr;
    }

    function setAdmin(address _admin) external onlyByOwner {
        admin = _admin;
    }

    function setFee(uint _fee) external onlyByOwner {
        require(_fee < FEE_MAX, "invalid_fee");
        fee = _fee;
    }

    function setTokenPrice(uint256 _tokenId, uint256 _tokenPrice) external {
        require(IKokiriNFT(address(nftAddress)).exists(_tokenId), "!exists");
        require(msg.sender == nftAddress.ownerOf(_tokenId) || msg.sender == owner() || msg.sender == admin, "!authorized");
        tokenPrices[_tokenId] = _tokenPrice;
        if (tokenIds.contains(_tokenId)) {
            tokenSales[_tokenId].price = _tokenPrice;
        }
    }

    /**
    * @dev Purchase _tokenId
    * @param _tokenId uint256 token ID (painting number)
    */
    function purchaseToken(uint256 _tokenId) external whenNotPaused {
        require(msg.sender != address(0) && msg.sender != address(this));
        require(tokenIds.contains(_tokenId), "!exists");
        require(msg.sender != nftAddress.ownerOf(_tokenId), "invalid owner");
        address tokenSeller = nftAddress.ownerOf(_tokenId);

        uint _tokenPrice = tokenPrices[_tokenId];
        uint _amount = _tokenPrice;
        if (_tokenPrice > 0) {
            uint _before = balance();
            buyToken.safeTransferFrom(msg.sender, address(this), _tokenPrice);
            _amount = balance().sub(_before);

            require(_amount >= _tokenPrice, "!enough payment");
            uint _fee = _amount.mul(fee).div(FEE_MAX);
            if (_fee > 0) buyToken.safeTransfer(feeAddress, _fee);
            buyToken.safeTransfer(tokenSeller, _amount.sub(_fee));
        }

        nftAddress.safeTransferFrom(tokenSeller, address(this), _tokenId);
        nftAddress.approve(msg.sender, _tokenId);
        nftAddress.safeTransferFrom(address(this), msg.sender, _tokenId);

        removeSale(_tokenId);
        
        emit Purchased(tokenSeller, msg.sender, _tokenId, _amount);
    }

    function wantSale(uint256 _tokenId, uint256 _price) external {
        require(IKokiriNFT(address(nftAddress)).exists(_tokenId), "invalid token");
        require(msg.sender == nftAddress.ownerOf(_tokenId), "!owner");
        require(!tokenIds.contains(_tokenId), "already exists");

        tokenIds.add(_tokenId);
        Token storage token = tokenSales[_tokenId];
        token.owner = msg.sender;
        token.price = _price;
        token.id = _tokenId;
        tokenPrices[_tokenId] = _price;

        _addSellerToken(msg.sender, _tokenId);
    }

    function _addSellerToken(address _seller, uint256 _tokenId) internal {
        if (!sellerTokens[_seller].contains(_tokenId)) {
            sellerTokens[_seller].add(_tokenId);
        }
    }

    function _removeSellerToken(address _seller, uint256 _tokenId) internal {
        if (sellerTokens[_seller].contains(_tokenId)) {
            sellerTokens[_seller].remove(_tokenId);
        }
    }

    function removeSale(uint _tokenId) public {
        require(msg.sender == nftAddress.ownerOf(_tokenId) || msg.sender == admin || msg.sender == owner(), "!authorized");
        require(tokenIds.contains(_tokenId), "!exists");

        tokenIds.remove(_tokenId);
        Token storage token = tokenSales[_tokenId];
        token.owner = address(0);
        token.price = 0;
        token.id = 0;

        _removeSellerToken(nftAddress.ownerOf(_tokenId), _tokenId);
    }

    function salesList(address _seller) external view returns (Token[] memory) {
        Token[] memory tokenList = new Token[](sellerTokens[_seller].length());
        for (uint i = 0; i < sellerTokens[_seller].length(); i++) {
            tokenList[i] = tokenSales[sellerTokens[_seller].at(i)];
        }

        return tokenList;
    }

    function salesListAll() external view returns (Token[] memory) {
        Token[] memory tokenList = new Token[](tokenIds.length());
        for (uint i = 0; i < tokenIds.length(); i++) {
            tokenList[i] = tokenSales[tokenIds.at(i)];
        }

        return tokenList;
    }

    function count(address _seller) external view returns (uint) {
        sellerTokens[_seller].length();
    }

    function countAll() external view returns (uint) {
        return tokenIds.length();
    }

    function salesIdList(address _seller) external view returns (uint[] memory) {
        uint[] memory tokenList = new uint[](sellerTokens[_seller].length());
        for (uint i = 0; i < tokenIds.length(); i++) {
            tokenList[i] = sellerTokens[_seller].at(i);
        }

        return tokenList;
    }

    function salesIdListAll() external view returns (uint[] memory) {
        uint[] memory tokenList = new uint[](tokenIds.length());
        for (uint i = 0; i < tokenIds.length(); i++) {
            tokenList[i] = tokenIds.at(i);
        }

        return tokenList;
    }

    function balance() public view returns (uint) {
        return buyToken.balanceOf(address(this));
    }

    function pause() external onlyByOwner {
        _pause();
    }

    function unpause() external onlyByOwner {
        _unpause();
    }

    function emergencyWithdraw() external onlyByOwner {
        uint currentBal = balance();
        if (currentBal > 0) {
            buyToken.safeTransfer(feeAddress, currentBal);
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}