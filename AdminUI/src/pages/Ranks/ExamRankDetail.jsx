import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../api/client';


const RANK_COLORS = ['#CD7F32','#C0C0C0','#FFD700','#B9F2FF','#E5E4E2'];
const RANK_ICONS  = ['🥉','🥈','🥇','💎','👑'];

const defaultForm = {
  name: '', rank_type: 'full', category: '', order: 1,
  pass_percentage: 70, color: '#CD7F32', icon: '🥉',
  question_timer_seconds: 30,
  has_overall_timer: false, overall_timer_seconds: 300,
};

const buildCategoryTimerState = (categoryList = []) => Object.fromEntries(
  categoryList.map(category => [category.id, {
    question_timer_seconds: category.question_timer_seconds ?? 30,
    has_overall_timer: category.has_overall_timer ?? false,
    overall_timer_seconds: category.overall_timer_seconds ?? 300,
  }])
);

export default function ExamRankDetail() {
  const { examId } = useParams();
  const navigate = useNavigate();

  const [exam,       setExam]       = useState(null);
  const [ranks,      setRanks]      = useState([]);
  const [categories, setCategories] = useState([]);
  const [showModal,  setShowModal]  = useState(false);
  const [editRank,   setEditRank]   = useState(null); // null = create, obj = edit
  const [form,       setForm]       = useState(defaultForm);
  const [categoryTimerState, setCategoryTimerState] = useState({});
  const [saving,     setSaving]     = useState(false);
  const [msg,        setMsg]        = useState('');

  const load = () => {
    api.get(`/courses/admin/exams/${examId}/`).then(r => setExam(r.data));
    api.get('/ranks/ranks/', { params: { exam: examId } }).then(r => setRanks(r.data));
    api.get('/courses/admin/categories/', { params: { exam: examId } }).then(r => {
      setCategories(r.data);
      setCategoryTimerState(buildCategoryTimerState(r.data));
    });
  };

  useEffect(() => { load(); }, [examId]);

  const openCreate = () => {
    setEditRank(null);
    setCategoryTimerState(buildCategoryTimerState(categories));
    setForm({ ...defaultForm, exam: parseInt(examId), order: ranks.length + 1 });
    setShowModal(true);
  };

  const openEdit = rank => {
    setEditRank(rank);
    setCategoryTimerState(buildCategoryTimerState(categories));
    setForm({
      name: rank.name, rank_type: rank.rank_type,
      category: rank.category || '', order: rank.order,
      pass_percentage: rank.pass_percentage, color: rank.color, icon: rank.icon,
      question_timer_seconds: rank.question_timer_seconds,
      has_overall_timer: rank.has_overall_timer,
      overall_timer_seconds: rank.overall_timer_seconds,
    });
    setShowModal(true);
  };

  const handleSave = async () => {
    setSaving(true); setMsg('');
    try {
      const payload = {
        ...form,
        exam: parseInt(examId),
        category: form.rank_type === 'category' && form.category ? parseInt(form.category) : null,
      };
      let savedRank;
      if (editRank) {
        savedRank = (await api.patch(`/ranks/ranks/${editRank.id}/`, payload)).data;
        setMsg('✅ Rank updated.');
      } else {
        savedRank = (await api.post('/ranks/ranks/', payload)).data;
        setMsg('✅ Rank created.');
      }

      await Promise.all(Object.entries(categoryTimerState).map(([categoryId, values]) =>
        api.patch(`/courses/admin/categories/${categoryId}/`, {
          question_timer_seconds: values.question_timer_seconds,
          has_overall_timer: values.has_overall_timer,
          overall_timer_seconds: values.overall_timer_seconds,
        })
      ));

      setShowModal(false);
      load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this rank?')) return;
    await api.delete(`/ranks/ranks/${id}/`);
    load();
  };

  const f = (key, val) => setForm(p => ({ ...p, [key]: val }));
  const updateCategoryTimer = (categoryId, key, value) => {
    setCategoryTimerState(prev => ({
      ...prev,
      [categoryId]: { ...prev[categoryId], [key]: value },
    }));
  };

  return (
    <div>
      {/* Breadcrumb */}
      <div className="breadcrumb">
        <Link to="/ranks">Ranks</Link> › <span>{exam?.title || '…'}</span>
      </div>

      <div className="page-header">
        <div>
          <h2>🏅 {exam?.title} — Rank Levels</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
            Ranks ordered from lowest (#1) to highest. Users progress through each rank.
          </p>
        </div>
        <button className="btn btn-primary" onClick={openCreate}>+ New Rank</button>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      {/* Ranks List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {ranks.map(rank => (
          <div key={rank.id} className="card" style={{
            display: 'flex', alignItems: 'center', gap: 16,
            borderLeft: `5px solid ${rank.color}`,
          }}>
            {/* Order badge */}
            <div style={{
              width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
              background: rank.color, display: 'flex', alignItems: 'center',
              justifyContent: 'center', fontSize: 22,
            }}>
              {rank.icon}
            </div>

            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontWeight: 700, fontSize: 16 }}>{rank.name}</span>
                <span style={{
                  padding: '2px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600,
                  background: rank.rank_type === 'category' ? '#EEF2FF' : '#F0FDF4',
                  color: rank.rank_type === 'category' ? '#6366F1' : '#16A34A',
                }}>
                  {rank.rank_type === 'category' ? '📂 Category' : '📚 Full Exam'}
                </span>
                <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                  #{rank.order}
                </span>
              </div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4, display: 'flex', gap: 16 }}>
                <span>✅ Pass: <b>{rank.pass_percentage}%</b></span>
                <span>⏱ Q-Timer: <b>{rank.question_timer_seconds}s</b></span>
                {rank.has_overall_timer && (
                  <span>⏰ Overall: <b>{rank.overall_timer_seconds}s</b></span>
                )}
                {rank.category_name && <span>📂 {rank.category_name}</span>}
              </div>
            </div>

            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn btn-sm"
                style={{ background: '#FEF9C3', color: '#92400E', border: '1px solid #FCD34D' }}
                onClick={() => navigate(`/ranks/${examId}/${rank.id}/xp`)}>
                ⚡ XP Config
              </button>
              <button className="btn btn-secondary btn-sm" onClick={() => openEdit(rank)}>
                ✏️ Edit
              </button>
              <button className="btn btn-sm" style={{ background: '#FEE2E2', color: '#DC2626' }}
                onClick={() => handleDelete(rank.id)}>
                🗑
              </button>
            </div>
          </div>
        ))}
        {ranks.length === 0 && (
          <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-muted)' }}>
            No ranks yet. Create the first rank to get started.
          </div>
        )}
      </div>

      {/* Create / Edit Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" style={{ maxWidth: 520 }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editRank ? '✏️ Edit Rank' : '+ Create Rank'}</h3>
              <button className="btn btn-icon" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div style={{ display: 'grid', gap: 14, padding: '4px 0' }}>
              {/* Name + Icon */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 10 }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label>Rank Name *</label>
                  <input className="form-control" value={form.name}
                    onChange={e => f('name', e.target.value)}
                    placeholder="e.g. Bronze, Silver, Gold" />
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label>Icon</label>
                  <input className="form-control" value={form.icon}
                    onChange={e => f('icon', e.target.value)}
                    style={{ width: 60, textAlign: 'center', fontSize: 20 }} />
                </div>
              </div>

              {/* Color swatches */}
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label>Color</label>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 4 }}>
                  {RANK_COLORS.map(c => (
                    <div key={c} onClick={() => f('color', c)} style={{
                      width: 28, height: 28, borderRadius: '50%', background: c, cursor: 'pointer',
                      border: form.color === c ? '3px solid #6366F1' : '2px solid #E5E7EB',
                    }} />
                  ))}
                  <input type="color" value={form.color} onChange={e => f('color', e.target.value)}
                    style={{ width: 28, height: 28, borderRadius: '50%', border: 'none', cursor: 'pointer' }} />
                </div>
              </div>

              {/* Order */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label>Order (1 = lowest)</label>
                  <input className="form-control" type="number" min={1} value={form.order}
                    onChange={e => f('order', parseInt(e.target.value))} />
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label>Pass Percentage (%)</label>
                  <input className="form-control" type="number" min={0} max={100}
                    value={form.pass_percentage}
                    onChange={e => f('pass_percentage', parseInt(e.target.value))} />
                </div>
              </div>

              {/* Rank Type */}
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label>Rank Type</label>
                <select className="form-control" value={form.rank_type}
                  onChange={e => f('rank_type', e.target.value)}>
                  <option value="full">Full Exam — applies to entire exam</option>
                  <option value="category">Category-Wise — applies to one category</option>
                </select>
              </div>

              {form.rank_type === 'category' && (
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label>Category</label>
                  <select className="form-control" value={form.category}
                    onChange={e => f('category', e.target.value)}>
                    <option value="">-- Select Category --</option>
                    {categories.map(c => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>
              )}

              {/* Timers */}
              <div style={{ borderTop: '1px solid var(--border)', paddingTop: 10 }}>
                <div style={{ fontWeight: 600, marginBottom: 10, fontSize: 13 }}>⏱ Timer Settings</div>
                <div className="form-group" style={{ marginBottom: 10 }}>
                  <label>Seconds per Question <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(0 = no limit)</span></label>
                  <input className="form-control" type="number" min={0}
                    value={form.question_timer_seconds}
                    onChange={e => f('question_timer_seconds', parseInt(e.target.value))} />
                </div>

                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', marginBottom: 8 }}>
                  <input type="checkbox" checked={form.has_overall_timer}
                    onChange={e => f('has_overall_timer', e.target.checked)} />
                  <span style={{ fontSize: 13 }}>Enable overall test timer</span>
                </label>

                {form.has_overall_timer && (
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label>Total Test Duration (seconds)</label>
                    <input className="form-control" type="number" min={1}
                      value={form.overall_timer_seconds}
                      onChange={e => f('overall_timer_seconds', parseInt(e.target.value))} />
                  </div>
                )}

                {categories.length > 0 && (
                  <div style={{ marginTop: 12, display: 'grid', gap: 10 }}>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                      These timers will be applied category-by-category during take-tests.
                    </div>
                    {categories.map(category => {
                      const timerValues = categoryTimerState[category.id] || {
                        question_timer_seconds: 30,
                        has_overall_timer: false,
                        overall_timer_seconds: 300,
                      };
                      return (
                        <div key={category.id} style={{ border: '1px solid var(--border)', borderRadius: 8, padding: 10 }}>
                          <div style={{ fontWeight: 600, marginBottom: 8 }}>{category.title}</div>
                          <div className="form-group" style={{ marginBottom: 8 }}>
                            <label>Per-question timer (seconds)</label>
                            <input className="form-control" type="number" min={0}
                              value={timerValues.question_timer_seconds}
                              onChange={e => updateCategoryTimer(category.id, 'question_timer_seconds', parseInt(e.target.value || 0))} />
                          </div>
                          <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', marginBottom: 8 }}>
                            <input type="checkbox" checked={timerValues.has_overall_timer}
                              onChange={e => updateCategoryTimer(category.id, 'has_overall_timer', e.target.checked)} />
                            <span style={{ fontSize: 13 }}>Enable overall timer</span>
                          </label>
                          {timerValues.has_overall_timer && (
                            <div className="form-group" style={{ marginBottom: 0 }}>
                              <label>Total duration (seconds)</label>
                              <input className="form-control" type="number" min={1}
                                value={timerValues.overall_timer_seconds}
                                onChange={e => updateCategoryTimer(category.id, 'overall_timer_seconds', parseInt(e.target.value || 0))} />
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="btn btn-primary" disabled={saving || !form.name}
                onClick={handleSave}>
                {saving ? 'Saving…' : (editRank ? 'Update Rank' : 'Create Rank')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
