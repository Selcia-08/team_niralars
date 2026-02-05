import { LayoutDashboard, BarChart3, FileText, FileSpreadsheet, Users, LogOut, Leaf, Package, ClipboardList, Navigation } from 'lucide-react';
import { cn } from '../lib/utils';
import { NavLink } from 'react-router-dom';

const navItems = [
  { icon: LayoutDashboard, label: 'Dashboard', to: '/' },
  { icon: FileSpreadsheet, label: 'Absorption Requests', to: '/absorption-requests' },
  { icon: Package, label: 'Packages', to: '/packages' },
  { icon: ClipboardList, label: 'Assign Tasks', to: '/assign-tasks' },
  { icon: Navigation, label: 'Allocate Routes', to: '/allocate-routes' },
  { icon: BarChart3, label: 'Analytics', to: '/analytics' },
  { icon: FileText, label: 'E-Way Bill', to: '/eway-bill' },
  { icon: Users, label: 'Drivers', to: '/drivers' },
  { icon: Leaf, label: 'Carbon Tracking', to: '/carbon-tracking' },
];

export function Sidebar() {
  return (
    <div className="h-screen w-[240px] bg-eco-dark border-r border-eco-card-border flex flex-col fixed left-0 top-0 z-50">
      {/* Logo */}
      <div className="p-6 flex items-center space-x-3">
        <div className="bg-white/5 p-2 rounded-full border border-eco-brand-orange/20">
            <Leaf className="w-5 h-5 text-eco-brand-orange" />
        </div>
        <span className="text-xl font-bold text-white tracking-wide">
          EcoLogiq
        </span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) => cn(
              "w-full flex items-center space-x-3 px-4 py-3 rounded-lg transition-all duration-200 group text-sm font-medium",
              isActive 
                ? "bg-eco-brand-orange text-white shadow-lg shadow-eco-brand-orange/20" 
                : "text-eco-text-secondary hover:bg-eco-secondary hover:text-white"
            )}
          >
            <item.icon className={cn("w-5 h-5 transition-colors", 
                "group-[.active]:text-white"
            )} />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      {/* User Profile & Logout */}
      <div className="p-4 border-t border-eco-card-border mt-auto">
        <NavLink to="/admin" className="flex items-center space-x-3 mb-4 px-2 hover:bg-eco-secondary/50 p-2 rounded-lg transition-colors group">
            <div className="w-10 h-10 rounded-full bg-eco-brand-orange flex items-center justify-center text-white font-bold group-hover:shadow-neon-orange transition-all">
                A
            </div>
            <div>
                <div className="text-sm font-medium text-white group-hover:text-eco-brand-orange transition-colors">Admin User</div>
                <div className="text-xs text-eco-text-secondary">System Admin</div>
            </div>
        </NavLink>
        <button className="flex items-center space-x-3 text-eco-text-secondary hover:text-white transition-colors px-2 py-2 w-full hover:bg-eco-secondary rounded-lg">
            <LogOut className="w-5 h-5" />
            <span className="text-sm font-medium">Logout</span>
        </button>
      </div>
    </div>
  );
}
