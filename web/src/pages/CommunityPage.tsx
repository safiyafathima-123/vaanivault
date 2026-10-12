import React from "react";

export const CommunityPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Community Setup</h1>
          <p className="text-sm text-slate-500">
            Manage contributors, invite council members, hash clips, and register datasets.
          </p>
        </div>
      </div>
      <div className="bg-white p-8 rounded-lg border border-slate-200 text-center text-slate-500">
        <p className="text-sm">Community onboarding and clip management will appear here.</p>
      </div>
    </div>
  );
};
