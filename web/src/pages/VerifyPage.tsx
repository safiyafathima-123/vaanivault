import React from "react";

export const VerifyPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Verify a Licence</h1>
          <p className="text-sm text-slate-500">
            Public verification tool for checking dataset licence validity on Monad.
          </p>
        </div>
      </div>
      <div className="bg-white p-8 rounded-lg border border-slate-200 text-center text-slate-500">
        <p className="text-sm">Public verification lookup form will appear here.</p>
      </div>
    </div>
  );
};
