import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import api, { getLessons, createLesson, updateLesson, deleteLesson } from '../../api/client';

const TYPE_OPTS     = [{ v:'study', l:'📖 Study' }, { v:'exam', l:'📝 Exam' }];
const TEST_SRC_OPTS = [{ v:'from_study', l:'Take From Study' }, { v:'custom_bank', l:'Custom Question Bank' }];
const SHOW_OPTS     = [{ v:'full_row', l:'Full Row Show' }, { v:'topic_wise', l:'Topic Wise Show' }];

const initLessonForm = (order = 0) => ({
  name: '', order, lesson_type: 'study', test_source: 'from_study', rank: '', is_active: true,
});

export default function CategoryDetail() {
  const { examId, catId } = useParams();
  const navigate = useNavigate();

  const [category,    setCategory]    = useState(null);
  const [lessons,     setLessons]     = useState([]);
  const [lessonModal, setLessonModal] = useState(null); // null | 'create' | lesson obj
  const [catModal,    setCatModal]    = useState(false);
  const [form,        setForm]        = useState(initLessonForm());
  const [catShowType, setCatShowType] = useState('full_row');
  const [ranks,       setRanks]       = useState([]);
  const [ranksLoading,setRanksLoading]= useState(false);
  const [err,         setErr]         = useState('');
  const [catSaving,   setCatSaving]   = useState(false);
  const [selectedLessonIds, setSelectedLessonIds] = useState([]);

  const load = async () => {
    const [catRes, lessonRes] = await Promise.all([
      api.get(`/courses/admin/categories/${catId}/`),
      getLessons(catId),
    ]);
    setCategory(catRes.data);
    setCatShowType(catRes.data.show_type || 'full_row');
    setLessons(lessonRes.data);
    setSelectedLessonIds([]);

    if (examId) {
      setRanksLoading(true);
      api.get('/ranks/ranks/', { params: { exam: examId } })
        .then(r => setRanks(r.data || []))
        .catch(() => setRanks([]))
        .finally(() => setRanksLoading(false));
    }
  };
  useEffect(() => { load(); }, [catId]);

  // ── Category settings ──
  const saveCatSettings = async () => {
    setCatSaving(true);
    try {
      await api.patch(`/courses/admin/categories/${catId}/`, { show_type: catShowType });
      await load();
      setCatModal(false);
    } catch (e) { setErr(JSON.stringify(e.response?.data)); }
    finally { setCatSaving(false); }
  };

  // ── Lesson CRUD ──
  const openCreate = () => { setForm(initLessonForm(lessons.length)); setLessonModal('create'); setErr(''); };
  const openEdit   = l => {
    setForm({
      name: l.name,
      order: l.order,
      lesson_type: l.lesson_type,
      test_source: l.test_source,
      rank: l.assigned_rank_id ?? l.rank ?? '',
      is_active: l.is_active,
    });
    setLessonModal(l); setErr('');
  };

  const save = async () => {
    try {
      const payload = {
        ...form,
        category: catId,
        rank: form.rank ? Number(form.rank) : null,
      };
      if (lessonModal === 'create') await createLesson(payload);
      else                          await updateLesson(lessonModal.id, payload);
      setLessonModal(null); load();
    } catch (e) { setErr(JSON.stringify(e.response?.data)); }
  };

  const remove = async id => {
    if (!window.confirm('Delete this lesson?')) return;
    await deleteLesson(id); load();
  };

  const toggleLessonSelection = (id) => {
    setSelectedLessonIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  };

  const toggleSelectAll = () => {
    if (selectedLessonIds.length === lessons.length) {
      setSelectedLessonIds([]);
      return;
    }
    setSelectedLessonIds(lessons.map(l => l.id));
  };

  const bulkDelete = async () => {
    if (selectedLessonIds.length === 0) return;
    if (!window.confirm(`Delete ${selectedLessonIds.length} selected lesson(s)?`)) return;
    await Promise.all(selectedLessonIds.map(id => deleteLesson(id)));
    setSelectedLessonIds([]);
    load();
  };

  const showTypeLabel = category?.show_type === 'topic_wise' ? '📚 Topic Wise' : '📋 Full Row';

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/courses">Course Editor</Link> ›{' '}
        <Link to={`/courses/${examId}`}>Exam</Link> ›{' '}
        <span>{category?.title || 'Category'}</span>
      </div>

      <div className="page-header">
        <div>
          <h2>📋 {category?.title || 'Lessons'}</h2>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 6 }}>
            {/* Show type badge */}
            <span style={{
              padding: '3px 12px', borderRadius: 20, fontSize: 12, fontWeight: 600,
              background: category?.show_type === 'topic_wise' ? '#EEF2FF' : '#F0FDF4',
              color: category?.show_type === 'topic_wise' ? '#6366F1' : '#16A34A',
              border: `1px solid ${category?.show_type === 'topic_wise' ? '#C7D2FE' : '#86EFAC'}`,
            }}>
              {showTypeLabel} Show
            </span>
            <button className="btn btn-sm btn-secondary"
              style={{ fontSize: 12, padding: '3px 12px' }}
              onClick={() => setCatModal(true)}>
              ⚙️ Category Settings
            </button>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {selectedLessonIds.length > 0 && (
            <button className="btn btn-secondary" onClick={bulkDelete}>🗑️ Delete Selected ({selectedLessonIds.length})</button>
          )}
          <button className="btn btn-primary" onClick={openCreate}>+ Add Lesson</button>
        </div>
      </div>

      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th><input type="checkbox" checked={lessons.length > 0 && selectedLessonIds.length === lessons.length} onChange={toggleSelectAll} /></th>
              <th>#</th><th>Name</th><th>Type</th>
              <th>Test Source</th><th>Has Active Bank</th><th>Status</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {lessons.map((l, i) => (
              <tr key={l.id}>
                <td><input type="checkbox" checked={selectedLessonIds.includes(l.id)} onChange={() => toggleLessonSelection(l.id)} /></td>
                <td>{i + 1}</td>
                <td style={{ fontWeight: 600, cursor: 'pointer', color: 'var(--primary)' }}
                  onClick={() => navigate(`/courses/${examId}/categories/${catId}/lessons/${l.id}`)}>
                  {l.name}
                </td>
                <td>
                  <span className={`badge ${l.lesson_type === 'study' ? 'badge-blue' : 'badge-red'}`}>
                    {l.lesson_type === 'study' ? '📖 Study' : '📝 Exam'}
                  </span>
                </td>
                <td><span className="badge badge-gray">{l.test_source}</span></td>
                <td>
                  {l.has_active_bank
                    ? <span className="badge badge-green">✓ Bank</span>
                    : <span className="badge badge-gray">—</span>}
                </td>
                <td>
                  <span className={`badge ${l.is_active ? 'badge-green' : 'badge-gray'}`}>
                    {l.is_active ? 'Active' : 'Draft'}
                  </span>
                </td>
                <td>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button className="btn btn-icon btn-sm" onClick={() => openEdit(l)} title="Settings">⚙️</button>
                    {l.lesson_type === 'study' && (
                      <button className="btn btn-icon btn-sm"
                        onClick={() => navigate(`/courses/${examId}/categories/${catId}/lessons/${l.id}`)}
                        title="Study Content">📝</button>
                    )}
                    {l.test_source === 'custom_bank' && (
                      <button className="btn btn-icon btn-sm"
                        onClick={() => navigate(`/courses/${examId}/categories/${catId}/lessons/${l.id}/banks`)}
                        title="Question Banks">🏦</button>
                    )}
                    <button className="btn btn-icon btn-sm" onClick={() => remove(l.id)} title="Delete">🗑️</button>
                  </div>
                </td>
              </tr>
            ))}
            {lessons.length === 0 && (
              <tr><td colSpan={8} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: 32 }}>
                No lessons yet.
              </td></tr>
            )}
          </tbody>
        </table>
      </div>

      {/* ── Category Settings Modal ── */}
      {catModal && (
        <div className="modal-overlay" onClick={() => setCatModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>⚙️ Category Settings — {category?.title}</h3>
              <button className="btn btn-icon" onClick={() => setCatModal(false)}>✕</button>
            </div>

            <div className="form-group">
              <label>Study Display Mode</label>
              <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 10 }}>
                This applies to all lessons in this category.
              </p>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                {SHOW_OPTS.map(o => (
                  <div key={o.v}
                    onClick={() => setCatShowType(o.v)}
                    style={{
                      padding: 14, borderRadius: 12, cursor: 'pointer', transition: 'all .15s',
                      border: `2px solid ${catShowType === o.v ? 'var(--primary)' : 'var(--border)'}`,
                      background: catShowType === o.v ? '#EEF2FF' : '#FAFAFA',
                    }}>
                    <div style={{ fontWeight: 700, fontSize: 13, color: catShowType === o.v ? 'var(--primary)' : 'inherit' }}>
                      {o.v === 'full_row' ? '📋' : '📚'} {o.l}
                    </div>
                    <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>
                      {o.v === 'full_row'
                        ? 'Shows all vocab rows in a scrollable list. Template: target, correct_answer, wrong_1-4'
                        : 'Shows one word at a time with explanations. Template: target, exp1-exp5'}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {catShowType === 'topic_wise' && (
              <div style={{ background: '#EEF2FF', borderRadius: 10, padding: 12, fontSize: 12, color: '#4338CA' }}>
                📌 Topic Wise mode: Excel import uses columns <b>target, exp1, exp2, exp3, exp4, exp5</b>
                (exp columns are optional). Students navigate word-by-word with Prev/Next buttons.
                No take-test unless a custom question bank is attached.
              </div>
            )}

            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setCatModal(false)}>Cancel</button>
              <button className="btn btn-primary" disabled={catSaving} onClick={saveCatSettings}>
                {catSaving ? 'Saving…' : 'Save Settings'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Lesson Settings Modal ── */}
      {lessonModal !== null && (
        <div className="modal-overlay" onClick={() => setLessonModal(null)}>
          <div className="modal" style={{ width: 'min(520px,95vw)' }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>⚙️ {lessonModal === 'create' ? 'Add Lesson' : 'Lesson Settings'}</h3>
              <button className="btn btn-icon" onClick={() => setLessonModal(null)}>✕</button>
            </div>
            {err && <div className="alert alert-error">{err}</div>}

            <div className="form-group">
              <label>Lesson Name *</label>
              <input className="form-control" value={form.name}
                onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                placeholder="e.g. Lesson 1, Verb Basics" />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Lesson Type</label>
                <select className="form-control" value={form.lesson_type}
                  onChange={e => setForm(f => ({ ...f, lesson_type: e.target.value }))}>
                  {TYPE_OPTS.map(o => <option key={o.v} value={o.v}>{o.l}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>Status</label>
                <select className="form-control" value={form.is_active}
                  onChange={e => setForm(f => ({ ...f, is_active: e.target.value === 'true' }))}>
                  <option value="true">Active</option>
                  <option value="false">Draft</option>
                </select>
              </div>
            </div>

            {/* Test source only for study lessons */}
            {form.lesson_type === 'study' && (
              <div className="form-group">
                <label>Take Test — Source</label>
                <select className="form-control" value={form.test_source}
                  onChange={e => setForm(f => ({ ...f, test_source: e.target.value }))}>
                  {TEST_SRC_OPTS.map(o => <option key={o.v} value={o.v}>{o.l}</option>)}
                </select>
              </div>
            )}

            <div className="form-group">
              <label>Visible for Rank</label>
              <select className="form-control" value={form.rank || ''}
                onChange={e => setForm(f => ({ ...f, rank: e.target.value }))}>
                <option value="">Show for all ranks</option>
                {!ranksLoading && ranks.map(r => (
                  <option key={r.id} value={r.id}>{r.name}</option>
                ))}
              </select>
              <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 6 }}>
                {ranksLoading
                  ? 'Loading ranks…'
                  : ranks.length === 0
                    ? 'No ranks configured for this exam yet.'
                    : 'Only users on the selected rank will see this lesson on the path page.'}
              </div>
            </div>

            {/* Info banners */}
            {form.lesson_type === 'exam' && (
              <div style={{ background: '#FEF3C7', borderRadius: 10, padding: 12, fontSize: 12, color: '#92400E' }}>
                📝 <b>Exam lesson</b>: Students go directly to Take Test (no study mode).
                Attach an active question bank for the test.
              </div>
            )}
            {form.lesson_type === 'study' && (
              <div style={{ background: '#F0FDF4', borderRadius: 10, padding: 12, fontSize: 12, color: '#15803D' }}>
                {form.test_source === 'from_study'
                  ? '📖 Study only, then test from study items (correct_answer column).'
                  : '🏦 Study content + test from custom question banks. Add banks after saving.'}
                {' '}Category is set to <b>{category?.show_type === 'topic_wise' ? 'Topic Wise' : 'Full Row'}</b> show mode.
              </div>
            )}

            <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4 }}>
              💡 Pass % and timers are configured per-rank in the <a href="/ranks" style={{ color: 'var(--primary)' }}>Ranks section →</a>
            </div>

            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setLessonModal(null)}>Cancel</button>
              <button className="btn btn-primary" disabled={!form.name} onClick={save}>
                {lessonModal === 'create' ? 'Create Lesson' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
