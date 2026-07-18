import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  rpAdminGetStories, rpAdminUpdateStory, rpAdminDeleteStory,
  rpAdminDownloadTemplate, rpAdminImportExcel,
} from '../../api/client';
import './RolePlay.css';

const JLPT_LEVELS  = ['All', 'N5', 'N4', 'N3', 'N2', 'N1'];
const STATUSES     = ['All', 'published', 'draft'];

// ── Import Modal ───────────────────────────────────────────────────────────────
function ImportModal({ onClose, onImported }) {
  const fileRef  = useRef(null);
  const [phase,  setPhase]  = useState('idle');   // idle | uploading | done | error
  const [result, setResult] = useState(null);
  const [error,  setError]  = useState('');
  const [dragOver, setDragOver] = useState(false);

  const handleDownload = async () => {
    try {
      const res  = await rpAdminDownloadTemplate();
      const url  = URL.createObjectURL(new Blob([res.data]));
      const a    = document.createElement('a');
      a.href     = url;
      a.download = 'roleplay_template.xlsx';
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      setError('Could not download template.');
    }
  };

  const doImport = useCallback(async (file) => {
    if (!file) return;
    setPhase('uploading');
    setError('');
    try {
      const res = await rpAdminImportExcel(file);
      setResult(res.data);
      setPhase('done');
      onImported();
    } catch (e) {
      setError(e?.response?.data?.detail || 'Import failed. Check your file format.');
      setPhase('error');
    }
  }, [onImported]);

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    setDragOver(false);
    const f = e.dataTransfer.files[0];
    if (f) doImport(f);
  }, [doImport]);

  return (
    <div className="rp-modal-overlay" onClick={onClose}>
      <div className="rp-modal" onClick={e => e.stopPropagation()}>
        <div className="rp-modal-header">
          <h3>📥 Add Stories</h3>
          <button className="rp-modal-close" onClick={onClose}>✕</button>
        </div>

        {/* Step 1 — Download */}
        <div className="rp-modal-step">
          <div className="rp-modal-step-num">1</div>
          <div className="rp-modal-step-body">
            <div className="rp-modal-step-title">Download Template</div>
            <p className="rp-modal-step-desc">
              Get the Excel template with all required columns: Story info, characters, dialogue, romaji, English, emotion.
            </p>
            <button className="btn btn-secondary" onClick={handleDownload}>
              ⬇ Download roleplay_template.xlsx
            </button>
          </div>
        </div>

        <div className="rp-modal-divider" />

        {/* Step 2 — Import */}
        <div className="rp-modal-step">
          <div className="rp-modal-step-num">2</div>
          <div className="rp-modal-step-body">
            <div className="rp-modal-step-title">Fill & Import Excel</div>
            <p className="rp-modal-step-desc">
              Fill in the template (one row per dialogue line) then upload it here. Stories and characters are created automatically.
            </p>

            {phase === 'idle' || phase === 'error' ? (
              <div
                className={`rp-drop-zone rp-drop-zone-sm ${dragOver ? 'drag-over' : ''}`}
                onDragOver={e => { e.preventDefault(); setDragOver(true); }}
                onDragLeave={() => setDragOver(false)}
                onDrop={handleDrop}
                onClick={() => fileRef.current.click()}
              >
                <div className="rp-drop-icon" style={{ fontSize: 32 }}>📊</div>
                <div className="rp-drop-title" style={{ fontSize: 14 }}>
                  Drop Excel file or click to browse
                </div>
                <div className="rp-drop-hint">.xlsx · .xls</div>
                <input
                  ref={fileRef}
                  type="file"
                  accept=".xlsx,.xls"
                  style={{ display: 'none' }}
                  onChange={e => doImport(e.target.files[0])}
                />
              </div>
            ) : phase === 'uploading' ? (
              <div className="rp-loading-card" style={{ padding: 24 }}>
                <div className="rp-spinner" />
                <div className="rp-loading-text" style={{ fontSize: 14 }}>Importing…</div>
              </div>
            ) : (
              <div className="rp-import-done" style={{ padding: 20 }}>
                <div className="rp-done-icon" style={{ fontSize: 40 }}>🎉</div>
                <div className="rp-done-stats" style={{ gap: 16 }}>
                  <div className="rp-done-stat">
                    <span>{result?.stories_created ?? 0}</span>
                    <label>Stories</label>
                  </div>
                  <div className="rp-done-stat">
                    <span>{result?.dialogues_created ?? 0}</span>
                    <label>Dialogues</label>
                  </div>
                </div>
                <button className="btn btn-secondary btn-sm" onClick={() => setPhase('idle')}>
                  Import Another
                </button>
              </div>
            )}

            {error && (
              <div className="alert alert-error" style={{ marginTop: 10 }}>
                ⚠️ {error}
              </div>
            )}
          </div>
        </div>

        {/* Column reference */}
        <details style={{ marginTop: 16 }}>
          <summary style={{ cursor: 'pointer', fontSize: 12, color: 'var(--text-muted)', fontWeight: 600 }}>
            📐 Required columns
          </summary>
          <div className="rp-columns-grid" style={{ marginTop: 8 }}>
            {['Story_Title','Category','JLPT_Level','Difficulty','Cover_Emoji',
              'Char_Name','Char_Emoji','Char_Order',
              'Dialogue_Order','Japanese','Romaji','English','Emotion','Pause_MS',
            ].map(c => (
              <div key={c} className="rp-column-chip">{c}</div>
            ))}
          </div>
        </details>
      </div>
    </div>
  );
}

// ── Main Stories Page ──────────────────────────────────────────────────────────
export default function RolePlayStories() {
  const [stories,      setStories]      = useState([]);
  const [loading,      setLoading]      = useState(true);
  const [error,        setError]        = useState('');
  const [search,       setSearch]       = useState('');
  const [jlptFilter,   setJlptFilter]   = useState('All');
  const [statusFilter, setStatusFilter] = useState('All');
  const [showModal,    setShowModal]    = useState(false);

  const fetchStories = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await rpAdminGetStories();
      setStories(res.data);
    } catch {
      setError('Could not load stories. Check your connection.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchStories(); }, []);

  const handleToggleStatus = async (s) => {
    const newStatus = s.is_published;  // will invert
    try {
      await rpAdminUpdateStory(s.id, { is_published: !s.is_published });
      setStories(prev => prev.map(x => x.id === s.id ? { ...x, is_published: !x.is_published } : x));
    } catch {
      setError('Could not update story status.');
    }
  };

  const handleDelete = async (s) => {
    if (!window.confirm(`Delete "${s.title}"? This cannot be undone.`)) return;
    try {
      await rpAdminDeleteStory(s.id);
      setStories(prev => prev.filter(x => x.id !== s.id));
    } catch {
      setError('Could not delete story.');
    }
  };

  const filtered = stories.filter(s =>
    (jlptFilter === 'All'  || s.jlpt_level === jlptFilter) &&
    (statusFilter === 'All' || (statusFilter === 'published' ? s.is_published : !s.is_published)) &&
    (search === '' || s.title.toLowerCase().includes(search.toLowerCase()) ||
                      s.category.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className="rp-page">
      {showModal && (
        <ImportModal
          onClose={() => setShowModal(false)}
          onImported={() => { setShowModal(false); fetchStories(); }}
        />
      )}

      <div className="rp-page-header">
        <div>
          <h2 className="rp-page-title">📖 Stories</h2>
          <p className="rp-page-sub">Manage all RolePlay conversation stories.</p>
        </div>
        <div className="rp-header-actions">
          <button className="btn btn-primary" onClick={() => setShowModal(true)}>
            + Add Story
          </button>
        </div>
      </div>

      {error && <div className="alert alert-error" style={{ marginBottom: 16 }}>⚠️ {error}</div>}

      {/* Filters */}
      <div className="rp-filters">
        <input
          className="rp-search"
          placeholder="🔍 Search stories..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <select className="rp-select" value={jlptFilter} onChange={e => setJlptFilter(e.target.value)}>
          {JLPT_LEVELS.map(l => <option key={l}>{l}</option>)}
        </select>
        <select className="rp-select" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
          {STATUSES.map(s => (
            <option key={s} value={s}>
              {s === 'All' ? 'All Status' : s.charAt(0).toUpperCase() + s.slice(1)}
            </option>
          ))}
        </select>
        <button className="btn btn-secondary btn-sm" onClick={fetchStories} title="Refresh">
          🔄
        </button>
      </div>

      <div className="card" style={{ padding: 0 }}>
        <div className="table-wrap">
          {loading ? (
            <div style={{ padding: 48, textAlign: 'center' }}>
              <div className="rp-spinner" style={{ margin: '0 auto 12px' }} />
              <div style={{ color: 'var(--text-muted)', fontSize: 13 }}>Loading stories…</div>
            </div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Cover</th>
                  <th>Title</th>
                  <th>Category</th>
                  <th>JLPT</th>
                  <th>Characters</th>
                  <th>Dialogue</th>
                  <th>Difficulty</th>
                  <th>Status</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(s => (
                  <tr key={s.id}>
                    <td>
                      <div className="rp-cover-cell">{s.cover_emoji || '📖'}</div>
                    </td>
                    <td style={{ fontWeight: 700 }}>{s.title}</td>
                    <td>
                      {s.category
                        ? <span className="badge badge-blue">{s.category}</span>
                        : <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>—</span>}
                    </td>
                    <td><span className="rp-jlpt-badge">{s.jlpt_level}</span></td>
                    <td>{s.character_count ?? '—'}</td>
                    <td>{s.dialogue_count ?? '—'}</td>
                    <td>
                      <span className={`badge ${
                        s.difficulty === 'easy' ? 'badge-green' :
                        s.difficulty === 'medium' ? 'badge-blue' : 'badge-red'
                      }`}>
                        {s.difficulty?.charAt(0).toUpperCase() + s.difficulty?.slice(1) ?? '—'}
                      </span>
                    </td>
                    <td>
                      <button
                        className={`rp-status-toggle ${s.is_published ? 'published' : 'draft'}`}
                        onClick={() => handleToggleStatus(s)}
                      >
                        {s.is_published ? '● Published' : '○ Draft'}
                      </button>
                    </td>
                    <td style={{ color: 'var(--text-muted)', fontSize: 12 }}>
                      {s.created_at ? new Date(s.created_at).toLocaleDateString() : '—'}
                    </td>
                    <td>
                      <div className="rp-action-row">
                        <button
                          className="btn btn-icon btn-danger"
                          title="Delete"
                          onClick={() => handleDelete(s)}
                        >🗑</button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!loading && filtered.length === 0 && (
                  <tr>
                    <td colSpan={10} style={{ textAlign: 'center', padding: 48, color: 'var(--text-muted)' }}>
                      {stories.length === 0
                        ? '📭 No stories yet — click "Add Story" to import your first one.'
                        : 'No stories match the current filters.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {!loading && (
        <div className="rp-table-footer">
          Showing {filtered.length} of {stories.length} stories
        </div>
      )}
    </div>
  );
}
