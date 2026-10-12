import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

const contractsOutDir = path.join(rootDir, "contracts", "out");
const serverAbiDir = path.join(rootDir, "server", "src", "abi");
const webAbiDir = path.join(rootDir, "web", "src", "abi");

const targets = [
  {
    contract: "VaaniVault",
    sourceFile: path.join(contractsOutDir, "VaaniVault.sol", "VaaniVault.json"),
  },
  {
    contract: "VaaniLicence",
    sourceFile: path.join(contractsOutDir, "VaaniLicence.sol", "VaaniLicence.json"),
  },
];

for (const dir of [serverAbiDir, webAbiDir]) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

for (const target of targets) {
  if (!fs.existsSync(target.sourceFile)) {
    console.error(`Artifact not found for ${target.contract}: ${target.sourceFile}`);
    process.exit(1);
  }

  const artifact = JSON.parse(fs.readFileSync(target.sourceFile, "utf-8"));
  const abiContent = JSON.stringify(artifact.abi, null, 2);

  const serverDest = path.join(serverAbiDir, `${target.contract}.json`);
  const webDest = path.join(webAbiDir, `${target.contract}.json`);

  fs.writeFileSync(serverDest, abiContent);
  fs.writeFileSync(webDest, abiContent);

  console.log(`Synced ABI for ${target.contract} -> server/src/abi and web/src/abi`);
}

console.log("ABI sync completed successfully.");
