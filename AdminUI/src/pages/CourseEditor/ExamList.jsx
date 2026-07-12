import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getAdminExams, createExam, updateExam, deleteExam } from '../../api/client';

export default function ExamList() {
  const [exams, setExams]   = useState([]);
  const [modal, setModal]   = useState(null); // null | 'create' | exam obj
  const [form,  setForm]    = useState({ title:'', description:'', level:'N5', is_active:true });
  const [err,   setErr]     = useState('');
  const navigate = useNavigate();

  const load = () => getAdminExams().then(r => setExams(r.data));
  useEffect(() => { load(); }, []);

  const openCreate = () => { setForm({ title:'', description:'', level:'N5', is_active:true }); setModal('create'); setErr(''); };
  const openEdit   = e  => { setForm({ title:e.title, description:e.description, level:e.level, is_active:e.is_active }); setModal(e); setErr(''); };

  const save = async () => {
    try {
      if (modal === 'create') await createExam(form);
      else                    await updateExam(modal.id, form);
      setModal(null); load();
    } catch (e) { setErr(JSON.stringify(e.response?.data)); }
  };

  const remove = async id => {
    if (!window.confirm('Delete this exam?')) return;
    await deleteExam(id); load();
  };

  return (
    <div>
      <div className="page-header">
        <h2>📚 Course Editor — Exams</h2>
        <button className="btn btn-primary" onClick={openCreate}>+ New Exam</button>
      </div>

      <div className="grid-cards">
        {exams.map(ex => (
          <div key={ex.id} className="card" style={{ cursor:'pointer' }}
           onClick={() => navigate(`/courses/${ex.id}`)}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
              <div>
                <span className={`badge ${ex.is_active ? 'badge-green' : 'badge-gray'}`}>
                  {ex.is_active ? 'Active' : 'Draft'}
                </span>
                <span className="badge badge-blue" style={{ marginLeft:6 }}>{ex.level}</span>
              </div>
              <div style={{ display:'flex', gap:6 }}>
                <button className="btn btn-icon btn-sm" onClick={e => { e.stopPropagation(); openEdit(ex); }} title="Edit">✏️</button>
                <button className="btn btn-icon btn-sm" onClick={e => { e.stopPropagation(); remove(ex.id); }} title="Delete">🗑️</button>
              </div>
            </div>
            <h3 style={{ marginTop:12, fontSize:17, fontWeight:700, cursor:'pointer' }}
                onClick={() => navigate(`/courses/${ex.id}`)}>
              {ex.title}
            </h3>
            <p style={{ color:'var(--text-muted)', fontSize:13, marginTop:4 }}>{ex.description}</p>
            <div style={{ marginTop:12, display:'flex', gap:16, fontSize:12, color:'var(--text-muted)' }}>
              <span>📂 {ex.categories_count} categories</span>
              <span style={{ color:'var(--primary)', fontWeight:600 }}>→ click to manage</span>
            </div>
          </div>
        ))}
        {exams.length === 0 && (
          <p style={{ color:'var(--text-muted)', gridColumn:'1/-1', textAlign:'center', padding:'40px 0' }}>
            No exams yet. Create your first exam.
          </p>
        )}
      </div>

      {/* Modal */}
      {modal !== null && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{modal === 'create' ? 'Create Exam' : 'Edit Exam'}</h3>
              <button className="btn btn-icon" onClick={() => setModal(null)}>✕</button>
            </div>
            {err && <div className="alert alert-error">{err}</div>}
            <div className="form-group">
              <label>Title</label>
              <input value={form.title} onChange={e => setForm(f=>({...f,title:e.target.value}))} placeholder="JLPT N5 Proficiency" />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Level</label>
                <select value={form.level} onChange={e => setForm(f=>({...f,level:e.target.value}))}>
                  {['N5','N4','N3','N2','N1'].map(l => <option key={l}>{l}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>Status</label>
                <select value={form.is_active} onChange={e => setForm(f=>({...f,is_active:e.target.value==='true'}))}>
                  <option value="true">Active</option>
                  <option value="false">Draft</option>
                </select>
              </div>
            </div>
            <div className="form-group">
              <label>Description</label>
              <textarea rows={3} value={form.description} onChange={e => setForm(f=>({...f,description:e.target.value}))} />
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setModal(null)}>Cancel</button>
              <button className="btn btn-primary" onClick={save}>Save</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
