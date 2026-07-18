import React, { useEffect, useState } from 'react';
import { getAdminExams, allUsers, me, getInstitution } from '../api/client';

export default function Dashboard() {
  const [exams, setExams] = useState([]);
  const [users, setUsers] = useState([]);
  const [institutionName, setInstitutionName] = useState('');
  const user = JSON.parse(localStorage.getItem('user') || '{}');

  useEffect(() => {
    getAdminExams().then(r => setExams(r.data)).catch(()=>{});
    allUsers().then(r => setUsers(r.data)).catch(()=>{});
    
    // Fetch institution name for institutional admin
    me().then(r => {
      if (r.data?.institution && r.data?.roles?.some(role => role.name === 'institutional_admin')) {
        getInstitution(r.data.institution).then(inst => {
          setInstitutionName(inst.data?.name || '');
        }).catch(()=>{});
      }
    }).catch(()=>{});
  }, []);

  const totalLessons = exams.reduce((s,e) =>
    s + (e.categories||[]).reduce((cs,c) => cs + (c.lessons?.length||0), 0), 0);

  return (
    <div>
      <div style={{ marginBottom:28 }}>
        <h2 style={{ fontSize:24, fontWeight:800 }}>👋 Welcome, {user.username || 'Admin'}</h2>
        <p style={{ color:'var(--text-muted)', marginTop:4 }}>
          {institutionName ? `${institutionName} - Admin Dashboard` : 'BenGo Admin Dashboard'}
        </p>
      </div>

      {/* Stats */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="value">{exams.length}</div>
          <div className="label">Total Exams</div>
        </div>
        <div className="stat-card">
          <div className="value">{exams.reduce((s,e)=>s+(e.categories_count||0),0)}</div>
          <div className="label">Total Categories</div>
        </div>
        <div className="stat-card">
          <div className="value">{totalLessons}</div>
          <div className="label">Total Lessons</div>
        </div>
        <div className="stat-card">
          <div className="value">{users.length}</div>
          <div className="label">Registered Users</div>
        </div>
      </div>

      {/* Recent Exams */}
      <div className="card">
        <div className="section-header" style={{ marginBottom:16 }}>
          <h3>📚 Exams Overview</h3>
        </div>
        <div className="table-wrap">
          <table>
            <thead>
              <tr><th>Level</th><th>Title</th><th>Categories</th><th>Status</th></tr>
            </thead>
            <tbody>
              {exams.map(e => (
                <tr key={e.id}>
                  <td><span className="badge badge-blue">{e.level}</span></td>
                  <td style={{ fontWeight:600 }}>{e.title}</td>
                  <td>{e.categories_count}</td>
                  <td><span className={`badge ${e.is_active?'badge-green':'badge-gray'}`}>{e.is_active?'Active':'Draft'}</span></td>
                </tr>
              ))}
              {exams.length === 0 && (
                <tr><td colSpan={4} style={{ textAlign:'center', color:'var(--text-muted)', padding:24 }}>No exams yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
