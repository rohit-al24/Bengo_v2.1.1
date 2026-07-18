import React, { useEffect, useState } from 'react';
import { me, getInstitutionStudents, register, updateUser, deleteUser, resetUserPassword } from '../../api/client';

function downloadCSV(rows, filename = 'students-template.csv'){
  const csv = rows.map(r => r.join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = filename; a.click(); URL.revokeObjectURL(url);
}

export default function Students(){
  const [user, setUser] = useState(null);
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState('');

  const load = async () => {
    setLoading(true);
    try{
      const { data: u } = await me();
      setUser(u);
      if (u.institution_id) {
        const { data } = await getInstitutionStudents(u.institution_id);
        setStudents(data);
      }
    }catch(e){ setMsg(String(e)); }
    setLoading(false);
  };

  useEffect(()=>{ load(); }, []);

  const handleDownloadTemplate = () => {
    // columns: registration_number, username, name, password
    downloadCSV([['registration_number','username','name','password']]);
  };

  const handleImport = async (file) => {
    if (!file) return;
    const txt = await file.text();
    const rows = txt.split('\n').map(r=>r.split(','));
    const header = rows.shift();
    // naive parsing
    const created = [];
    for (const r of rows) {
      if (r.length < 4) continue;
      const payload = {
        email: (r[1] || '').trim() || `${Math.random().toString(36).substr(2,6)}@example.local`,
        username: (r[1]||r[2]||'').trim() || `user_${Math.random().toString(36).substr(2,6)}`,
        name: (r[2]||'').trim(),
        password: (r[3]||Math.random().toString(36).substr(2,8)).trim(),
        institution: user?.institution_id,
        institutional_registration_number: (r[0]||'').trim(),
      };
      try{
        await register(payload);
        created.push(payload.username);
      }catch(e){ console.error(e); }
    }
    setMsg(`Imported ${created.length} users`);
    load();
  };

  const handleEdit = async (s) => {
    const username = prompt('Username', s.username) || s.username;
    const first_name = prompt('First name', s.first_name || '') || s.first_name;
    const last_name = prompt('Last name', s.last_name || '') || s.last_name;
    try{
      await updateUser(s.id, { username, first_name, last_name });
      setMsg('✅ Updated'); load();
    }catch(e){ setMsg('❌ ' + JSON.stringify(e.response?.data || e.message)); }
  };

  const handleRemove = async (s) => {
    if (!confirm(`Delete user ${s.username || s.email}? This cannot be undone.`)) return;
    try{
      await deleteUser(s.id);
      setMsg('✅ Deleted'); load();
    }catch(e){ setMsg('❌ ' + JSON.stringify(e.response?.data || e.message)); }
  };

  const handleReset = async (s) => {
    const useCustom = confirm('Do you want to set a custom password? Cancel to auto-generate.');
    let payload = {};
    if (useCustom) {
      const pwd = prompt('New password');
      if (!pwd) return;
      payload = { password: pwd };
    }
    try{
      const { data } = await resetUserPassword(s.id, payload);
      setMsg('✅ Password reset' + (data.password ? ` — new: ${data.password}` : ''));
      load();
    }catch(e){ setMsg('❌ ' + JSON.stringify(e.response?.data || e.message)); }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Students</h2>
        <div style={{ display:'flex', gap:8 }}>
          <button className="btn" onClick={handleDownloadTemplate}>Download Template</button>
          <label className="btn"><input type="file" style={{ display:'none' }} onChange={e=>handleImport(e.target.files?.[0])} /> Import</label>
        </div>
      </div>

      {msg && <div className={`alert ${msg.startsWith('Imported') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      <div className="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Username</th><th>Email</th><th>Reg#</th><th>Actions</th></tr></thead>
          <tbody>
            {loading && <tr><td colSpan={5} style={{textAlign:'center'}}>Loading…</td></tr>}
            {!loading && students.map((s,i)=> (
              <tr key={s.id}>
                <td>{i+1}</td>
                <td>{s.username}</td>
                <td>{s.email}</td>
                <td>{s.institutional_registration_number||'-'}</td>
                <td style={{ display:'flex', gap:6 }}>
                  <button className="btn btn-secondary btn-sm" onClick={()=>handleEdit(s)}>Edit</button>
                  <button className="btn btn-warning btn-sm" onClick={()=>handleReset(s)}>Reset</button>
                  <button className="btn btn-danger btn-sm" onClick={()=>handleRemove(s)}>Remove</button>
                </td>
              </tr>
            ))}
            {!loading && students.length===0 && <tr><td colSpan={5} style={{textAlign:'center'}}>No students.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
