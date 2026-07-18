import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { getInstitutions, createInstitution } from '../api/client';

export default function Institutions() {
  const [q, setQ] = useState('');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState('');
  const navigate = useNavigate();

  const load = () => {
    setLoading(true);
    getInstitutions().then(r => setItems(r.data)).catch(e => setMsg(String(e))).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleCreate = async () => {
    const code = prompt('Institution code (short)');
    if (!code) return;
    const name = prompt('Institution name');
    if (!name) return;
    try {
      await createInstitution({ code, name });
      setMsg('✅ Institution created');
      load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  const filtered = q ? items.filter(i => (i.name || '').toLowerCase().includes(q.toLowerCase()) || (i.code||'').toLowerCase().includes(q.toLowerCase())) : items;

  return (
    <div>
      <div className="page-header">
        <h2>🏫 Institutions</h2>
        <div style={{ display:'flex', gap:8 }}>
          <input placeholder="Search institutions" value={q} onChange={e => setQ(e.target.value)} />
          <button className="btn" onClick={handleCreate}>＋ Add Institution</button>
        </div>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      <div className="table-wrap">
        <table>
          <thead>
            <tr><th>#</th><th>Code</th><th>Name</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {loading && <tr><td colSpan={4} style={{ textAlign:'center', padding:32, color:'var(--text-muted)' }}>Loading…</td></tr>}
            {!loading && filtered.map((it,i) => (
              <tr key={it.id}>
                <td>{i+1}</td>
                <td style={{ fontWeight:600 }}>{it.code}</td>
                <td>{it.name}</td>
                <td>
                  <button className="btn btn-secondary btn-sm" onClick={() => navigate(`/institutions/${it.id}`)}>Manage</button>
                </td>
              </tr>
            ))}
            {!loading && filtered.length === 0 && <tr><td colSpan={4} style={{ textAlign:'center', padding:32, color:'var(--text-muted)' }}>No institutions.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
