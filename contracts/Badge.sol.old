// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Badge is ERC721, Ownable {
    constructor() ERC721("BadgeToken", "BDG") {}

    function createBadge(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "ERC721: caller is not the owner"
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to
    ) internal pure {
        require(
            from == address(0) || to == address(0),
            "Badge - ERC721: Token non transferable"
        );
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}
