import React from "react";
import { useParams } from "react-router-dom";

export const DatasetDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();

  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg border border-slate-200">
        <h1 className="text-xl font-bold text-slate-900">Dataset Details</h1>
        <p className="text-sm font-mono text-slate-500 mt-1">Dataset ID: {id}</p>
        <div className="mt-6 text-sm text-slate-500">
          Dataset metadata, contributor audio samples, and terms will appear here.
        </div>
      </div>
    </div>
  );
};
