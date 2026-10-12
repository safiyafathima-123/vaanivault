# VaaniVault

Community-governed AI data licensing and revenue sharing on Monad.

---

## 1. Problem and Who It Serves

AI models learn Indian languages from voices that were never asked. Contributors who record voices, text, or images rarely know who trains on their data, for what purpose, or under what terms. Furthermore, communities pooling linguistic and cultural data have had no transparent, collective governance mechanism to say yes or no, and individual contributors are left out of revenue splits.

VaaniVault gives communities a verifiable way to govern access to their datasets and ensures every contributor receives their fair share of revenue directly upon approval. The showcase deployment highlights a Tamil voice dataset recorded with contributor consent in Chennai.

## 2. How It Works

1. **Invite & Consent**: Stewards invite contributors and council members via phone/email logins. Contributors sign gasless EIP-712 consent covering their clips and permitted purposes.
2. **Dataset Registration**: The steward registers the dataset on-chain with a Merkle root of file hashes, consent root, revenue split parameters, and council governance rules.
3. **Licence Request & Escrow**: An AI developer requests a dataset licence by selecting an allowed purpose, reviewing the generated agreement, and depositing testnet MON into escrow.
4. **Community Council Vote**: Council members cast gasless votes (Approve / Reject / Abstain). Sponsoring relayers submit the EIP-712 votes to Monad.
5. **Instant Settlement**: Upon reaching the approval threshold, the approving transaction atomically splits payment across all non-revoked contributors, the community fund, and the platform, while minting a soulbound licence NFT to the requester.
6. **Fingerprinted Delivery**: The licensee receives a unique bundle with canary audio clips, cryptographically fingerprinted on-chain to detect and trace leaks.

## 3. Every Flaw and Its In-Product Fix

| Identified Flaw | In-Product Fix | Where |
|---|---|---|
| Contributors have no crypto wallets | Phone or email login creates a wallet invisibly | PRD Section 7 |
| Contributors and voters have no MON for gas | Signed actions submitted by a sponsoring relayer | PRD Sections 7, 9 |
| "Why not a database?" | Escrow, payouts, and licences verifiable on Monad without trusting a server | PRD Sections 2, 9 |
| Copying after download | Fingerprinted bundles + leak-trace canary matching | PRD Section 11 |
| Fake ownership or scraped data | Per-clip consent signatures, invite-only onboarding, admin pause | PRD Sections 7, 11 |
| Consent withdrawal (DPDP Act 2023) | One-tap gasless revocation on-chain; revoked clips excluded from future bundles & payouts | PRD Section 11 |
| Buyers need legal certainty | Generated licence agreement hashed and signed in request & stored in licence | PRD Section 9 |
| Fake or inactive councils | Invite-only council, quorum requirements, and auto-refund on expiry | PRD Section 8 |
| Lump-sum payouts hide distribution | Direct per-contributor credits visible on the transparent receipt | PRD Section 10 |
| Not Monad-specific | Parallel-friendly contract design, sub-second settlement, and micropayments | PRD Section 2 |

## 4. Why Monad (Gas and Settlement Measurements)

Monad's 10,000 TPS, 300 ms block times, 600 ms finality, and tiny transaction costs make direct micro-distribution economically feasible:

- **Instant Settlement**: Approval, multi-party payout, and licence minting occur atomically in a single sub-second transaction.
- **Micro-Payouts**: Crediting fractions of a cent to dozens of contributors is prohibitive on chains with standard L1 gas fees.
- **Gasless Participation**: Low fees make relayer sponsorship sustainable at scale.
- **Parallel Execution Compatibility**: State storage is cleanly partitioned per-dataset and per-request to prevent shared state contention across parallel threads.

## 5. Contracts: Addresses, Verified Source Links, Test Summary

- **Network**: Monad Testnet (Chain ID: 10143)
- **RPC Endpoint**: `https://testnet-rpc.monad.xyz`
- **Explorer**: `https://testnet.monadvision.com`
- **VaaniVault**: (Pending deployment)
- **VaaniLicence**: (Pending deployment)

### Test Summary
- Contract test suites cover unit logic, EIP-712 signature verification, multi-recipient settlement math, and failure modes.

## 6. Limitations, Stated Plainly

- **Copying Files**: No technical architecture can prevent a licensee from copying unencrypted data files once downloaded; canary fingerprinting deters and attributes leaks rather than preventing reproduction.
- **Identity Verification**: Phone login establishes control of a verified credential, not legal identity or copyright authorship; the steward's invite remains the trust anchor.
- **Canary Robustness**: v1 matches exact file hashes of canary clips; re-encoding or targeted stripping requires audio transcription matching (planned for v2).

## 7. Roadmap

1. **High-Frequency Licensing**: Sub-second per-batch micropayment licensing for autonomous AI agents.
2. **Merkle Distributor**: Scalable payouts for datasets with thousands of contributors.
3. **Dispute Bonding**: Verifiable steward applications with bonded challenge periods.
4. **Fiat On/Off Ramps**: Credit card purchasing and local currency payouts for contributors.
5. **Acoustic Canary Matching**: Robust watermarking surviving re-encoding and model parameter probing.
6. **Agent Identity (ERC-8004)**: Autonomous AI agent licensing and on-chain track records.
7. **Multi-Language Expansion**: Onboarding regional languages across India and Southeast Asia.

## 8. How to Run It Locally; Demo Accounts

### Prerequisites
- Node.js 20+
- Git
- Monad Foundry (`foundryup --network monad`)

### Setup & Run
```bash
# 1. Setup & build smart contracts
cd contracts
forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts@v5.0.2
forge build

# 2. Start server
cd ../server
npm install
npm run dev

# 3. Start web frontend
cd ../web
npm install
npm run dev
```
