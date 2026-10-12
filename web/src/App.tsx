import React from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { config } from "./lib/wagmi";

import { Layout } from "./components/Layout";
import { HomePage } from "./pages/HomePage";
import { MarketplacePage } from "./pages/MarketplacePage";
import { DatasetDetailPage } from "./pages/DatasetDetailPage";
import { RequestPage } from "./pages/RequestPage";
import { VotePage } from "./pages/VotePage";
import { ReceiptPage } from "./pages/ReceiptPage";
import { CommunityPage } from "./pages/CommunityPage";
import { EarningsPage } from "./pages/EarningsPage";
import { VerifyPage } from "./pages/VerifyPage";
import { TracePage } from "./pages/TracePage";
import { AdminPage } from "./pages/AdminPage";
import { AboutPage } from "./pages/AboutPage";

const queryClient = new QueryClient();

export const App: React.FC = () => {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Layout />}>
              <Route index element={<HomePage />} />
              <Route path="marketplace" element={<MarketplacePage />} />
              <Route path="datasets/:id" element={<DatasetDetailPage />} />
              <Route path="request/:datasetId" element={<RequestPage />} />
              <Route path="vote/:requestId" element={<VotePage />} />
              <Route path="receipt/:requestId" element={<ReceiptPage />} />
              <Route path="community" element={<CommunityPage />} />
              <Route path="earnings" element={<EarningsPage />} />
              <Route path="verify" element={<VerifyPage />} />
              <Route path="trace" element={<TracePage />} />
              <Route path="admin" element={<AdminPage />} />
              <Route path="about" element={<AboutPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </QueryClientProvider>
    </WagmiProvider>
  );
};

export default App;
