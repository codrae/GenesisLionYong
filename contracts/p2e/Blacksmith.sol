// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../nft/Sword.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title Blacksmith
/// @notice 검 NFT(목검 -> 전설의 검, 6등급)를 강화하는 제련소.
///         VRF 난수와 레벨별 확률(probs)을 비교해 성공 시 levelup, 실패 시 burn.
/// @dev 아래 Sword 주소들은 Goerli 테스트넷에 배포했던 컨트랙트 주소 (현재 지원 종료).
contract Blacksmith is Ownable, VRFConsumerBaseV2 {
    Sword[] swords = [
        Sword(0xbe1514Cae15635F3045660C3861c27d4b72B3FDF), // 목검
        Sword(0x5088E5E3CAae8f634EA8eA37B98211C99D47034B), // 운명의 검
        Sword(0xC04bf57398C179f40911ce075F064f33CdD0F922), // 미련의 검
        Sword(0xbCcCc893859d071DAc71837e4b15579ba2e7b630), // 생명의 검
        Sword(0x05a0a79a907b6ca5186C7678c84A6e023bF31cFB), // 용의 검
        Sword(0x2ae1C3b5b0ec10F74A2E41C31D3626e629115b64)  // 전설의 검
    ];

    uint256[] probs = [0,0,0,0,0,0,0,0,0,0]; // 레벨별 강화 성공 확률(%)

    // ---- Chainlink VRF ----
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 s_keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    mapping(uint256 => uint256) private s_nft_id;  // requestId => nftId
    mapping(uint256 => uint256) private s_ranking; // requestId => ranking

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function setProbs(uint256 position, uint256 value) public onlyOwner {
        probs[position] = value;
    }

    /// @notice 강화 시도 — 소유자만 호출 가능, VRF 난수 요청.
    function enforce(uint256 nftId, uint256 ranking) public payable returns (uint256 requestId) {
        require(swords[ranking].ownerOf(nftId) == msg.sender, "You must be the owner of NFT.");

        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_nft_id[requestId] = nftId;
        s_ranking[requestId] = ranking;
    }

    /// @dev VRF 콜백 — 확률 비교 후 강화 성공/실패 처리.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 d100Value = (randomWords[0] % 100);
        uint256 this_nftId = s_nft_id[requestId];
        uint256 this_ranking = s_ranking[requestId];
        uint256 this_level = swords[this_ranking].swordLevel(this_nftId);
        uint256 this_prob = probs[this_level];

        if (d100Value < this_prob) {
            swords[this_ranking].levelup(this_nftId); // 강화 성공
        } else {
            swords[this_ranking].burn(this_nftId);     // 강화 실패 -> 소각
        }
    }
}
