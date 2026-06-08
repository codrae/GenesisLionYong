// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title Lottery
/// @notice 단일 번호 복권. 0.01 ETH로 참여, 관리자가 당첨 번호 설정 후 당첨자가 수령.
contract Lottery {
    mapping(address => uint256) user;
    uint256 total_users;
    uint256 winning_number;
    uint256 winning_ether;

    function lottery_in(uint256 number) public payable {
        if (msg.value == 0.01 ether) {
            user[msg.sender] = number;
            total_users = total_users + 1;
        } else {
            revert(); // 참여비 불일치 시 트랜잭션 실패
        }
    }

    function lottery_set(uint256 number) public {
        winning_number = number;
        winning_ether = address(this).balance / total_users;
    }

    function claim() public {
        if (user[msg.sender] == winning_number) {
            address payable to = payable(msg.sender);
            to.transfer(winning_ether);
            user[msg.sender] = 0; // 중복 클레임 방지 (번호 초기화)
        } else {
            revert();
        }
    }
}
