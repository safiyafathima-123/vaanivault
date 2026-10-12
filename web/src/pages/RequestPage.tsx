import React from "react";
import { useParams } from "react-router-dom";

export const RequestPage: React.FC = () => {
  const { datasetId } = useParams<{ datasetId: string }>();

  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg border border-slate-200">
        <h1 className="text-xl font-bold text-slate-900">Request Licence</h1>
        <p className="text-sm font-mono text-slate-500 mt-1">Target Dataset: {datasetId}</p>
        <div className="mt-6 text-sm text-slate-500">
          Licence request form with purpose selection and escrow deposit will appear here.
        </div>
      </div>
    </div>
  );
};
