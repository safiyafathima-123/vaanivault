import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

const broadcastDir = path.join(rootDir, "contracts", "broadcast", "Deploy.s.sol", "10143");
const deploymentJsonPath = path.join(rootDir, "deployments", "monad-testnet.json");
const runLatestPath = path.join(broadcastDir, "run-latest.json");

console.log("=== Post-Deployment Sync ===");

if (!fs.existsSync(runLatestPath)) {
  console.error(`Error: Broadcast file not found at ${runLatestPath}`);
  console.error("Please run the deployment script first with `--broadcast`.");
  process.exit(1);
}

const broadcastData = JSON.parse(fs.readFileSync(runLatestPath, "utf-8"));
const transactions = broadcastData.transactions || [];
const receipts = broadcastData.receipts || [];

let vaaniLicenceAddress = null;
let vaaniVaultAddress = null;
let licenceArguments = [];
let vaultArguments = [];
let deployBlock = 0;

for (const tx of transactions) {
  if (tx.transactionType === "CREATE") {
    if (tx.contractName === "VaaniLicence") {
      vaaniLicenceAddress = tx.contractAddress;
      licenceArguments = tx.arguments || [];
    } else if (tx.contractName === "VaaniVault") {
      vaaniVaultAddress = tx.contractAddress;
      vaultArguments = tx.arguments || [];
    }
  }
}

// Extract deployment block from receipt if available, or fallback to first tx / broadcast receipt
if (receipts.length > 0 && receipts[0].blockNumber) {
  deployBlock = typeof receipts[0].blockNumber === "string"
    ? parseInt(receipts[0].blockNumber, 16)
    : receipts[0].blockNumber;
}

if (!vaaniLicenceAddress || !vaaniVaultAddress) {
  console.error("Error: Could not extract VaaniLicence or VaaniVault CREATE transaction from broadcast.");
  process.exit(1);
}

const deploymentInfo = {
  chainId: 10143,
  VaaniLicence: vaaniLicenceAddress,
  VaaniVault: vaaniVaultAddress,
  deployBlock: deployBlock,
  constructorArgs: {
    VaaniLicence: licenceArguments,
    VaaniVault: vaultArguments,
  },
  updatedAt: new Date().toISOString(),
};

fs.writeFileSync(deploymentJsonPath, JSON.stringify(deploymentInfo, null, 2) + "\n");
console.log(`Updated ${deploymentJsonPath}:`);
console.log(JSON.stringify(deploymentInfo, null, 2));

// Run sync-abi.mjs
console.log("\nRunning sync-abi.mjs...");
const syncScriptPath = path.join(__dirname, "sync-abi.mjs");
execFileSync(process.execPath, [syncScriptPath], { stdio: "inherit" });

console.log("\nPost-deployment processing complete!");
