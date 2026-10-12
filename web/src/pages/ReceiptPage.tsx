import React from "react";
import { useParams } from "react-router-dom";

export const ReceiptPage: React.FC = () => {
  const { requestId } = useParams<{ requestId: string }>();

  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg border border-slate-200">
        <h1 className="text-xl font-bold text-slate-900">Settlement Receipt</h1>
        <p className="text-sm font-mono text-slate-500 mt-1">Request ID: {requestId}</p>
        <div className="mt-6 text-sm text-slate-500">
          On-chain settlement timeline, individual contributor payout table, and token links will appear here.
        </div>
      </div>
    </div>
  );
};
