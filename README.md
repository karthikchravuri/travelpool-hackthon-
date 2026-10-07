# TravelPool — Decentralized Travel Insurance Pool with AI Claims Processing

> **INNOBLOCK 2.0 hackathon project.** A member-owned travel insurance pool where travelers deposit TEST tokens as premiums, submit claims with evidence, an AI engine recommends **APPROVE / REJECT / ESCALATE**, smart contracts pay approved claims automatically, and escalated claims are settled by member voting.

```
npm install
npm run dev        →  http://localhost:5173
```

Sign up, log in, and the dashboard is yours. Wallet connection uses **real MetaMask on Ethereum
Sepolia**; a development-only demo wallet remains as a fallback until real MetaMask use is
verified end to end (see [WALLET_MIGRATION.md](WALLET_MIGRATION.md)). Without an AI key or a
deployed contract the app still runs, using the built-in review engine and a recorded ledger.

---

## Table of contents

1. [Problem](#problem) · 2. [Solution](#solution) · 3. [Features](#features) · 4. [Architecture](#architecture) · 5. [Tech stack](#tech-stack) · 6. [Folder structure](#folder-structure) · 7. [Installation](#installation) · 8. [Environment variables](#environment-variables) · 9. [Blockchain setup](#blockchain-setup) · 10. [AI setup](#ai-setup) · 11. [Test environment](#demo-mode) · 12. [Guided tour](#guided-tour) · 13. [API endpoints](#api-endpoints) · 14. [Smart contracts](#smart-contracts) · 15. [Future improvements](#future-improvements)

---

## Problem

Travel insurance claims for lost luggage, medical costs and cancellations are **slow**, and insurer decisions are **hard to question**. Travelers wait weeks, receive one-line rejections, and cannot see how a decision was made or whether the rules were applied fairly.

## Solution

TravelPool turns insurance into a transparent, community-owned protocol:

| Step | What happens |
|---|---|
| **1. Join Pool** | A traveler deposits a 100 TEST premium. Membership becomes **ACTIVE**, the pool balance and member count increase. |
| **2. Travel** | Members are covered for lost luggage, medical expenses and trip cancellation. |
| **3. Submit Claim** | Evidence files are uploaded **off-chain**; their SHA-256 fingerprint is anchored on-chain with the claim. |
| **4. AI Reviews** | Policy rules + a fraud model produce **APPROVED / REJECTED / ESCALATED** with a confidence score and a plain-language reason. |
| **5. Community Decides** | Escalated claims go to weighted member voting with quorum and a deadline. |
| **6. Get Paid** | Approved claims trigger the smart-contract payout and the pool balance updates instantly. |

## Features

- **Accounts** — email + password sign-up, log in, log out, protected dashboard. Kept separate from wallet identity.
- **Wallet connection** — real MetaMask via ethers v6, with Sepolia detection, a *Switch to Sepolia*
  action, account/network change handling, and a dev-only demo fallback.
- **Pool Members** — directory of every member with premium deposited, voting power and status.
- **Membership** — join with a 100 TEST premium; status, coverage, voting power on the profile.
- **Multi-step claim flow** — details → drag-and-drop evidence (previews, progress, validation) → animated AI review → decision.
- **Evidence fingerprints** — SHA-256 computed in the browser *and* on the server; a combined bundle hash is stored on-chain. Files never touch the chain.
- **Explainable AI** — decision, confidence, reason and six policy/risk checks for every claim. Optional LLM via any OpenAI-compatible API, with guardrails.
- **Fraud detection** — duplicate evidence hashes, similar descriptions, matching amounts, repeat/rapid submissions and abnormal amounts → fraud score 0–100 with risk level and indicators.
- **Smart-contract payouts** — approved claims pay out automatically; double payouts are impossible.
- **Governance** — vote progress, quorum meter, countdown, approve/reject, one vote per member, no self-voting, non-members blocked.
- **Dashboard** — pool balance, members, claims, reserve ratio, charts (balance history, claim status, payout history, AI decisions) and live activity.
- **Blockchain UX for humans** — “Blockchain Verification” panels expand to tx hash, block, gas and network; badges: `ON-CHAIN VERIFIED`, `AI VERIFIED`, `COMMUNITY APPROVED`.
- **Run Demo page** — three guided scenarios for judges, with live balance animation and a one-click data reset.
- **Responsive** — desktop sidebar, mobile drawer + bottom navigation.

## Architecture

```
┌──────────────────────────── Frontend (React + Vite + Tailwind) ────────────────────────────┐
│ Landing · Overview · Pool · Submit Claim · Claims · Claim Detail · Governance · Activity    │
│ Wallet adapter (MetaMask | Demo) · SHA-256 in browser · Toasts · Tx confirmation overlay    │
└───────────────────────────────────────────┬────────────────────────────────────────────────┘
                                            │ REST /api (Vite proxy)
┌───────────────────────────────────────────▼────────────────────────────────────────────────┐
│                               Backend (Node.js + Express)                                    │
│  routes ─► services (claims · members · pool · ledger)                                       │
│            ├─ AI pipeline:  fraudDetector ─► policy checks ─► LLM engine | Demo engine       │
│            ├─ Storage:      local (content-addressed)  | IPFS (Kubo HTTP API)                │
│            ├─ Blockchain:   ethers.js relayer ─► InsurancePool  | simulated ledger fallback  │
│            └─ SQLite (sql.js, auto-created & seeded)                                         │
└───────────────────────────────────────────┬────────────────────────────────────────────────┘
                                            │ JSON-RPC (operator / AI oracle / gas relayer)
┌───────────────────────────────────────────▼────────────────────────────────────────────────┐
│ Hardhat local chain:  TestToken (ERC-20 "TEST")  ·  InsurancePool (membership, claims,       │
│                       evidence hash, AI decision, voting, automatic payouts)                 │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Design decisions**

- **Relayer pattern.** The backend operator account acts as the AI oracle *and* a gas-sponsoring relayer (`joinFor`, `submitClaimFor`, `voteFor`). Members never need ETH, and a demo wallet works exactly like MetaMask. Members can also call `join`, `submitClaim` and `vote` directly.
- **Off-chain evidence, on-chain fingerprint.** Files are stored by a pluggable storage provider; only `bytes32` SHA-256 bundle hashes go on-chain. The contract counts re-used fingerprints and emits `DuplicateEvidenceFlagged`.
- **Graceful degradation.** Each external service has a simulated twin. If a transaction reverts or the chain stops, that action is recorded on the demo ledger and the UI labels it `DEMO LEDGER` instead of `ON-CHAIN`.
- **One source of truth for the UI.** SQLite stores claims, votes, activity and the pool mirror; in chain mode the contract enforces the same rules and the Pool page shows the on-chain balance next to it.

## Tech stack

| Layer | Tech |
|---|---|
| Frontend | React 18, Vite 6, Tailwind CSS 4, React Router 6, Lucide React, hand-built SVG charts (no chart library) |
| Backend | Node.js, Express 5, Multer, ethers.js 6 |
| Database | SQLite via **sql.js** (WebAssembly — no native build tools needed on Windows/macOS/Linux) |
| Blockchain | Solidity 0.8.24, Hardhat 2, OpenZeppelin 5, ethers.js |
| AI | Built-in demo engine + optional OpenAI-compatible LLM (OpenAI, Groq, OpenRouter, Together, Ollama, LM Studio…) |
| Storage | Local content-addressed store, optional IPFS |

## Folder structure

```
travelpool/
├── frontend/
│   ├── src/
│   │   ├── components/      # UI primitives (ui/), charts/, domain components
│   │   ├── context/         # App (wallet/health), Toasts, Tx confirmation overlay
│   │   ├── data/            # Claim types, status metadata, AI steps
│   │   ├── hooks/           # useApi, useCountUp, useClaimActions
│   │   ├── layouts/         # AppLayout (sidebar, top bar, mobile nav)
│   │   ├── pages/           # Landing, Overview, Pool, SubmitClaim, Claims, ClaimDetail,
│   │   │                    # Governance, Activity, Profile, Demo, NotFound
│   │   ├── services/        # api.js, wallet.js
│   │   ├── utils/           # formatting, SHA-256 helpers
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── public/
│   ├── package.json
│   └── vite.config.js
├── backend/
│   ├── src/
│   │   ├── ai/              # fraudDetector, policyRules, demoEngine, llmEngine, pipeline
│   │   ├── database/        # sql.js wrapper, schema, seed, reset
│   │   ├── middleware/      # errors, upload validation, rate limiting
│   │   ├── routes/          # pool, members, claims, evidence, demo
│   │   ├── services/        # blockchain gateway, claims, members, pool, ledger, demo evidence
│   │   ├── storage/         # local + IPFS providers
│   │   ├── utils/
│   │   └── server.js
│   ├── data/                # travelpool.db + deployment.json (generated)
│   ├── uploads/             # off-chain evidence (generated)
│   ├── package.json
│   └── .env.example
├── blockchain/
│   ├── contracts/           # TestToken.sol, InsurancePool.sol
│   ├── scripts/             # deploy.js, wait-and-deploy.js
│   ├── test/                # InsurancePool.test.js
│   ├── hardhat.config.js
│   └── package.json
├── README.md
├── package.json             # npm workspaces + root scripts
├── .gitignore
└── .env.example
```

## Installation

**Requirements:** Node.js **18.18+** (20 or 22 LTS recommended) and npm.

```bash
# 1. Extract the ZIP and open the folder in VS Code
cd travelpool

# 2. Install everything (frontend, backend and blockchain workspaces)
npm install

# 3. Start the app in Demo Mode
npm run dev
```

Open **http://localhost:5173** (Vite opens it automatically). The API runs on **http://localhost:4000/api**. On first start the SQLite database is created and seeded automatically.

| Command | What it does |
|---|---|
| `npm run dev` | Backend + frontend (Demo Mode — simulated ledger) |
| `npm run dev:chain` | Hardhat node + contract deployment + backend + frontend (**real on-chain mode**) |
| `npm run blockchain` | Start a local Hardhat node only |
| `npm run deploy` | Deploy contracts to the running local node |
| `npm run backend` / `npm run frontend` | Start one service |
| `npm run compile` | Compile Solidity contracts |
| `npm run test:contracts` | Run the smart-contract test suite |
| `npm run reset` | Reset demo data (1,000 TEST pool · 128 members · 42 claims) |
| `npm run build` | Production build of the frontend |
| `npm start` | Build the frontend and serve app + API from http://localhost:4000 |

## Environment variables

Everything is optional. Copy `.env.example` to `.env` (root or `backend/`) only if you want to change something.

| Variable | Default | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | *(empty)* | Enables the LLM claims engine. Empty → demo AI engine |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | Any OpenAI-compatible endpoint |
| `OPENAI_MODEL` | `gpt-4o-mini` | Model name |
| `RPC_URL` | `http://127.0.0.1:8545` | EVM JSON-RPC endpoint |
| `PRIVATE_KEY` | *(empty)* | Operator / AI oracle key. Empty on Hardhat → the node's unlocked dev account is used |
| `CONTRACT_ADDRESS` | *(empty)* | InsurancePool address. Empty → read from `backend/data/deployment.json` |
| `STORAGE_PROVIDER` | `local` | `local` or `ipfs` |
| `IPFS_API_URL` / `IPFS_GATEWAY_URL` | local Kubo / ipfs.io | IPFS settings |
| `PORT` | `4000` | API port |
| `CORS_ORIGIN` | `*` | Allowed origin(s), comma-separated |

> Never commit a real private key. `.env` is git-ignored and TravelPool only ever needs test keys.

## Blockchain setup

### Ethereum Sepolia (real network)

```bash
# .env — never commit this file
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
PRIVATE_KEY=<a key you control, funded with Sepolia ETH>

npm run compile --workspace blockchain
npm run deploy:sepolia --workspace blockchain
```

The deploy script prints `VITE_CHAIN_ID`, `VITE_CONTRACT_ADDRESS` and `VITE_TOKEN_ADDRESS` for
`frontend/.env`, plus `CONTRACT_ADDRESS` for the backend. Until those are set, no real transaction
can be signed and the UI says so rather than pretending otherwise.

### Local Hardhat chain

**One command:**

```bash
npm run dev:chain
```

This starts a Hardhat node, waits for it, compiles and deploys `TestToken` + `InsurancePool`, registers 10 community validator members (10 × 100 TEST = **1,000 TEST** pool), writes `backend/data/deployment.json`, and the backend connects automatically (within ~5 seconds). Click the **Demo Mode** pill to see *Blockchain: LIVE · Hardhat Local*, and every join, claim, AI decision, vote and payout becomes a real transaction (`ON-CHAIN` badge in Blockchain Verification).

**Manual (three terminals):**

```bash
npm run blockchain        # terminal 1 – local chain on :8545
npm run deploy            # terminal 2 – deploy contracts (once per chain start)
npm run dev               # terminal 3 – backend + frontend
```

*First compile downloads the Solidity 0.8.24 compiler, so it needs internet access once.* If you restart the Hardhat node, run `npm run deploy` again; until then the backend falls back to the demo ledger automatically.

**MetaMask (optional):** add network `http://127.0.0.1:8545`, chain ID `31337`. Because the backend sponsors gas, any account works — no funds needed.

## AI setup

The AI pipeline lives in `backend/src/ai/`:

1. **`fraudDetector.js`** — extracts features against pool history (duplicate evidence hash, description similarity, matching amounts, claimant frequency, rapid submissions, amount vs. type average) and scores them with an explainable heuristic model. The model sits behind a `score(features)` interface (`setFraudModel`) so a trained ML model can replace it without touching callers.
2. **`policyRules.js` + `demoEngine.js`** — deterministic policy checks (coverage & exclusions, limits, evidence, timeline, policy reference, fraud screening) and the demo decision engine.
3. **`llmEngine.js`** — when `OPENAI_API_KEY` is set, the claim, policy, evidence fingerprints, rule checks and fraud report are sent to an OpenAI-compatible model that returns JSON `{decision, confidence, reason}`.
4. **Guardrails (`index.js`)** — hard policy failures are always rejected; claims with fraud score ≥ 60 are never auto-approved by the LLM; on timeout/errors the demo engine is used automatically.

Decision logic of the demo engine:

| Outcome | When |
|---|---|
| **REJECTED** | Hard policy failure (excluded cause, over limit, outside filing window, no evidence) or critical fraud (≥ 92) |
| **ESCALATED** | Fraud score ≥ 50, amount above the auto-approval threshold, or multiple warnings → member vote |
| **APPROVED** | Everything else — paid immediately by the contract |

Example (no key needed): *ESCALATED · 61% — “The submitted amount (700 TEST) is unusually high compared with previous lost luggage claims (avg 271 TEST) and similar evidence has appeared in an earlier submission (TP-007).”*

## Demo mode

TravelPool runs even if MetaMask is missing, no blockchain is running, no AI key is set and IPFS is unavailable. The top bar shows a **Demo Mode** pill; click it to see each service:

| Service | Live | Demo fallback |
|---|---|---|
| Wallet | MetaMask | Built-in demo wallet `0x71C9…92AC` |
| Blockchain | Hardhat / any EVM via ethers.js | Simulated ledger with realistic tx hashes, blocks and gas |
| AI | OpenAI-compatible LLM | TravelPool Demo AI engine |
| Evidence storage | IPFS | Local content-addressed storage |

Seeded demo data: **1,000 TEST** pool, **128** members, **42** claims, **18** paid, **87%** reserve ratio — including `TP-001` (Lost Luggage, 150 TEST, approved 94%), `TP-002` (Medical, 320 TEST, approved 91%), `TP-003` (Lost Luggage, 700 TEST, escalated, fraud 78) and `TP-004` (Trip Cancellation, 450 TEST, rejected).

## Guided tour

Open **Run Demo** in the sidebar (or `/app/demo`). Press **Reset demo data** first, then **Run full demo** — or run each scenario:

**Scenario 1 — Small luggage claim**
Connect demo wallet → join pool (+100 TEST) → generate evidence fingerprints (luggage receipt + lost baggage report) → submit 150 TEST claim → **AI APPROVED** → smart-contract payout of 150 TEST → pool balance animates down.
`Claim Approved ✓ · AI Approved ✓ · Evidence Verified ✓ · Payout Completed ✓`

**Scenario 2 — Suspicious claim**
Submit a 700 TEST luggage claim whose receipt is byte-identical to evidence from an earlier claim → fraud engine flags duplicate evidence, high amount and similar description → **AI ESCALATED** → live member governance: votes stream in to **7 approve / 3 reject** → majority APPROVE → payout executed → balance updates.

**Scenario 3 — Pool dashboard**
Shows every balance snapshot of the session (start → join → payouts) and **Animate balance** replays the change. Then open **Overview** to show the charts.

Suggested 30-second opening: Landing page → **Launch App** → Overview → Run Demo → Run full demo.

You can also demo manually: **Submit Claim → “Use sample claim”** fills the form and evidence; **Governance** lets you vote on escalated claims (or “Simulate community votes”).

## API endpoints

| Method | Route | Purpose |
|---|---|---|
| POST | `/api/auth/register` | Create an account |
| POST | `/api/auth/login` | Sign in, returns a session token |
| POST | `/api/auth/logout` | End the session |
| GET | `/api/auth/me` | Current account |
| PATCH | `/api/auth/me` | Update traveler details |
| GET | `/api/members` | Pool member directory |


| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Service status (AI / blockchain / storage, demo flags) |
| GET | `/api/pool` | Pool balance, members, premiums, paid, reserve ratio, health, chain status |
| GET | `/api/stats` | Dashboard aggregates + chart series |
| GET | `/api/activity?limit=&type=&address=` | Activity feed with tx hashes |
| POST | `/api/members/join` | `{ address, walletType }` → join pool (100 TEST) |
| GET | `/api/members/:address` | Profile: membership, coverage, claims, payouts, voting power |
| GET | `/api/claims?status=&claimant=` | List claims (`APPROVED`, `REJECTED`, `ESCALATED`, `PENDING`, `PAID`) |
| POST | `/api/claims` | multipart: `address, claimType, amount, travelDate, description, policyRef, evidence[]` |
| GET | `/api/claims/:id` | Claim detail with evidence, votes, transactions, timeline |
| POST | `/api/claims/:id/analyze` | Run AI review; auto-payout if approved, open vote if escalated |
| POST | `/api/claims/:id/vote` | `{ voter, support: "APPROVE" \| "REJECT" }` |
| POST | `/api/claims/:id/payout` | Execute payout for an approved, unpaid claim (idempotent guard) |
| GET | `/api/evidence/:id/file` | Download off-chain evidence |
| POST | `/api/demo/reset` | Reset demo data |
| POST | `/api/demo/claims/:id/community-vote` | Next community member casts a vote (demo) |
| GET | `/api/demo/evidence/:scenario/:file` | Deterministic demo evidence PDFs |

**Security measures:** input validation & sanitisation, claim amount limits, evidence MIME/extension whitelist, 5 MB per file / 6 files, duplicate-vote prevention (DB unique key + contract), member-only voting, claimant self-vote blocked, double-payout prevention (contract `paid` flag + DB guard + serialized mutations), rate limiting, no private keys in code, `nosniff` headers.

## Smart contracts

### `TestToken.sol`
OpenZeppelin ERC-20 **“TravelPool Test Token” (TEST)**. Owner can mint; anyone can use `faucet()` once per hour (1,000 TEST). Test value only.

### `InsurancePool.sol`

| Area | Functions / rules |
|---|---|
| Membership | `join()` (premium via `transferFrom`), `joinFor(member)` (relayer-sponsored), `members(addr)`, `memberCount`, `totalPremiums` |
| Voting power | `votingPower(addr)` = deposited ÷ premium (min 1 for active members) |
| Claims | `submitClaim(type, amount, evidenceHash, policyRef)` / `submitClaimFor(...)`: active member, `0 < amount ≤ maxClaimAmount`, non-zero `bytes32` evidence hash; re-used fingerprints emit `DuplicateEvidenceFlagged` |
| AI decision | `recordAIDecision(id, decision, confidence, fraudScore)` — operator only. **Approved → payout**, Rejected → closed, **Escalated → voting opens** with deadline |
| Voting | `vote(id, support)` / `voteFor(...)`: members only, one vote each, claimant cannot vote, before deadline. Reaching **quorum** finalizes automatically; `finalizeVoting(id)` after the deadline |
| Payout | Internal `_payout`: requires liquidity, sets `paid` before transfer (checks-effects-interactions), `ReentrancyGuard`, `SafeERC20` — a claim can never be paid twice |
| Admin | `setOperator`, `setParameters(premium, maxClaim, votingPeriod, quorum)` |

Deployment parameters: premium 100 TEST · max claim 2,000 TEST · voting period 72 h · quorum 10.
The test suite (`npm run test:contracts`) covers joining, AI-approved payout + double-payout protection, non-member and duplicate-evidence handling, escalation → 7–3 vote → payout, rejection by majority and operator access control.

## Future improvements

- Replace the heuristic fraud model with a trained gradient-boosted / transformer model (feature interface already in place) and add OCR on receipts.
- Pin evidence to IPFS/Filecoin by default and encrypt it with member-held keys (Lit Protocol) for privacy.
- Parametric cover via Chainlink oracles (flight delay/cancellation data → instant payouts).
- Deploy to a public testnet (Sepolia / Polygon Amoy) with account abstraction (ERC-4337) instead of a custom relayer.
- Premium yield strategies, reinsurance tranches and dynamic pricing by risk.
- Reputation-weighted voting, delegation and slashing for bad-faith voters.
- Mobile app with document capture and push notifications.

---

Built for **INNOBLOCK 2.0**. TEST tokens have no monetary value; this is a hackathon prototype, not an insurance product.
