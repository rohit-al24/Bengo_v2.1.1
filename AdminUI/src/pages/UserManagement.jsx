import React, { useEffect, useState } from 'react';
import { me, allUsers, assignRole } from '../api/client';

export default function UserManagement() {
  const [allUsersList, setAllUsers] = useState([]);
  const [isInstitutionAdmin, setIsInstitutionAdmin] = useState(false);
  const [institutionId, setInstitutionId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [modal,   setModal]   = useState(null);
  const [role,    setRole]    = useState('admin');
  const [msg,     setMsg]     = useState('');

  const load = () => {
    setLoading(true);
    me().then(r => {
      const roles = (r.data?.roles || []).map(x => x.name || x);
      setIsInstitutionAdmin(roles.includes('institutional_admin'));
      setInstitutionId(r.data?.institution_id);
    }).catch(()=>{});
    
    allUsers().then(r => setAllUsers(r.data)).finally(() => setLoading(false));
  };
  
  const getDisplayUsers = () => {
    let display = allUsersList;
    if (isInstitutionAdmin && institutionId) {
      display = display.filter(u => u.institution_id === institutionId);
    }
    return display.filter(u => {
      const hasRelevantRole = u.roles?.some(r => 
        r.name === 'user' || r.name === 'mentor' || r.name === 'institutional_admin'
      );
      return hasRelevantRole;
    });
  };
  
  const users = getDisplayUsers();
  
  useEffect(() => { load(); }, []);

  const assign = async () => {
    try {
      await assignRole(modal.id, role);
      setMsg(`✅ Role "${role}" assigned to ${modal.username}.`);
      setModal(null); load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data));
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>👥 User Management</h2>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Email</th>
              <th>Username</th>
              <th>Roles</th>
              <th>XP</th>
              <th>Streak</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan={8} style={{ textAlign:'center', padding:32, color:'var(--text-muted)' }}>Loading…</td></tr>
            )}
            {!loading && users.map((u, i) => (
              <tr key={u.id}>
                <td>{i + 1}</td>
                <td style={{ fontWeight: 600 }}>{u.email}</td>
                <td>{u.username}</td>
                <td>
                  {u.roles?.map(r => (
                    <span key={r.id} className={`badge ${r.name === 'admin' ? 'badge-red' : 'badge-blue'}`}
                          style={{ marginRight: 4 }}>
                      {r.name}
                    </span>
                  ))}
                </td>
                <td>{u.xp} XP</td>
                <td>{u.streak_days}🔥</td>
                <td style={{ fontSize: 12, color:'var(--text-muted)' }}>
                  {new Date(u.date_joined).toLocaleDateString()}
                </td>
                <td>
                  <button className="btn btn-secondary btn-sm" onClick={() => { setModal(u); setMsg(''); }}>
                    Assign Role
                  </button>
                </td>
              </tr>
            ))}
            {!loading && users.length === 0 && (
              <tr><td colSpan={8} style={{ textAlign:'center', padding:32, color:'var(--text-muted)' }}>No users yet.</td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Assign Role Modal */}
      {modal && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Assign Role</h3>
              <button className="btn btn-icon" onClick={() => setModal(null)}>✕</button>
            </div>
            <p style={{ marginBottom:16, color:'var(--text-muted)' }}>
              Assign a role to <strong>{modal.username}</strong> ({modal.email})
            </p>
            <div className="form-group">
              <label>Role</label>
              <select value={role} onChange={e => setRole(e.target.value)}>
                <option value="admin">admin</option>
                <option value="user">user</option>
              </select>
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setModal(null)}>Cancel</button>
              <button className="btn btn-primary" onClick={assign}>Assign</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
