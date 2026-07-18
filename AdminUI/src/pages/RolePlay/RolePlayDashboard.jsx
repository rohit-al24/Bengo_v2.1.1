import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { rpAdminGetStories } from '../../api/client';
import './RolePlay.css';

export default function RolePlayDashboard() {
  const navigate = useNavigate();
  const [stories, setStories]   = useState([]);
  const [loading, setLoading]   = useState(true);
  const [error,   setError]     = useState('');

  useEffect(() => {
    rpAdminGetStories()
      .then(r => setStories(r.data))
      .catch(() => setError('Could not load stories.'))
      .finally(() => setLoading(false));
  }, []);

  const published   = stories.filter(s => s.is_published).length;
  const draft       = stories.filter(s => !s.is_published).length;
  const totalDialogues = stories.reduce((acc, s) => acc + (s.dialogue_count || 0), 0);
  const recentStories = [...stories].sort((a, b) => new Date(b.created_at) - new Date(a.created_at)).slice(0, 5);

  const stats = [
    { icon: '📖', label: 'Total Stories',  value: loading ? '…' : stories.length, color: '#c41230' },
    { icon: '✅', label: 'Published',      value: loading ? '…' : published,       color: '#10b981' },
    { icon: '📝', label: 'Draft',          value: loading ? '…' : draft,           color: '#f59e0b' },
    { icon: '💬', label: 'Total Dialogues',value: loading ? '…' : totalDialogues,  color: '#667eea' },
  ];

  return (
    <div className="rp-page">
      <div className="rp-page-header">
        <div>
          <h2 className="rp-page-title">🎭 RolePlay Dashboard</h2>
          <p className="rp-page-sub">Overview of all conversation stories and activity.</p>
        </div>
        <button className="btn btn-primary" onClick={() => navigate('/roleplay/stories')}>
          📖 Manage Stories
        </button>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      {/* Stats */}
      <div className="rp-stats-grid">
        {stats.map(s => (
          <div className="rp-stat-card" key={s.label}>
            <div className="rp-stat-icon" style={{ background: `${s.color}18`, color: s.color }}>{s.icon}</div>
            <div className="rp-stat-info">
              <div className="rp-stat-value" style={{ color: s.color }}>{s.value}</div>
              <div className="rp-stat-label">{s.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent stories */}
      <div className="card" style={{ marginTop: 24 }}>
        <div className="card-header">
          <span style={{ fontWeight: 700 }}>📋 Recent Stories</span>
          <button className="btn btn-link" onClick={() => navigate('/roleplay/stories')}>View all</button>
        </div>
        {loading ? (
          <div style={{ padding: 32, textAlign: 'center' }}>
            <div className="rp-spinner" style={{ margin: '0 auto 8px' }} />
            <span style={{ color: 'var(--text-muted)', fontSize: 13 }}>Loading…</span>
          </div>
        ) : recentStories.length === 0 ? (
          <div style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)' }}>
            No stories imported yet. Go to <b>Stories</b> to add your first one.
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Cover</th><th>Title</th><th>JLPT</th>
                <th>Difficulty</th><th>Characters</th><th>Dialogues</th><th>Status</th>
              </tr>
            </thead>
            <tbody>
              {recentStories.map(s => (
                <tr key={s.id}>
                  <td><div className="rp-cover-cell">{s.cover_emoji || '📖'}</div></td>
                  <td style={{ fontWeight: 600 }}>{s.title}</td>
                  <td><span className="rp-jlpt-badge">{s.jlpt_level}</span></td>
                  <td>
                    <span className={`badge ${
                      s.difficulty === 'easy' ? 'badge-green' :
                      s.difficulty === 'medium' ? 'badge-blue' : 'badge-red'
                    }`}>
                      {s.difficulty?.charAt(0).toUpperCase() + s.difficulty?.slice(1)}
                    </span>
                  </td>
                  <td>{s.character_count ?? '—'}</td>
                  <td>{s.dialogue_count ?? '—'}</td>
                  <td>
                    <span className={`badge ${s.is_published ? 'badge-green' : 'badge-yellow'}`}>
                      {s.is_published ? 'Published' : 'Draft'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
