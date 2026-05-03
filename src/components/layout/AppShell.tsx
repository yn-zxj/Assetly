import { NavLink, Outlet, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Package, Pill, Settings, MapPin,
  ChevronRight,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { useSettingsStore } from '../../stores/useSettingsStore';
import { getDb } from '../../services/database';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: '首页' },
  { to: '/items', icon: Package, label: '物品' },
  { to: '/medicine', icon: Pill, label: '药箱' },
  { to: '/locations', icon: MapPin, label: '位置' },
  { to: '/settings', icon: Settings, label: '设置' },
];

const sidebarSubItems = [
  { to: '/categories', label: '分类管理' },
  { to: '/locations', label: '位置管理' },
  { to: '/logs', label: '运行日志' },
];

export default function AppShell() {
  const location = useLocation();
  const [isMobile, setIsMobile] = useState(false);
  const { loadSettings, themeColor } = useSettingsStore();
  const [dbReady, setDbReady] = useState(false);

  // Logs page should highlight Settings nav button
  const isSettingsActive = location.pathname === '/settings' || location.pathname === '/logs';

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768);
    check();
    window.addEventListener('resize', check);
    return () => window.removeEventListener('resize', check);
  }, []);

  useEffect(() => {
    (async () => {
      await getDb(); // Init DB
      await loadSettings();
      setDbReady(true);
    })();
  }, [loadSettings]);

  useEffect(() => {
    document.documentElement.style.setProperty('--color-primary', themeColor);
  }, [themeColor]);

  if (!dbReady) {
    return (
      <div className="flex items-center justify-center h-screen bg-background">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-muted text-sm">正在加载...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      {/* Desktop Sidebar */}
      {!isMobile && (
        <aside className="w-60 bg-surface border-r border-border flex flex-col shrink-0">
          <div className="p-5 border-b border-border">
            <h1 className="text-lg font-bold text-gray-800 flex items-center gap-2">
              <Package className="w-6 h-6 text-primary" />
              Assetly
            </h1>
            <p className="text-xs text-muted mt-1">家庭物品管家</p>
          </div>
          <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
            {navItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === '/'}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2.5 rounded-[12px] text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-primary/10 text-primary'
                      : 'text-gray-600 hover:bg-gray-100'
                  }`
                }
              >
                <item.icon className="w-5 h-5" />
                {item.label}
              </NavLink>
            ))}
            <div className="pt-3 mt-3 border-t border-border">
              <p className="px-3 py-1 text-xs text-muted font-medium">管理</p>
              {sidebarSubItems.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  className={({ isActive }) =>
                    `flex items-center gap-2 px-3 py-2 rounded-[12px] text-sm transition-colors ${
                      isActive
                        ? 'bg-primary/10 text-primary'
                        : 'text-gray-500 hover:bg-gray-100'
                    }`
                  }
                >
                  <ChevronRight className="w-4 h-4" />
                  {item.label}
                </NavLink>
              ))}
            </div>
          </nav>

        </aside>
      )}

      {/* Main Content */}
      <main
        className={`flex-1 overflow-y-auto ${
          isMobile
            ? 'pt-[env(safe-area-inset-top,0px)] pb-[calc(6rem+env(safe-area-inset-bottom,0px))]'
            : ''
        }`}
      >
        <Outlet />
      </main>

      {/* Mobile Bottom Nav - Floating Pill */}
      {isMobile && (
        <div
          className="fixed bottom-0 left-0 right-0 z-50 flex items-end justify-center px-4 pointer-events-none"
          style={{ paddingBottom: `calc(1.25rem + env(safe-area-inset-bottom, 0px))` }}
        >
          <div className="flex items-center gap-2 bg-white/90 backdrop-blur-xl rounded-full px-2 py-2 shadow-lg shadow-black/8 border border-gray-100 pointer-events-auto">
            {navItems.map((item) => {
              const isActive = item.to === '/settings' ? isSettingsActive : location.pathname === item.to;
              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  className={() =>
                    `flex items-center justify-center w-14 h-12 rounded-full transition-all duration-200 ${
                      isActive
                        ? 'bg-primary text-white shadow-md shadow-primary/25'
                        : 'text-gray-400 hover:text-gray-600 hover:bg-gray-100'
                    }`
                  }
                >
                  <item.icon className="w-5 h-5" />
                </NavLink>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
