import React, { useEffect, useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { me } from '../api/client';
import './Layout.css';

const NAV = [
  { to: '/',            icon: '⊞',  label: 'Dashboard'     },
  { to: '/daily-revision', icon: '🔁', label: 'Daily Revision' },
  { to: '/courses',     icon: '📚', label: 'Course Editor' },
  { to: '/ranks',       icon: '🏅', label: 'Ranks'         },
  { to: '/certificates',icon: '🎓', label: 'Certificates'  },
  { to: '/institutions', icon: '🏫', label: 'Institutions'  },
  { to: '/users',       icon: '👥', label: 'Users'         },
];


export default function Layout() {
  const navigate = useNavigate();
  const logout = () => { localStorage.clear(); navigate('/login'); };
  const [isInstitutionAdmin, setIsInstitutionAdmin] = useState(false);

  useEffect(() => {
    me().then(r => {
      const roles = (r.data?.roles || []).map(x => x.name || x);
      setIsInstitutionAdmin(roles.includes('institution_admin'));
    }).catch(() => {});
  }, []);

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
          {isInstitutionAdmin && (
            <div style={{ marginTop: 12 }}>
              <div style={{ padding: '8px 12px', color:'var(--text-muted)', fontSize:12 }}>Institution Admin</div>
              <NavLink to="/institution-admin/students" className={({isActive})=>`nav-item ${isActive? 'active':''}`}><span className="nav-icon">👨‍🎓</span><span>Students</span></NavLink>
              <NavLink to="/institution-admin/mentors" className={({isActive})=>`nav-item ${isActive? 'active':''}`}><span className="nav-icon">🧑‍🏫</span><span>Mentors</span></NavLink>
              <NavLink to="/institution-admin/auth" className={({isActive})=>`nav-item ${isActive? 'active':''}`}><span className="nav-icon">🔐</span><span>Auth</span></NavLink>
            </div>
          )}
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
