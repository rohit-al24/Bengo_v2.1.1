import React, { useEffect, useState, useCallback } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../api/client';

export default function XPConfigPage() {
  const { examId, rankId } = useParams();
  const [rank,       setRank]       = useState(null);
  const [exam,       setExam]       = useState(null);
  const [categories, setCategories] = useState([]);
  const [configs,    setConfigs]    = useState({}); // { lessonId: { study_xp, test_xp, id } }
  const [saving,     setSaving]     = useState({});
  const [msg,        setMsg]        = useState('');

  const load = useCallback(async () => {
    const [rankRes, examRes, catRes, cfgRes] = await Promise.all([
      api.get(`/ranks/ranks/${rankId}/`),
      api.get(`/courses/admin/exams/${examId}/`),
      api.get('/courses/admin/categories/', { params: { exam: examId } }),
      api.get('/ranks/xp-configs/', { params: { rank: rankId } }),
    ]);
    setRank(rankRes.data);
    setExam(examRes.data);
    setCategories(catRes.data);
    // Build config map by lesson id
    const map = {};
    for (const cfg of cfgRes.data) {
      map[cfg.lesson] = cfg;
    }
    setConfigs(map);
  }, [examId, rankId]);

  useEffect(() => { load(); }, [load]);

  const updateLocal = (lessonId, key, value) => {
    setConfigs(prev => ({
      ...prev,
      [lessonId]: { ...(prev[lessonId] || { study_xp: 10, test_xp: 50 }), [key]: parseInt(value) || 0 },
    }));
  };

  const saveLesson = async (lessonId) => {
    setSaving(p => ({ ...p, [lessonId]: true }));
    setMsg('');
    const cfg = configs[lessonId] || { study_xp: 10, test_xp: 50 };
    try {
      if (cfg.id) {
        await api.patch(`/ranks/xp-configs/${cfg.id}/`, { study_xp: cfg.study_xp, test_xp: cfg.test_xp });
      } else {
        const res = await api.post('/ranks/xp-configs/', {
          rank: parseInt(rankId), lesson: lessonId,
          study_xp: cfg.study_xp, test_xp: cfg.test_xp,
        });
        setConfigs(p => ({ ...p, [lessonId]: res.data }));
      }
      setMsg(`✅ Saved XP for lesson ${lessonId}`);
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data));
    } finally {
      setSaving(p => ({ ...p, [lessonId]: false }));
    }
  };

  return (
    <div>
      {/* Breadcrumb */}
      <div className="breadcrumb">
        <Link to="/ranks">Ranks</Link> ›{' '}
        <Link to={`/ranks/${examId}`}>{exam?.title || '…'}</Link> ›{' '}
        <span>XP Config — {rank?.name}</span>
      </div>

      <div className="page-header">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {rank && (
              <div style={{
                width: 36, height: 36, borderRadius: '50%',
                background: rank.color, display: 'flex', alignItems: 'center',
                justifyContent: 'center', fontSize: 18,
              }}>
                {rank.icon}
              </div>
            )}
            <h2>⚡ XP Config — {rank?.name}</h2>
          </div>
          <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
            Set how much XP users earn for completing study or passing the test for each lesson in this rank.
          </p>
        </div>
      </div>

      {msg && (
        <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`} style={{ marginBottom: 16 }}>
          {msg}
        </div>
      )}

      {/* One section per category */}
      {categories.map(cat => {
        const catLessons = cat.lessons || [];
        if (catLessons.length === 0) return null;
        return (
          <div key={cat.id} className="card" style={{ marginBottom: 20 }}>
            <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 14, color: 'var(--primary)' }}>
              📂 {cat.title}
              <span style={{ marginLeft: 8, fontSize: 11, color: 'var(--text-muted)',
                            fontWeight: 400, padding: '2px 8px',
                            background: cat.show_type === 'topic_wise' ? '#EEF2FF' : '#F0FDF4',
                            borderRadius: 10 }}>
                {cat.show_type === 'topic_wise' ? 'Topic Wise' : 'Full Row'}
              </span>
            </div>

            <div className="table-wrap" style={{ margin: 0 }}>
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Lesson</th>
                    <th>Type</th>
                    <th style={{ width: 130 }}>📖 Study XP</th>
                    <th style={{ width: 130 }}>✅ Test XP</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {catLessons.map((lesson, i) => {
                    const cfg = configs[lesson.id] || {};
                    const studyXP = cfg.study_xp ?? 10;
                    const testXP  = cfg.test_xp  ?? 50;
                    const isExam  = lesson.lesson_type === 'exam';

                    return (
                      <tr key={lesson.id}>
                        <td style={{ color: 'var(--text-muted)' }}>{i + 1}</td>
                        <td style={{ fontWeight: 600 }}>{lesson.name}</td>
                        <td>
                          <span className={`badge ${isExam ? 'badge-red' : 'badge-blue'}`}>
                            {isExam ? '📝 Exam' : '📖 Study'}
                          </span>
                        </td>
                        <td>
                          {isExam ? (
                            <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>— (exam only)</span>
                          ) : (
                            <input
                              type="number" min={0} className="form-control"
                              style={{ width: 100, padding: '4px 8px' }}
                              value={studyXP}
                              onChange={e => updateLocal(lesson.id, 'study_xp', e.target.value)}
                            />
                          )}
                        </td>
                        <td>
                          <input
                            type="number" min={0} className="form-control"
                            style={{ width: 100, padding: '4px 8px' }}
                            value={testXP}
                            onChange={e => updateLocal(lesson.id, 'test_xp', e.target.value)}
                          />
                        </td>
                        <td>
                          <button
                            className="btn btn-primary btn-sm"
                            disabled={saving[lesson.id]}
                            onClick={() => saveLesson(lesson.id)}
                          >
                            {saving[lesson.id] ? '…' : 'Save'}
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        );
      })}

      {categories.length === 0 && (
        <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-muted)' }}>
          No categories found. <Link to={`/courses/${examId}`}>Add categories →</Link>
        </div>
      )}
    </div>
  );
}
