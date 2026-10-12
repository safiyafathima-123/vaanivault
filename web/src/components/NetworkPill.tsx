import React from "react";
import { useAccount, useSwitchChain } from "wagmi";
import { monadTestnet } from "../lib/chain";

export const NetworkPill: React.FC = () => {
  const { isConnected, chainId } = useAccount();
  const { switchChain, isPending } = useSwitchChain();

  const isWrongChain = isConnected && chainId !== monadTestnet.id;

  if (isWrongChain) {
    return (
      <div className="flex items-center gap-2 px-3 py-1.5 text-xs font-medium rounded-full bg-amber-50 text-amber-800 border border-amber-300">
        <span className="w-2 h-2 rounded-full bg-amber-500" />
        <span>Wrong Network (Chain {chainId})</span>
        <button
          onClick={() => switchChain({ chainId: monadTestnet.id })}
          disabled={isPending}
          className="ml-1 px-2 py-0.5 text-xs font-semibold rounded bg-amber-600 text-white hover:bg-amber-700 disabled:opacity-50 cursor-pointer"
        >
          {isPending ? "Switching..." : "Switch to Monad Testnet"}
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2 px-3 py-1.5 text-xs font-medium rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200">
      <span className="w-2 h-2 rounded-full bg-emerald-500" />
      <span>Monad Testnet ({monadTestnet.id})</span>
    </div>
  );
};
