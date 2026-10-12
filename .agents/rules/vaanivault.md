---
trigger: always_on
---

# VaaniVault Project Rules

## Source of Truth
- The final project requirements are in `docs/PRD.md`. Read the relevant sections before writing code.
- If a task conflicts with the PRD or the PRD is unclear, stop and ask. Never invent features.

## Network
- Use Monad testnet only.
- Chain ID: `10143`
- RPC: `https://testnet-rpc.monad.xyz`
- Explorer: `https://testnet.monadvision.com`
- Currency: MON (testnet only).
- Contract addresses and deployment block belong in `deployments/monad-testnet.json`.
- Copy contract ABIs from the contracts build output using a script. Never hand-write ABIs.

## Project Structure
- `/contracts`: Foundry, Solidity 0.8.24, OpenZeppelin Contracts v5.
- `/server`: Node.js 20, TypeScript, Express, viem, better-sqlite3, zod.
- `/web`: React, Vite, TypeScript, Tailwind, react-router, wagmi v2, viem.
- Work only in the folders specified by the current task.
- Do not refactor unrelated code.
- Do not add dependencies without explaining why.

## Secrets and Privacy
- Never read, print, log, echo, or commit private keys or `.env` values. Refer to environment variable names only.
- Keep every `.env.example` updated with variable names and comments, but never actual secret values.
- Never put personal data or raw files on-chain. Store only hashes, addresses, amounts, and statuses.

## Monad-Specific Design
- Keep contract state keyed per dataset and per request.
- Avoid global counters that user transactions write to, to support Monad parallel execution.
- Contributors and council voters must not need MON. Their actions use EIP-712 signatures submitted by the server relayer.
- Approval must pay every contributor, the community fund, and the platform in one transaction.

## Transactions in the UI
- Every write must show: awaiting signature → pending → confirmed, with an explorer link.
- Relayed actions must show: signed → relaying → confirmed.
- Never show success before a transaction receipt is confirmed.
- Decode custom errors into plain-language messages.
- Label every amount as “testnet MON.”
- Clearly label demo data as demo data.

## Contributor and Voter Screens
- Use simple wording: “Sign in,” “Approve,” and “Your earnings.”
- Avoid crypto terminology such as “wallet,” “gas,” “transaction,” and “seed phrase” on these screens.

## Finishing a Task
- Run the relevant tests and builds.
- Report what passed and failed.
- List any deviations from the PRD and explain why.
- Stop after completing the assigned task. Do not start the next task automatically.