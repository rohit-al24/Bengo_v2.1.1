import React, { useEffect, useState } from 'react';
import { me, getInstitutionMentors, register } from '../../api/client';

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

  const load = async () => {
    setLoading(true);
    try{
      const { data: u } = await me();
      setUser(u);
      if (u.institution_id) {
        const { data } = await getInstitutionMentors(u.institution_id);
        setMentors(data);
      }
    }catch(e){ setMsg(String(e)); }
    setLoading(false);
  };

  useEffect(()=>{ load(); }, []);

  const handleDownloadTemplate = () => {
    // columns: id, name, password
    downloadCSV([['id','name','password']]);
  };

  const handleImport = async (file) => {
    if (!file) return;
    const txt = await file.text();
    const rows = txt.split('\n').map(r=>r.split(','));
    rows.shift();
    let created = 0;
    for (const r of rows) {
      if (r.length < 2) continue;
      const payload = {
        email: `${Math.random().toString(36).substr(2,6)}@example.local`,
        username: (r[1]||`mentor_${Math.random().toString(36).substr(2,6)}`).trim(),
        name: (r[1]||'').trim(),
        password: (r[2]||Math.random().toString(36).substr(2,8)).trim(),
        institution: user?.institution_id,
      };
      try{ await register(payload); created++; }catch(e){ console.error(e); }
    }
    setMsg(`Imported ${created} mentors`);
    load();
  };

  return (
    <div>
      <div className="page-header">
        <h2>Mentors</h2>
        <div style={{ display:'flex', gap:8 }}>
          <button className="btn" onClick={handleDownloadTemplate}>Download Template</button>
          <label className="btn"><input type="file" style={{ display:'none' }} onChange={e=>handleImport(e.target.files?.[0])} /> Import</label>
        </div>
      </div>

      {msg && <div className={`alert ${msg.startsWith('Imported') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      <div className="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Username</th><th>Email</th><th>Actions</th></tr></thead>
          <tbody>
            {loading && <tr><td colSpan={4} style={{textAlign:'center'}}>Loading…</td></tr>}
            {!loading && mentors.map((s,i)=> (
              <tr key={s.id}><td>{i+1}</td><td>{s.username}</td><td>{s.email}</td><td><button className="btn btn-secondary btn-sm">Edit</button></td></tr>
            ))}
            {!loading && mentors.length===0 && <tr><td colSpan={4} style={{textAlign:'center'}}>No mentors.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
