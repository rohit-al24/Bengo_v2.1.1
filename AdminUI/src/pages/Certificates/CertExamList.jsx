import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/client';

export default function CertExamList() {
  const [exams, setExams] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/courses/admin/exams/').then(r => setExams(r.data)).finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="page-header">
        <div>
          <h2>🎓 Certificates</h2>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
            Select an exam to manage certificate templates for each rank.
          </p>
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>Loading…</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(280px,1fr))', gap: 16 }}>
          {exams.map(exam => (
            <Link key={exam.id} to={`/certificates/${exam.id}`} style={{ textDecoration: 'none' }}>
              <div className="card" style={{ cursor: 'pointer', borderLeft: '4px solid #F59E0B', transition: 'transform .15s' }}
                onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
                onMouseLeave={e => e.currentTarget.style.transform = ''}
              >
                <div style={{ fontSize: 28, marginBottom: 8 }}>🎓</div>
                <h3 style={{ marginBottom: 4 }}>{exam.title}</h3>
                <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 12 }}>{exam.level}</p>
                <div style={{ padding: '4px 12px', background: '#FEF3C7', color: '#92400E', borderRadius: 20, fontSize: 12, fontWeight: 600, display: 'inline-block' }}>
                  Manage Certificates →
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
