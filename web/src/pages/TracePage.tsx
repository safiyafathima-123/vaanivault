import React from "react";

export const TracePage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Leak Trace & Attribution</h1>
          <p className="text-sm text-slate-500">
            Check suspect files against canary fingerprints to identify the licensed party.
          </p>
        </div>
      </div>
      <div className="bg-white p-8 rounded-lg border border-slate-200 text-center text-slate-500">
        <p className="text-sm">File upload and leak attribution checker will appear here.</p>
      </div>
    </div>
  );
};
