import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { allUsers, assignRole, getInstitution, updateUser } from '../api/client';

export default function InstitutionDetail() {
  const { id } = useParams();
  const [inst, setInst] = useState(null);
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState('');
  const [selectedUserId, setSelectedUserId] = useState('');
  const [msg, setMsg] = useState('');

  const load = async () => {
    try {
      const [{ data: instData }, { data: all }] = await Promise.all([
        getInstitution(id),
        allUsers(),
      ]);
      setInst(instData);
      setUsers(all);
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  useEffect(() => { load(); }, [id]);

  const currentInstitutionAdmins = users.filter(user =>
    user.institution === Number(id) &&
    user.roles?.some(role => role.name === 'institutional_admin')
  );

  const candidates = users.filter(user => {
    const query = search.toLowerCase().trim();
    if (!query) return true;
    const fullName = `${user.first_name || ''} ${user.last_name || ''}`.toLowerCase();
    return (
      (user.email || '').toLowerCase().includes(query) ||
      (user.username || '').toLowerCase().includes(query) ||
      fullName.includes(query)
    );
  }).filter(user =>
    !user.roles?.some(role => role.name === 'institutional_admin' && user.institution === Number(id))
  );

  const handleAssignAdmin = async () => {
    if (!selectedUserId) return;
    try {
      await assignRole(Number(selectedUserId), 'institutional_admin');
      await updateUser(Number(selectedUserId), { institution_id: Number(id) });
      setMsg('✅ Institution admin assigned successfully.');
      setSelectedUserId('');
      load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Institution: {inst ? inst.name : id}</h2>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      <div style={{ display: 'grid', gap: 20 }}>
        <div className="card" style={{ padding: 20 }}>
          <h3>Assign Institution Admin</h3>
          <p style={{ color: 'var(--text-muted)', marginTop: 8 }}>
            Search by email, username, or full name then assign that user as the institution admin for this institution.
          </p>
          <div style={{ display: 'grid', gap: 12, marginTop: 16 }}>
            <input
              placeholder="Search users by email, username or name"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            <select value={selectedUserId} onChange={e => setSelectedUserId(e.target.value)}>
              <option value="">Select user to assign</option>
              {candidates.map(user => (
                <option key={user.id} value={user.id}>
                  {user.email || user.username} — {user.username} {user.first_name || ''} {user.last_name || ''}
                </option>
              ))}
            </select>
            <button className="btn btn-primary" onClick={handleAssignAdmin} disabled={!selectedUserId}>
              Assign Institution Admin
            </button>
          </div>
        </div>

        <div className="card" style={{ padding: 20 }}>
          <h3>Current Institution Admins</h3>
          <div className="table-wrap" style={{ marginTop: 12 }}>
            <table>
              <thead>
                <tr><th>#</th><th>Email</th><th>Username</th><th>Name</th></tr>
              </thead>
              <tbody>
                {currentInstitutionAdmins.length === 0 ? (
                  <tr><td colSpan={4} style={{ textAlign: 'center', padding: 20 }}>No institution admins assigned.</td></tr>
                ) : currentInstitutionAdmins.map((user, index) => (
                  <tr key={user.id}>
                    <td>{index + 1}</td>
                    <td>{user.email}</td>
                    <td>{user.username}</td>
                    <td>{`${user.first_name || ''} ${user.last_name || ''}`.trim() || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
