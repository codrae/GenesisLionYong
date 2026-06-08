# Genesis Lion — Solidity / Web3 학습 저장소

> **GENESIS LION** — 메타콩즈·실타래 NFT 홀더를 대상으로 진행된 web3/Solidity 교육 프로그램에서 작성한 학습용 스마트 컨트랙트 모음입니다.
> NFT · 토큰 · P2E · DeFi 미니 프로젝트를 통해 Solidity와 이더리움 스마트 컨트랙트의 기초를 익혔습니다.

---

> ⚠️ **Disclaimer**
> 이 저장소는 **학습 목적**으로 작성되었습니다. 컨트랙트 상당 부분은 교육 프로그램의 강의 내용을 따라 구현했으며,
> Chainlink VRF 사용 코드는 [Chainlink 공식 문서](https://docs.chain.link/vrf)의 예제를 기반으로 합니다.
> 보안 감사를 거치지 않았으며 프로덕션 사용을 목적으로 하지 않습니다.
> 당시 테스트넷은 Goerli 기준이며, 현재는 지원이 종료되었습니다.

---

## 학습 목표

web3 환경에서 직접 가치를 설계해보는 것을 목표로, 아래 세 단계를 순차적으로 구현했습니다.

1. **NFT / 토큰 발행 + 마켓 연결** — ERC721 NFT와 ERC20 토큰을 발행하고 Uniswap 풀에 연결
2. **P2E(Play-to-Earn)** — 확률 기반 NFT 강화, 코인 소모 강화, 등급 시스템
3. **DeFi 기초** — 담보·인출·청산 개념 (학습 단계)

## 다룬 개념

| 영역 | 내용 |
|------|------|
| 토큰 표준 | ERC721(NFT), ERC20(Coin), ERC721Burnable |
| 접근 제어 | `Ownable`, `AccessControl`(MINTER_ROLE / LEVELUP_ROLE), `onlyOwner` modifier 패턴 |
| 난수 | Chainlink VRF v2 (검증 가능한 난수) — `requestRandomWords` → `fulfillRandomWords` 콜백 |
| 라이브러리 | OpenZeppelin Contracts, Chainlink Contracts |
| 메타데이터 | OpenSea Metadata Standard, IPFS vs web2(Netlify) 이미지 호스팅, baseURI |
| DEX | Uniswap 유동성 풀, 슬리피지, 가격비 변동 |
| 거래 정책 | OperatorFilter (마켓플레이스 거래 제한) |
| 검증 | Flatten → Etherscan Verify & Publish (소스 공개로 투명성 확보) |

## 폴더 구조

```
.
├── contracts/
│   ├── nft/
│   │   ├── MetaYong.sol     # ERC721 + Pausable + Burnable + Ownable
│   │   └── Sword.sol        # ERC721 + AccessControl, NFT별 레벨 관리
│   ├── lottery/
│   │   ├── Lottery.sol      # 단순 복권 (단일 번호)
│   │   └── Pancake.sol      # 회차(round)별 복권 + Chainlink VRF
│   └── p2e/
│       └── Blacksmith.sol   # NFT 제련/강화 — VRF 확률로 levelup 또는 burn
└── images/                  # NFT 메타데이터용 이미지
```

> Chainlink VRF의 원본 예제 코드(VRFD20)는 저장소에 포함하지 않았습니다. 실제 사용 흐름은 `Pancake.sol`과 `Blacksmith.sol`에서 확인할 수 있으며, 원본은 [Chainlink 공식 문서](https://docs.chain.link/vrf/v2-5/getting-started)를 참고하세요.

## 핵심 컨트랙트

### `nft/Sword.sol`
NFT마다 레벨을 독립적으로 관리하는 ERC721. `MINTER_ROLE`과 `LEVELUP_ROLE`을 분리해
민팅 권한과 강화 권한을 다른 컨트랙트(예: `Blacksmith`)에 위임할 수 있도록 설계.

### `lottery/Pancake.sol`
PancakeSwap 복권을 참고한 회차 기반 복권. `mapping(round => mapping(address => uint256[]))`
중첩 매핑으로 회차별 참여 번호를 관리하고, 당첨 번호는 Chainlink VRF로 추첨.

### `p2e/Blacksmith.sol`
검 NFT(목검 → 전설의 검, 6등급)를 강화하는 제련소. VRF로 받은 난수와 레벨별 확률(`probs`)을
비교해 성공 시 `levelup`, 실패 시 `burn`.

## 배운 점

- **블록체인에는 진짜 난수가 없다.** 모든 노드가 동일하게 동작해야 하므로 `random()`이 존재하지 않는다. `block.timestamp` 기반 꼼수는 조작 가능해 위험하므로, 검증 가능한 난수(Chainlink VRF)를 사용한다.
- **가스 최적화는 설계 단계에서 결정된다.** ERC721 `Enumerable`은 가스 비용이 크므로 꼭 필요한 경우가 아니면 제외한다. 새 토큰을 `safeMint`하는 것보다 기존 토큰 상태를 바꾸는 `levelup`이 훨씬 저렴하다.
- **권한은 `if`문이 아니라 modifier/Role로.** 소유권 이전·인수를 고려하면 하드코딩된 주소 비교 대신 `onlyOwner` / `AccessControl`로 관리해야 변경 가능성이 열린다.
- **배포된 컨트랙트는 불변이다.** 수정이 필요하면 새로 배포해야 한다.
- **소스 공개가 곧 신뢰다.** Flatten 후 Etherscan에 Verify & Publish 하면 누구나 코드를 검증할 수 있다.

## 기술 스택

`Solidity ^0.8.x` · `OpenZeppelin Contracts` · `Chainlink VRF v2` · `Remix` · `Etherscan` · `Uniswap` · `Netlify(이미지 호스팅)`

---

*GENESIS LION — NFT 홀더 대상 web3 교육 프로그램 (2022) 학습 기록*
