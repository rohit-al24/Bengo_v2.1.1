import React from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import './Layout.css';

const NAV = [
  { to: '/',            icon: '⊞',  label: 'Dashboard'     },
  { to: '/daily-revision', icon: '🔁', label: 'Daily Revision' },
  { to: '/courses',     icon: '📚', label: 'Course Editor' },
  { to: '/ranks',       icon: '🏅', label: 'Ranks'         },
  { to: '/certificates',icon: '🎓', label: 'Certificates'  },
  { to: '/users',       icon: '👥', label: 'Users'         },
];


export default function Layout() {
  const navigate = useNavigate();
  const logout = () => { localStorage.clear(); navigate('/login'); };

  return (
    <div className="layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="brand-logo">BenGo</span>
          <span className="brand-sub">Admin Panel</span>
        </div>
        <nav className="sidebar-nav">
          {NAV.map(n => (
            <NavLink
              key={n.to}
              to={n.to}
              end={n.to === '/'}
              className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            >
              <span className="nav-icon">{n.icon}</span>
              <span>{n.label}</span>
            </NavLink>
          ))}
        </nav>
        <button className="sidebar-logout" onClick={logout}>
          <span>🚪</span> Logout
        </button>
      </aside>

      {/* Main content */}
      <main className="main-content">
        <Outlet />
      </main>
    </div>
  );
}
