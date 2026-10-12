import React from "react";
import { useAccount, useConnect, useDisconnect } from "wagmi";

export const ConnectButton: React.FC = () => {
  const { address, isConnected } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected && address) {
    const formatted = `${address.slice(0, 6)}...${address.slice(-4)}`;
    return (
      <div className="flex items-center gap-2">
        <span className="font-mono text-xs px-2.5 py-1.5 rounded bg-slate-100 text-slate-800 border border-slate-200">
          {formatted}
        </span>
        <button
          onClick={() => disconnect()}
          className="px-3 py-1.5 text-xs font-medium rounded border border-slate-300 text-slate-700 bg-white hover:bg-slate-50 cursor-pointer"
        >
          Disconnect
        </button>
      </div>
    );
  }

  // Find the injected connector
  const injectedConnector = connectors.find((c) => c.id === "injected") || connectors[0];

  return (
    <button
      onClick={() => injectedConnector && connect({ connector: injectedConnector })}
      disabled={isPending || !injectedConnector}
      className="px-3.5 py-1.5 text-xs font-semibold rounded bg-slate-900 text-white hover:bg-slate-800 disabled:opacity-50 cursor-pointer"
    >
      {isPending ? "Connecting..." : "Connect"}
    </button>
  );
};
