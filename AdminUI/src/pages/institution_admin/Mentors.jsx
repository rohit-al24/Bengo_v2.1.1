import React, { useEffect, useState } from 'react';
import { me, getInstitutionMentors, register, updateUser, deleteUser, resetUserPassword } from '../../api/client';
import * as XLSX from 'xlsx';

function downloadCSV(rows, filename = 'mentors-template.csv'){
  const csv = rows.map(r => r.join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href = url; a.download = filename; a.click(); URL.revokeObjectURL(url);
}

export default function Mentors(){
  const [user, setUser] = useState(null);
  const [mentors, setMentors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [formData, setFormData] = useState({ username: '', email: '', first_name: '', last_name: '', password: '' });

  const load = async () => {
    setLoading(true);
    try{
      const { data: u } = await me();
      setUser(u);
      if (u.institution_id) {
        const { data } = await getInstitutionMentors(u.institution_id);
        setMentors(Array.isArray(data) ? data : []);
      }
    }catch(e){ setMsg('❌ Failed to load mentors'); }
    setLoading(false);
  };

  useEffect(()=>{ load(); }, []);

  const handleDownloadTemplate = () => {
    downloadCSV([['username','email','first_name','last_name','password']]);
  };

  const handleImport = async (file) => {
    if (!file) return;
    try {
      const buffer = await file.arrayBuffer();
      const workbook = XLSX.read(buffer, { type: 'array' });
      const worksheet = workbook.Sheets[workbook.SheetNames[0]];
      const rows = XLSX.utils.sheet_to_json(worksheet);
      
      let created = 0;
      for (const row of rows) {
        const payload = {
          email: (row.email || row.Email || '').trim() || `${Math.random().toString(36).substr(2,6)}@example.local`,
          username: (row.username || row.Username || row.name || row.Name || '').trim() || `mentor_${Math.random().toString(36).substr(2,6)}`,
          first_name: (row.first_name || row.First_Name || '').trim() || '',
          last_name: (row.last_name || row.Last_Name || '').trim() || '',
          password: (row.password || row.Password || Math.random().toString(36).substr(2,8)).trim(),
          password2: (row.password || row.Password || Math.random().toString(36).substr(2,8)).trim(),
          institution_id: user?.institution_id,
          skip_email_verification: true,
        };
        try{
          await register(payload);
          created++;
        }catch(e){ console.error(e); }
      }
      setMsg(`✅ Imported ${created} mentors`);
      load();
    } catch (e) {
      setMsg('❌ Import failed: ' + e.message);
    }
  };

  const handleAddMentor = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...formData,
        institution_id: user?.institution_id,
        password2: formData.password,
        skip_email_verification: true,
      };
      await register(payload);
      setMsg('✅ Mentor added');
      setFormData({ username: '', email: '', first_name: '', last_name: '', password: '' });
      setShowAddForm(false);
      load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  const handleEdit = async (m) => {
    const username = prompt('Username', m.username) || m.username;
    const first_name = prompt('First name', m.first_name || '') || m.first_name;
    const last_name = prompt('Last name', m.last_name || '') || m.last_name;
    try{
      await updateUser(m.id, { username, first_name, last_name });
      setMsg('✅ Updated'); load();
    }catch(e){ setMsg('❌ ' + JSON.stringify(e.response?.data || e.message)); }
  };

  const handleRemove = async (m) => {
    if (!confirm(`Delete mentor ${m.username || m.email}? This cannot be undone.`)) return;
    try{
      await deleteUser(m.id);
      setMsg('✅ Deleted'); load();
    }catch(e){ setMsg('❌ ' + JSON.stringify(e.response?.data || e.message)); }
  };

  const handleReset = async (m) => {
    const useCustom = confirm('Do you want to set a custom password? Cancel to auto-generate.');
    let payload = {};
    if (useCustom) {
      const pwd = prompt('New password');
      if (!pwd) return;
      payload = { password: pwd };
    }
    try{
      const { data } = await resetUserPassword(m.id, payload);
      setMsg('✅ Password reset' + (data.password ? ` — new: ${data.password}` : ''));
      load();
    }catch(e){ setMsg('❌ ' + JSON.stringify(e.response?.data || e.message)); }
  };

  return (
    <div>
      <div className="page-header">
        <h2>Mentors</h2>
        <div style={{ display:'flex', gap:8 }}>
          <button className="btn btn-primary" onClick={()=>setShowAddForm(true)}>+ Add Mentor</button>
          <button className="btn" onClick={handleDownloadTemplate}>Download Template</button>
          <label className="btn"><input type="file" accept=".csv,.xlsx,.xls" style={{ display:'none' }} onChange={e=>handleImport(e.target.files?.[0])} /> Import Excel</label>
        </div>
      </div>

      {msg && <div className={`alert ${msg.includes('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      {showAddForm && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card" style={{ padding: 24, maxWidth: 400, width: '90%' }}>
            <h3>Add Mentor</h3>
            <form onSubmit={handleAddMentor} style={{ marginTop: 16, display: 'grid', gap: 12 }}>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 12, fontWeight: 600 }}>Email*</label>
                <input type="email" required value={formData.email} onChange={e=>setFormData({...formData, email:e.target.value})} style={{ width: '100%', padding: 8, border: '1px solid #ccc', borderRadius: 4 }} />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 12, fontWeight: 600 }}>Username*</label>
                <input type="text" required value={formData.username} onChange={e=>setFormData({...formData, username:e.target.value})} style={{ width: '100%', padding: 8, border: '1px solid #ccc', borderRadius: 4 }} />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 12, fontWeight: 600 }}>First Name</label>
                <input type="text" value={formData.first_name} onChange={e=>setFormData({...formData, first_name:e.target.value})} style={{ width: '100%', padding: 8, border: '1px solid #ccc', borderRadius: 4 }} />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 12, fontWeight: 600 }}>Last Name</label>
                <input type="text" value={formData.last_name} onChange={e=>setFormData({...formData, last_name:e.target.value})} style={{ width: '100%', padding: 8, border: '1px solid #ccc', borderRadius: 4 }} />
              </div>
              <div>
                <label style={{ display: 'block', marginBottom: 4, fontSize: 12, fontWeight: 600 }}>Password*</label>
                <input type="password" required value={formData.password} onChange={e=>setFormData({...formData, password:e.target.value})} style={{ width: '100%', padding: 8, border: '1px solid #ccc', borderRadius: 4 }} />
              </div>
              <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>Add</button>
                <button type="button" className="btn btn-secondary" style={{ flex: 1 }} onClick={()=>setShowAddForm(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Username</th><th>Email</th><th>Actions</th></tr></thead>
          <tbody>
            {loading && <tr><td colSpan={4} style={{textAlign:'center'}}>Loading…</td></tr>}
            {!loading && mentors.map((s,i)=> (
              <tr key={s.id}>
                <td>{i+1}</td>
                <td>{s.username}</td>
                <td>{s.email}</td>
                <td style={{ display:'flex', gap:6 }}>
                  <button className="btn btn-secondary btn-sm" onClick={()=>handleEdit(s)}>Edit</button>
                  <button className="btn btn-warning btn-sm" onClick={()=>handleReset(s)}>Reset</button>
                  <button className="btn btn-danger btn-sm" onClick={()=>handleRemove(s)}>Remove</button>
                </td>
              </tr>
            ))}
            {!loading && mentors.length===0 && <tr><td colSpan={4} style={{textAlign:'center'}}>No mentors.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
