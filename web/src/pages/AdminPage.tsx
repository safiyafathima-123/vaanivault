import React from "react";

export const AdminPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Admin & Operations</h1>
          <p className="text-sm text-slate-500">
            Pause listings, check relayer gas budget, and inspect system telemetry.
          </p>
        </div>
      </div>
      <div className="bg-white p-8 rounded-lg border border-slate-200 text-center text-slate-500">
        <p className="text-sm">Admin controls and relayer status will appear here.</p>
      </div>
    </div>
  );
};
