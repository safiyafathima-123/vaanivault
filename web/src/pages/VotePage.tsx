import React from "react";
import { useParams } from "react-router-dom";

export const VotePage: React.FC = () => {
  const { requestId } = useParams<{ requestId: string }>();

  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg border border-slate-200">
        <h1 className="text-xl font-bold text-slate-900">Council Vote Card</h1>
        <p className="text-sm font-mono text-slate-500 mt-1">Request ID: {requestId}</p>
        <div className="mt-6 text-sm text-slate-500">
          Mobile-friendly gasless vote interface with live tally will appear here.
        </div>
      </div>
    </div>
  );
};
