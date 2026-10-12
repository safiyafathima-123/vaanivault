import React from "react";
import { Link } from "react-router-dom";

export const HomePage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg border border-slate-200">
        <h1 className="text-2xl font-bold text-slate-900">Welcome to VaaniVault</h1>
        <p className="mt-2 text-slate-600 max-w-2xl">
          Community-governed AI data licensing and revenue sharing on Monad. Contributors sign
          consent without wallets, AI teams pay into escrow in testnet MON, and community councils
          vote gaslessly to settle payouts instantly.
        </p>
        <div className="mt-6 flex flex-wrap gap-3">
          <Link
            to="/marketplace"
            className="px-4 py-2 text-sm font-semibold rounded bg-slate-900 text-white hover:bg-slate-800"
          >
            Explore Marketplace
          </Link>
          <Link
            to="/community"
            className="px-4 py-2 text-sm font-semibold rounded border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
          >
            Community Setup
          </Link>
        </div>
      </div>
    </div>
  );
};
