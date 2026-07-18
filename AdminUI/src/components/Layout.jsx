import React, { useEffect, useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { me, getInstitution } from '../api/client';
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
  const [isAdmin, setIsAdmin] = useState(false);
  const [isInstitutionAdmin, setIsInstitutionAdmin] = useState(false);
  const [isMentor, setIsMentor] = useState(false);
  const [institutionName, setInstitutionName] = useState('');

  useEffect(() => {
    me().then(r => {
      const roles = (r.data?.roles || []).map(x => x.name || x);
      setIsAdmin(roles.includes('admin'));
      setIsInstitutionAdmin(roles.includes('institutional_admin'));
      setIsMentor(roles.includes('mentor'));
      
      // Fetch institution name for institutional admin
      if (roles.includes('institutional_admin') && r.data?.institution) {
        getInstitution(r.data.institution).then(inst => {
          setInstitutionName(inst.data?.name || '');
        }).catch(()=>{});
      }
    }).catch(() => {});
  }, []);

  // Filter nav items based on role
  const getNavItems = () => {
    if (isAdmin) {
      return NAV; // Admin sees all pages
    }
    if (isInstitutionAdmin) {
      // Institution admin sees dashboard and users only
      return [
        { to: '/',            icon: '⊞',  label: 'Dashboard'     },
        { to: '/users',       icon: '👥', label: 'Users'         },
      ];
    }
    if (isMentor) {
      // Mentor sees only dashboard
      return [
        { to: '/',            icon: '⊞',  label: 'Dashboard'     },
      ];
    }
    return [];
  };

  return (
    <div className="layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="brand-logo">BenGo</span>
          <span className="brand-sub">{isInstitutionAdmin && institutionName ? institutionName : 'Admin Panel'}</span>
        </div>
        <nav className="sidebar-nav">
          {getNavItems().map(n => (
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
