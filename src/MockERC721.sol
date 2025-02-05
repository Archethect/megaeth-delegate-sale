// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockNFT", "MNFT") {}

    /**
     * @notice Mint a new NFT to the caller.
     */
    function mint() public {
        _tokenIdCounter++;
        _mint(msg.sender, _tokenIdCounter);
    }
}
