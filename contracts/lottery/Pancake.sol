// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title Pancake
/// @notice 회차(round)별 3자리 복권. 당첨 번호는 Chainlink VRF로 추첨.
/// @dev VRF 설정값은 Goerli 테스트넷 기준 (현재 지원 종료).
contract Pancake is VRFConsumerBaseV2, Ownable {
    uint256 round;
    uint256 price = 0.01 ether;
    uint256 winning_price = 0.01 ether;

    // round => (player => numbers)
    mapping(uint256 => mapping(address => uint256[])) my_numbers;
    // round => winning numbers
    mapping(uint256 => uint256[]) winning_numbers;

    // ---- Chainlink VRF ----
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 s_keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 6000000;
    uint32 numWords = 3;
    mapping(uint256 => uint256) round_mapping; // requestId => round

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function lottery_in(uint256[] memory numbers) public payable {
        if (msg.value == price) {
            my_numbers[round][msg.sender] = numbers;
        } else {
            revert("Not enough ETH");
        }
    }

    /// @dev VRF 콜백 — 추첨 번호 3개를 한 자리수로 변환해 회차에 저장.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 value0 = (randomWords[0] % 10);
        uint256 value1 = (randomWords[1] % 10);
        uint256 value2 = (randomWords[2] % 10);
        uint256 this_round = round_mapping[requestId];
        winning_numbers[this_round] = [value0, value1, value2];
    }

    function lottery_set(uint256 this_round) public onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        round_mapping[requestId] = this_round;
    }

    function check_lottery_number(uint256 this_round) public view returns (uint256[] memory) {
        return winning_numbers[this_round];
    }

    function claim(uint256 this_round) public {
        uint256 point = 0;
        if (winning_numbers[this_round][0] == my_numbers[this_round][msg.sender][0]) {
            point = point + 1;
            if (winning_numbers[this_round][1] == my_numbers[this_round][msg.sender][1]) {
                point = point + 1;
                if (winning_numbers[this_round][2] == my_numbers[this_round][msg.sender][2]) {
                    point = point + 1;
                }
            }
        }

        if (point > 0) {
            address payable to = payable(msg.sender);
            to.transfer(point * winning_price);
        } else {
            revert("Not a winner");
        }
    }
}
