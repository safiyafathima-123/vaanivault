import { defineChain } from "viem";
import * as chains from "viem/chains";

export const monadTestnet =
  "monadTestnet" in chains && (chains as Record<string, any>).monadTestnet
    ? (chains as Record<string, any>).monadTestnet
    : defineChain({
        id: 10143,
        name: "Monad Testnet",
        nativeCurrency: {
          name: "Monad",
          symbol: "MON",
          decimals: 18,
        },
        rpcUrls: {
          default: {
            http: ["https://testnet-rpc.monad.xyz"],
          },
        },
        blockExplorers: {
          default: {
            name: "MonadVision",
            url: "https://testnet.monadvision.com",
          },
        },
        testnet: true,
      });
