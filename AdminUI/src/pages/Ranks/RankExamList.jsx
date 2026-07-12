import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../../api/client';

export default function RankExamList() {
  const [exams, setExams] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/courses/admin/exams/').then(r => setExams(r.data)).finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>🏅 Rank System</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
            Select an exam to configure its rank levels and progression settings.
          </p>
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>Loading…</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(280px,1fr))', gap: 16 }}>
          {exams.map(exam => (
            <Link
              key={exam.id}
              to={`/ranks/${exam.id}`}
              style={{ textDecoration: 'none' }}
            >
              <div className="card" style={{
                cursor: 'pointer', transition: 'transform .15s, box-shadow .15s',
                borderLeft: '4px solid var(--primary)',
              }}
                onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(99,102,241,.15)'; }}
                onMouseLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = ''; }}
              >
                <div style={{ fontSize: 28, marginBottom: 8 }}>
                  {exam.level === 'N5' ? '🥉' : exam.level === 'N4' ? '🥈' : exam.level === 'N3' ? '🥇' : '🏆'}
                </div>
                <h3 style={{ marginBottom: 4 }}>{exam.title}</h3>
                <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 12 }}>
                  {exam.level} · {exam.description || 'No description'}
                </p>
                <div style={{
                  display: 'inline-block', padding: '4px 12px',
                  background: 'var(--primary-light)', color: 'var(--primary)',
                  borderRadius: 20, fontSize: 12, fontWeight: 600
                }}>
                  Configure Ranks →
                </div>
              </div>
            </Link>
          ))}
          {exams.length === 0 && (
            <div style={{ gridColumn: '1/-1', textAlign: 'center', padding: 60, color: 'var(--text-muted)' }}>
              No exams found. Create exams in Course Editor first.
            </div>
          )}
        </div>
      )}
    </div>
  );
}
