// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

contract FreepadNFT is ERC721URIStorage, Ownable {
    uint256 public constant MAX_SUPPLY = 100000000;
    uint256 public totalMinted = 0;
    mapping(address => bool) private _hasSoulbound;

    AggregatorV3Interface internal priceFeed;
    uint256 public constant PRICE_IN_USD = 20 * 1e18;

    event Minted(address indexed recipient, uint256 tokenId);
    event Burned(uint256 tokenId);

    constructor() ERC721("FreepadNFT", "FNFT") Ownable(msg.sender) {
        priceFeed = AggregatorV3Interface(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);
    }

    /**
     * @dev Mint a new Soulbound Token to a specific address with metadata URI.
     *      Requires payment equivalent to $20 in ETH.
     * @param to The address of the recipient.
     * @param tokenURI The metadata URI for the token.
     */
    function mint(address to, string memory tokenURI) external payable {
        require(!_hasSoulbound[to], "TOKEN_ALREADY_MINTED");
        require(totalMinted < MAX_SUPPLY, "MAXIMUM_SUPPLY_REACHED");
        
        uint256 ethPrice = getLatestETHPrice();
        uint256 requiredETH = (PRICE_IN_USD * 1e18) / ethPrice;
        require(msg.value >= requiredETH, "INSUFFICIENT_BALANCE");

        uint256 tokenId = totalMinted + 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        _hasSoulbound[to] = true;
        totalMinted += 1;
        emit Minted(to, tokenId);
        
        if (msg.value > requiredETH) {
            uint256 refund = msg.value - requiredETH;
            payable(msg.sender).transfer(refund);
        }
    }

    /**
     * @dev Override `_transfer` to prevent transfers of Soulbound Tokens.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override {
        require(false, "CANNOT_TRANSFER");
    }

    /**
     * @dev Override `transferFrom` to prevent transfers of Soulbound Tokens.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override(ERC721, IERC721) {
        require(false, "CANNOT_TRANSFER");
    }

    /**
     * @dev Override `safeTransferFrom` to prevent transfers of Soulbound Tokens.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public pure override(ERC721, IERC721) {
        require(false, "CANNOT_TRANSFER");
    }

    /**
     * @dev Burn a Soulbound Token.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can burn their Soulbound Token");
        _burn(tokenId);
        _hasSoulbound[msg.sender] = false;
        emit Burned(tokenId);
    }

    /**
     * @dev Check if an address owns a Soulbound Token.
     * @param owner The address to check.
     * @return bool Returns true if the address owns a Soulbound Token, false otherwise.
     */
    function hasSoulbound(address owner) external view returns (bool) {
        return _hasSoulbound[owner];
    }

    /**
     * @dev Get the latest ETH price in USD (18 decimals).
     * @return uint256 ETH price in USD.
     */
    function getLatestETHPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 1e10;
    }

    /**
     * @dev Withdraw ETH from the contract (only owner).
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
