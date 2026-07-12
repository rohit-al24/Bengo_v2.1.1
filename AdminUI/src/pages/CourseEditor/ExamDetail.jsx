import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { getAdminExams, getCategories, createCategory, updateCategory, deleteCategory } from '../../api/client';

export default function ExamDetail() {
  const { examId } = useParams();
  const navigate   = useNavigate();
  const [exam,  setExam]  = useState(null);
  const [cats,  setCats]  = useState([]);
  const [modal, setModal] = useState(null);
  const [form,  setForm]  = useState({ title:'', description:'', icon:'', order:0 });
  const [err,   setErr]   = useState('');

  const loadExam = () => getAdminExams().then(r => setExam(r.data.find(e => String(e.id) === examId)));
  const loadCats = () => getCategories(examId).then(r => setCats(r.data));

  useEffect(() => { loadExam(); loadCats(); }, [examId]);

  const openCreate = () => { setForm({ title:'', description:'', icon:'', order:cats.length }); setModal('create'); setErr(''); };
  const openEdit   = c  => { setForm({ title:c.title, description:c.description, icon:c.icon, order:c.order }); setModal(c); setErr(''); };

  const save = async () => {
    try {
      if (modal === 'create') await createCategory({ ...form, exam: examId });
      else                    await updateCategory(modal.id, form);
      setModal(null); loadCats();
    } catch (e) { setErr(JSON.stringify(e.response?.data)); }
  };

  const remove = async id => {
    if (!window.confirm('Delete this category?')) return;
    await deleteCategory(id); loadCats();
  };

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/courses">Course Editor</Link> › <span>{exam?.title || '…'}</span>
      </div>
      <div className="page-header">
        <h2>{exam?.level} — {exam?.title}</h2>
        <button className="btn btn-primary" onClick={openCreate}>+ Add Category</button>
      </div>

      <div className="grid-cards">
        {cats.map(cat => (
          <div key={cat.id} className="card">
            <div style={{ display:'flex', justifyContent:'space-between' }}>
              <span className="badge badge-blue">{cat.lessons_count} lessons</span>
              <div style={{ display:'flex', gap:6 }}>
                <button className="btn btn-icon btn-sm" onClick={() => openEdit(cat)}>✏️</button>
                <button className="btn btn-icon btn-sm" onClick={() => remove(cat.id)}>🗑️</button>
              </div>
            </div>
            <h3 style={{ marginTop:12, fontSize:16, fontWeight:700, cursor:'pointer' }}
                onClick={() => navigate(`/courses/${examId}/categories/${cat.id}`)}>
              {cat.title}
            </h3>
            <p style={{ color:'var(--text-muted)', fontSize:13, marginTop:4 }}>{cat.description}</p>
          </div>
        ))}
        {cats.length === 0 && (
          <p style={{ color:'var(--text-muted)', gridColumn:'1/-1', textAlign:'center', padding:'40px 0' }}>
            No categories yet. Add one to get started.
          </p>
        )}
      </div>

      {modal !== null && (
        <div className="modal-overlay" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{modal === 'create' ? 'Add Category' : 'Edit Category'}</h3>
              <button className="btn btn-icon" onClick={() => setModal(null)}>✕</button>
            </div>
            {err && <div className="alert alert-error">{err}</div>}
            <div className="form-group">
              <label>Title</label>
              <input value={form.title} onChange={e => setForm(f=>({...f,title:e.target.value}))} placeholder="Vocabulary" />
            </div>
            <div className="form-group">
              <label>Description</label>
              <input value={form.description} onChange={e => setForm(f=>({...f,description:e.target.value}))} />
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
