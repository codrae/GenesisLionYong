// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Sword
/// @notice ERC721 NFT with per-token level. MINTER_ROLE and LEVELUP_ROLE are
///         separated so minting and upgrading can be delegated to other contracts.
contract Sword is ERC721, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant LEVELUP_ROLE = keccak256("LEVELUP_ROLE");
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public swordLevel; // tokenId => level

    constructor() ERC721("Sword", "SWD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function levelup(uint256 nftId) public onlyRole(LEVELUP_ROLE) {
        require(swordLevel[nftId] <= 10, "level too high");
        swordLevel[nftId] = swordLevel[nftId] + 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
