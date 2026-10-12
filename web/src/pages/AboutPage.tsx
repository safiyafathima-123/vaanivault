import React from "react";

export const AboutPage: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg border border-slate-200">
        <h1 className="text-xl font-bold text-slate-900">About VaaniVault & Limitations</h1>
        <p className="mt-2 text-sm text-slate-600">
          What the blockchain proves and what it does not, in plain words.
        </p>

        <div className="mt-6 space-y-4 text-sm text-slate-700">
          <div className="p-4 bg-slate-50 rounded border border-slate-200">
            <h2 className="font-semibold text-slate-900">What is guaranteed on-chain</h2>
            <ul className="list-disc list-inside mt-2 space-y-1 text-slate-600">
              <li>Escrowed funds are released only upon council approval or individual owner decision.</li>
              <li>Every non-revoked contributor is credited their exact split directly in the approval transaction.</li>
              <li>Gasless votes and consents are signed using EIP-712 and cannot be forged or altered by relayers.</li>
              <li>Licences are soulbound ERC-721 tokens tied immutably to agreement terms and manifest hashes.</li>
            </ul>
          </div>

          <div className="p-4 bg-slate-50 rounded border border-slate-200">
            <h2 className="font-semibold text-slate-900">Honest limitations</h2>
            <ul className="list-disc list-inside mt-2 space-y-1 text-slate-600">
              <li>No system can stop a licensee from copying files once downloaded. Fingerprinted canaries attribute leaks rather than preventing duplication.</li>
              <li>Phone login verifies control of a phone number and associated wallet, not legal personhood or original copyright authorship.</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};
