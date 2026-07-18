import React, { useEffect, useState } from 'react';
import { me, getInstitutionStudents, getInstitutionMentors, getInstitution, updateInstitution, updateUser } from '../../api/client';

export default function Authentications() {
  const [user, setUser] = useState(null);
  const [settings, setSettings] = useState({ approvalRequired: false, mentorAssignEnabled: false, mentorChangeEnabled: false });
  const [students, setStudents] = useState([]);
  const [mentors, setMentors] = useState([]);
  const [inst, setInst] = useState(null);
  const [message, setMessage] = useState('');

  const load = async () => {
    try {
      const { data: u } = await me();
      setUser(u);
      const institutionId = u.institution || u.institution_id;
      if (institutionId) {
        const [{ data: s }, { data: m }, { data: institution }] = await Promise.all([
          getInstitutionStudents(institutionId),
          getInstitutionMentors(institutionId),
          getInstitution(institutionId),
        ]);
        setStudents(s);
        setMentors(m);
        setInst(institution);
        setSettings({
          approvalRequired: institution.approval_required,
          mentorAssignEnabled: institution.mentor_assign_enabled,
          mentorChangeEnabled: institution.mentor_change_enabled,
        });
      }
    } catch (e) {
      setMessage('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  useEffect(() => { load(); }, []);

  const updateSetting = async (key, value) => {
    if (!inst) return;
    try {
      const payload = {
        approval_required: key === 'approvalRequired' ? value : inst.approval_required,
        mentor_assign_enabled: key === 'mentorAssignEnabled' ? value : inst.mentor_assign_enabled,
        mentor_change_enabled: key === 'mentorChangeEnabled' ? value : inst.mentor_change_enabled,
      };
      const { data } = await updateInstitution(inst.id, payload);
      setInst(data);
      setSettings({
        approvalRequired: data.approval_required,
        mentorAssignEnabled: data.mentor_assign_enabled,
        mentorChangeEnabled: data.mentor_change_enabled,
      });
      setMessage('Settings saved.');
    } catch (e) {
      setMessage('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  const handleApproval = async (studentId, approve) => {
    try {
      await updateUser(studentId, { is_approved: approve });
      setStudents(prev => prev.map(s => s.id === studentId ? { ...s, is_approved: approve } : s));
      setMessage(approve ? 'Student approved.' : 'Student declined.');
    } catch (e) {
      setMessage('❌ ' + JSON.stringify(e.response?.data || e.message));
    }
  };

  const pendingApprovals = students.filter(s => !s.is_approved && s.institutional_registration_number);

  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 20 }}>
      <div style={{ flex: '1 1 540px', minWidth: 320 }}>
        <div className="page-header"><h2>Authentication Settings</h2></div>
        {message && (
          <div className="card" style={{ padding: 16, marginBottom: 20, backgroundColor: '#FFF4F1', color: '#9B1C1C' }}>
            {message}
          </div>
        )}
        <div className="card" style={{ padding: 20, marginBottom: 20 }}>
          <h3>Institution security settings</h3>
          <p style={{ color: 'var(--text-muted)', marginTop: 8 }}>These toggles apply to your institution's registration and mentor flows.</p>
          <div style={{ marginTop: 16, display: 'grid', gap: 12 }}>
            <label className="setting-row">
              <span>
                <strong>Approval required</strong>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                  Students who register with an institution number must be approved before the dashboard appears.
                </div>
              </span>
              <button
                className={`btn ${settings.approvalRequired ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => updateSetting('approvalRequired', !settings.approvalRequired)}
              >
                {settings.approvalRequired ? 'On' : 'Off'}
              </button>
            </label>
            <label className="setting-row">
              <span>
                <strong>Mentor assign by student</strong>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                  Allow students to choose an active mentor from institution mentors.
                </div>
              </span>
              <button
                className={`btn ${settings.mentorAssignEnabled ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => updateSetting('mentorAssignEnabled', !settings.mentorAssignEnabled)}
              >
                {settings.mentorAssignEnabled ? 'On' : 'Off'}
              </button>
            </label>
            <label className="setting-row">
              <span>
                <strong>Allow mentor changes</strong>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                  Permit students to switch their current mentor at any time.
                </div>
              </span>
              <button
                className={`btn ${settings.mentorChangeEnabled ? 'btn-primary' : 'btn-secondary'}`}
                onClick={() => updateSetting('mentorChangeEnabled', !settings.mentorChangeEnabled)}
              >
                {settings.mentorChangeEnabled ? 'On' : 'Off'}
              </button>
            </label>
          </div>
        </div>

        {settings.approvalRequired && (
          <div className="card" style={{ padding: 20, marginBottom: 20 }}>
            <h3>Approval queue</h3>
            <p style={{ color: 'var(--text-muted)', marginTop: 8 }}>
              Students with a registration number who are waiting for approval.
            </p>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Reg#</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {pendingApprovals.length === 0 ? (
                    <tr><td colSpan={5} style={{ textAlign: 'center', padding: 20 }}>No pending approvals.</td></tr>
                  ) : pendingApprovals.map((s, index) => (
                    <tr key={s.id}>
                      <td>{index + 1}</td>
                      <td>{(s.first_name || s.last_name) ? `${s.first_name || ''} ${s.last_name || ''}`.trim() : s.username}</td>
                      <td>{s.email}</td>
                      <td>{s.institutional_registration_number}</td>
                      <td>
                        <button className="btn btn-primary btn-sm" style={{ marginRight: 6 }} onClick={() => handleApproval(s.id, true)}>Approve</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleApproval(s.id, false)}>Decline</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      <div style={{ flex: '0 0 320px', minWidth: 280 }}>
        <div className="card" style={{ padding: 20 }}>
          <h3>Institution</h3>
          <p><strong>{inst?.name || 'No institution loaded'}</strong></p>
          <p style={{ color: 'var(--text-muted)' }}><strong>Approval required:</strong> {settings.approvalRequired ? 'Enabled' : 'Disabled'}</p>
          <p style={{ color: 'var(--text-muted)' }}><strong>Mentor assign:</strong> {settings.mentorAssignEnabled ? 'Enabled' : 'Disabled'}</p>
          <p style={{ color: 'var(--text-muted)' }}><strong>Mentor change:</strong> {settings.mentorChangeEnabled ? 'Enabled' : 'Disabled'}</p>
          {inst?.code && <p style={{ color: 'var(--text-muted)', marginTop: 12 }}><strong>Code:</strong> {inst.code}</p>}
        </div>
      </div>
    </div>
  );
}
