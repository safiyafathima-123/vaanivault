import React from "react";

export const MarketplacePage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Dataset Marketplace</h1>
          <p className="text-sm text-slate-500">
            Browse community-owned voice, text, and multimodal datasets.
          </p>
        </div>
      </div>
      <div className="bg-white p-8 rounded-lg border border-slate-200 text-center text-slate-500">
        <p className="text-sm">Marketplace listings will appear here.</p>
      </div>
    </div>
  );
};
