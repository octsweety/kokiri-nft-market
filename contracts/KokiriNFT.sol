//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract KokiriNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public minter = address(0xC627D743B1BfF30f853AE218396e6d47a4f34ceA);

    modifier onlyByOwner {
        require(msg.sender == owner() || msg.sender == minter, "!authorized");
        _;
    }

    constructor(address _minter) public 
        ERC721("Magi Kokiri NFT", "MK")
    {
        minter = _minter;
    }

    function setMinter(address _minter) external onlyByOwner {
        require(msg.sender != address(0), "!address");
        minter = _minter;
    }

    function mintNFT(address recipient, string memory tokenURI)
        public onlyByOwner
        returns (uint256 newItemId)
    {
        _tokenIds.increment();

        newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        require(_exists(_tokenId), "!exists");
        require(msg.sender == ownerOf(_tokenId), "!owner");
        _setTokenURI(_tokenId, _tokenURI);
    }

    function transferNFT(address recipient, uint256 _tokenId) external {
        require(_exists(_tokenId), "!exists");
        require(msg.sender == ownerOf(_tokenId), "!owner");

        safeTransferFrom(msg.sender, recipient, _tokenId);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function tokens(address _holder) public view returns (uint256[] memory) {
        uint256 holderBal = balanceOf(_holder);
        uint256[] memory tokenIds = new uint256[](holderBal);
        for (uint i = 0; i < holderBal; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_holder, i);
        }

        return tokenIds;
    }
}