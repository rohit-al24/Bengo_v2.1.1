import React, { useEffect, useState } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { me, getInstitution } from '../api/client';
import './Layout.css';
import '../pages/RolePlay/RolePlay.css';

const NAV = [
  { to: '/',            icon: '⊞',  label: 'Dashboard'     },
  { to: '/daily-revision', icon: '🔁', label: 'Daily Revision' },
  { to: '/announcements', icon: '📢', label: 'Announcements' },
  { to: '/courses',     icon: '📚', label: 'Course Editor' },
  { to: '/ranks',       icon: '🏅', label: 'Ranks'         },
  { to: '/certificates',icon: '🎓', label: 'Certificates'  },
  { to: '/institutions', icon: '🏫', label: 'Institutions'  },
  { to: '/users',       icon: '👥', label: 'Users'         },
];

const RP_SUB_NAV = [
  { to: '/roleplay',           label: 'Dashboard',   end: true },
  { to: '/roleplay/stories',   label: 'Stories',     end: false },
  { to: '/roleplay/import',    label: 'Import Excel',end: false },
  { to: '/roleplay/characters',label: 'Characters',  end: false },
  { to: '/roleplay/analytics', label: 'Analytics',   end: false },
  { to: '/roleplay/settings',  label: 'Settings',    end: false },
];

export default function Layout() {
  const navigate  = useNavigate();
  const location  = useLocation();
  const logout    = () => { localStorage.clear(); navigate('/login'); };

  const [isAdmin,           setIsAdmin]           = useState(false);
  const [isInstitutionAdmin,setIsInstitutionAdmin] = useState(false);
  const [isMentor,          setIsMentor]           = useState(false);
  const [institutionName,   setInstitutionName]    = useState('');
  const [rpOpen,            setRpOpen]             = useState(
    location.pathname.startsWith('/roleplay')
  );

  useEffect(() => {
    me().then(r => {
      const roles = (r.data?.roles || []).map(x => x.name || x);
      setIsAdmin(roles.includes('admin'));
      setIsInstitutionAdmin(roles.includes('institutional_admin'));
      setIsMentor(roles.includes('mentor'));

      if (roles.includes('institutional_admin') && r.data?.institution) {
        getInstitution(r.data.institution).then(inst => {
          setInstitutionName(inst.data?.name || '');
        }).catch(()=>{});
      }
    }).catch(() => {});
  }, []);

  // Auto-expand RolePlay group when navigating to it
  useEffect(() => {
    if (location.pathname.startsWith('/roleplay')) setRpOpen(true);
  }, [location.pathname]);

  // Filter nav items based on role
  const getNavItems = () => {
    if (isAdmin) return NAV;
    if (isInstitutionAdmin) {
      return [
        { to: '/',      icon: '⊞',  label: 'Dashboard' },
        { to: '/users', icon: '👥', label: 'Users'     },
      ];
    }
    if (isMentor) {
      return [{ to: '/', icon: '⊞', label: 'Dashboard' }];
    }
    return [];
  };

  return (
    <div className="layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="brand-logo">BenGo</span>
          <span className="brand-sub">
            {isInstitutionAdmin && institutionName ? institutionName : 'Admin Panel'}
          </span>
        </div>

        <nav className="sidebar-nav">
          {/* Standard nav items */}
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

          {/* RolePlay collapsible group — admin only */}
          {isAdmin && (
            <div className="nav-group">
              <div
                className={`nav-group-header${rpOpen ? ' open' : ''}`}
                onClick={() => setRpOpen(o => !o)}
              >
                <span className="nav-group-header-left">
                  <span className="nav-icon">🎭</span>
                  <span>RolePlay</span>
                </span>
                <span className={`nav-group-chevron${rpOpen ? ' open' : ''}`}>▶</span>
              </div>

              {rpOpen && (
                <div className="nav-sub-items">
                  {RP_SUB_NAV.map(item => (
                    <NavLink
                      key={item.to}
                      to={item.to}
                      end={item.end}
                      className={({ isActive }) =>
                        `nav-sub-item${isActive ? ' active' : ''}`
                      }
                    >
                      <span className="nav-sub-dot" />
                      {item.label}
                    </NavLink>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Institution-admin specific pages */}
          {isInstitutionAdmin && (
            <div style={{ marginTop: 12 }}>
              <div style={{ padding: '8px 12px', color:'var(--text-muted)', fontSize:12 }}>Institution Admin</div>
              <NavLink to="/institution-admin/students" className={({isActive})=>`nav-item ${isActive? 'active':''}`}><span className="nav-icon">👨‍🎓</span><span>Students</span></NavLink>
              <NavLink to="/institution-admin/mentors"  className={({isActive})=>`nav-item ${isActive? 'active':''}`}><span className="nav-icon">🧑‍🏫</span><span>Mentors</span></NavLink>
              <NavLink to="/institution-admin/auth"     className={({isActive})=>`nav-item ${isActive? 'active':''}`}><span className="nav-icon">🔐</span><span>Auth</span></NavLink>
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
