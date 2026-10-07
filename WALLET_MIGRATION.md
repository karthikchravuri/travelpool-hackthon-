# Wallet migration status

Two wallet paths exist right now, and their state is kept strictly separate.

| | Real wallet | Demo wallet |
|---|---|---|
| `wallet.type` | `"metamask"` | `"demo"` |
| Source | `window.ethereum` via ethers v6 `BrowserProvider` | fixed address, signs nothing |
| Network checks | live `eth_chainId`, `chainChanged` events | none — never reports a network |
| `canTransact` | true on the configured chain with contracts set | **always false** |
| On-chain writes | `join()`, `approve()`, `faucet()`, `vote()` signed by the user | never |

The demo wallet is a **development fallback only**. It is gated behind
`VITE_ENABLE_DEMO_WALLET` (default on) and can be switched off with:

```
VITE_ENABLE_DEMO_WALLET=false
```

## What is built

- `window.ethereum` + ethers v6, loaded on demand so it stays out of the initial bundle
- Wallet states: Disconnected → "Connect Wallet"; Connecting → "Connecting to MetaMask…";
  Connected → shortened real address; Wrong Network → "Wrong Network" + "Switch to Sepolia";
  Rejected → "Connection request rejected"; Not installed → "Install MetaMask"
- `wallet_switchEthereumChain`, falling back to `wallet_addEthereumChain` when MetaMask
  does not know Sepolia yet (error 4902)
- `accountsChanged` and `chainChanged` listeners; changing account refetches profile,
  membership, claims and voting power
- Join Pool as real user-signed transactions: `faucet()` (only if short) → `approve()` →
  `join()`, each confirmed in MetaMask
- Transaction overlay: "Confirm transaction in MetaMask…" → "Transaction submitted" →
  "Transaction confirmed", with the hash and a "View on Etherscan" link
- Nothing is reported as confirmed before `tx.wait()` resolves

## What still blocks removing the demo wallet

The contracts are **not deployed to Sepolia yet**, so steps 2–4 of the migration cannot be
signed off. `VITE_CONTRACT_ADDRESS` and `VITE_TOKEN_ADDRESS` are empty, which means
`canTransact` is false and no real transaction can be requested.

Deploying needs a funded Sepolia key, which only you can supply:

```bash
# .env  (never commit this)
SEPOLIA_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
PRIVATE_KEY=<a key you control, funded with Sepolia ETH>

npm run compile  --workspace blockchain
npm run deploy:sepolia --workspace blockchain
```

The deploy script prints the three values to paste into `frontend/.env`, plus
`CONTRACT_ADDRESS` for the backend.

## Verification checklist

Run through this with MetaMask installed and the addresses configured:

- [ ] MetaMask opens on "Connect Wallet"
- [ ] Real address appears, shortened
- [ ] Switching account in MetaMask updates profile, membership and voting power
- [ ] Switching to a non-Sepolia network shows "Wrong Network"
- [ ] "Switch to Sepolia" switches, and offers to add the network if unknown
- [ ] Dismissing the MetaMask prompt shows "Connection request rejected"
- [ ] Join Pool opens MetaMask and asks for each signature in turn
- [ ] The overlay only says "Transaction confirmed" after the block confirms
- [ ] The transaction hash shown matches Etherscan, and the link opens it

Once every box is ticked, remove the demo wallet: delete `DEMO_WALLET`, `connectDemo`,
`isDemoWallet` and `DEMO_WALLET_ENABLED` from `frontend/src/services/wallet.js`, the demo
branch in `AppContext.connect`, the demo button in `components/Wallet.jsx`, and the
`isDemo` branches in `NetworkBadge`, `NetworkGuard`, `JoinPool` and `pages/Profile.jsx`.
