import React, { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../api/client';

export default function CertExamDetail() {
  const { examId } = useParams();
  const [exam,    setExam]    = useState(null);
  const [ranks,   setRanks]   = useState([]);
  const [certs,   setCerts]   = useState({}); // { rankId: [cert,...] }
  const [showModal, setShowModal] = useState(false);
  const [selectedRank, setSelectedRank] = useState(null);
  const [form, setForm]   = useState({ name: '', preview_note: '' });
  const [saving, setSaving] = useState(false);
  const [msg,    setMsg]    = useState('');
  const fileRef = useRef();

  const load = async () => {
    const [examRes, ranksRes] = await Promise.all([
      api.get(`/courses/admin/exams/${examId}/`),
      api.get('/ranks/ranks/', { params: { exam: examId } }),
    ]);
    setExam(examRes.data);
    setRanks(ranksRes.data);

    // Load certs for each rank
    const certMap = {};
    for (const rank of ranksRes.data) {
      const res = await api.get('/certificates/templates/', { params: { rank: rank.id } });
      certMap[rank.id] = res.data;
    }
    setCerts(certMap);
  };

  useEffect(() => { load(); }, [examId]);

  const openUpload = (rank) => {
    setSelectedRank(rank);
    setForm({ name: `${rank.name} Certificate`, preview_note: '' });
    setShowModal(true);
  };

  const handleUpload = async () => {
    const file = fileRef.current?.files?.[0];
    if (!file || !selectedRank) return;
    setSaving(true); setMsg('');
    try {
      const fd = new FormData();
      fd.append('rank', selectedRank.id);
      fd.append('name', form.name);
      fd.append('preview_note', form.preview_note);
      fd.append('template_file', file);
      await api.post('/certificates/templates/', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setMsg('✅ Certificate uploaded.');
      setShowModal(false);
      load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data));
    } finally {
      setSaving(false);
    }
  };

  const toggleActive = async (cert) => {
    const endpoint = cert.is_active
      ? `/certificates/templates/${cert.id}/deactivate/`
      : `/certificates/templates/${cert.id}/activate/`;
    await api.post(endpoint);
    load();
  };

  const deleteCert = async (id) => {
    if (!window.confirm('Delete this certificate template?')) return;
    await api.delete(`/certificates/templates/${id}/`);
    load();
  };

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/certificates">Certificates</Link> › <span>{exam?.title || '…'}</span>
      </div>

      <div className="page-header">
        <h2>🎓 {exam?.title} — Certificate Templates</h2>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      {ranks.length === 0 && (
        <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-muted)' }}>
          No ranks configured for this exam yet. <Link to={`/ranks/${examId}`}>Configure ranks first →</Link>
        </div>
      )}

      {/* One section per rank */}
      {ranks.map(rank => {
        const rankCerts = certs[rank.id] || [];
        const active    = rankCerts.find(c => c.is_active);

        return (
          <div key={rank.id} className="card" style={{ marginBottom: 20 }}>
            {/* Rank header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
              <div style={{
                width: 40, height: 40, borderRadius: '50%', background: rank.color,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0,
              }}>
                {rank.icon}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 15 }}>{rank.name}</div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Rank #{rank.order}</div>
              </div>
              <button className="btn btn-primary btn-sm" onClick={() => openUpload(rank)}>
                + Upload Template
              </button>
            </div>

            {/* Active badge */}
            {active && (
              <div style={{
                display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px',
                background: '#F0FDF4', border: '1px solid #86EFAC', borderRadius: 8, marginBottom: 12,
              }}>
                <span style={{ fontSize: 16 }}>✅</span>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: '#16A34A' }}>ACTIVE CERTIFICATE</div>
                  <div style={{ fontSize: 12, color: '#15803D' }}>{active.name}</div>
                </div>
                <a href={active.template_url} target="_blank" rel="noreferrer"
                  style={{ marginLeft: 'auto', fontSize: 12, color: 'var(--primary)', fontWeight: 600 }}>
                  Preview →
                </a>
              </div>
            )}

            {/* All templates table */}
            {rankCerts.length > 0 ? (
              <div className="table-wrap" style={{ margin: 0 }}>
                <table>
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>File</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rankCerts.map(cert => (
                      <tr key={cert.id}>
                        <td style={{ fontWeight: 600 }}>{cert.name}</td>
                        <td>
                          <a href={cert.template_url} target="_blank" rel="noreferrer"
                            style={{ color: 'var(--primary)', fontSize: 12 }}>
                            View File ↗
                          </a>
                        </td>
                        <td>
                          <span style={{
                            padding: '3px 10px', borderRadius: 12, fontSize: 11, fontWeight: 600,
                            background: cert.is_active ? '#D1FAE5' : '#F3F4F6',
                            color: cert.is_active ? '#065F46' : '#6B7280',
                          }}>
                            {cert.is_active ? '● Active' : '○ Inactive'}
                          </span>
                        </td>
                        <td>
                          <div style={{ display: 'flex', gap: 6 }}>
                            <button
                              className="btn btn-sm"
                              style={{
                                background: cert.is_active ? '#FEE2E2' : '#D1FAE5',
                                color: cert.is_active ? '#DC2626' : '#065F46',
                              }}
                              onClick={() => toggleActive(cert)}
                            >
                              {cert.is_active ? 'Deactivate' : 'Activate'}
                            </button>
                            <button className="btn btn-sm"
                              style={{ background: '#FEE2E2', color: '#DC2626' }}
                              onClick={() => deleteCert(cert.id)}>
                              🗑
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--text-muted)', fontSize: 13 }}>
                No certificate templates yet for this rank.
              </div>
            )}
          </div>
        );
      })}

      {/* Upload Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>📄 Upload Certificate Template for {selectedRank?.name}</h3>
              <button className="btn btn-icon" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div style={{ display: 'grid', gap: 14 }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label>Certificate Name *</label>
                <input className="form-control" value={form.name}
                  onChange={e => setForm(p => ({ ...p, name: e.target.value }))}
                  placeholder="e.g. Bronze Mastery Certificate" />
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label>Template File (PDF or Image) *</label>
                <input type="file" accept=".pdf,.png,.jpg,.jpeg,.webp"
                  ref={fileRef}
                  style={{ padding: 10, background: '#F6F9FF', border: '2px dashed var(--border)', borderRadius: 10, width: '100%' }}
                />
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label>Admin Notes (optional)</label>
                <input className="form-control" value={form.preview_note}
                  onChange={e => setForm(p => ({ ...p, preview_note: e.target.value }))}
                  placeholder="Internal notes about this template" />
              </div>

              <div style={{ background: '#FEF3C7', borderRadius: 8, padding: 10, fontSize: 12, color: '#92400E' }}>
                💡 Only one certificate per rank can be active. Activating this will auto-deactivate the current one.
              </div>
            </div>

            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
              <button className="btn btn-primary" disabled={saving} onClick={handleUpload}>
                {saving ? 'Uploading…' : 'Upload & Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
