import React from "react";
import { NavLink, Outlet } from "react-router-dom";
import { NetworkPill } from "./NetworkPill";
import { ConnectButton } from "./ConnectButton";

const navItems = [
  { path: "/marketplace", label: "Marketplace" },
  { path: "/community", label: "Community" },
  { path: "/earnings", label: "My Earnings" },
  { path: "/verify", label: "Verify" },
  { path: "/trace", label: "Leak Trace" },
  { path: "/admin", label: "Admin" },
  { path: "/about", label: "About" },
];

const mobileNavItems = [
  { path: "/marketplace", label: "Market" },
  { path: "/community", label: "Community" },
  { path: "/earnings", label: "Earnings" },
  { path: "/verify", label: "Verify" },
  { path: "/about", label: "About" },
];

export const Layout: React.FC = () => {
  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-slate-50 text-slate-900">
      {/* Desktop Sidebar */}
      <aside className="hidden md:flex flex-col w-64 border-r border-slate-200 bg-white min-h-screen shrink-0">
        <div className="p-5 border-b border-slate-100">
          <NavLink to="/" className="flex items-center gap-2">
            <span className="text-xl font-bold tracking-tight text-slate-900">VaaniVault</span>
            <span className="text-xs px-2 py-0.5 rounded bg-slate-100 text-slate-600 font-medium">Monad</span>
          </NavLink>
          <p className="text-xs text-slate-500 mt-1">Community data licensing</p>
        </div>

        <nav className="flex-1 p-3 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `block px-3 py-2 text-sm font-medium rounded ${
                  isActive
                    ? "bg-slate-900 text-white"
                    : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-slate-100 text-xs text-slate-400">
          Monad Metropolis · Chain 10143
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-h-screen pb-16 md:pb-0">
        {/* Top Header */}
        <header className="h-16 border-b border-slate-200 bg-white px-4 md:px-8 flex items-center justify-between sticky top-0 z-10">
          <div className="md:hidden flex items-center gap-2">
            <NavLink to="/" className="text-lg font-bold tracking-tight text-slate-900">
              VaaniVault
            </NavLink>
          </div>

          <div className="hidden md:block">
            <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">
              AI Training Data Governance
            </span>
          </div>

          <div className="flex items-center gap-3">
            <NetworkPill />
            <ConnectButton />
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 p-4 md:p-8 max-w-6xl w-full mx-auto">
          <Outlet />
        </main>
      </div>

      {/* Mobile Bottom Tabs */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-white border-t border-slate-200 flex items-center justify-around z-20">
        {mobileNavItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `flex flex-col items-center justify-center flex-1 h-full py-1 text-xs font-medium ${
                isActive ? "text-slate-900 font-semibold" : "text-slate-500"
              }`
            }
          >
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>
    </div>
  );
};
