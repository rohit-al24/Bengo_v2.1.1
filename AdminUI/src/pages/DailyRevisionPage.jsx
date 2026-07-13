import React, { useEffect, useState } from 'react';
import api from '../api/client';

export default function DailyRevisionPage() {
  const [config, setConfig] = useState({
    timer_minutes: 10,
    per_question_xp: 5,
    overall_completion_xp: 10,
    streak_count: 1,
    daily_limit: 1,
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [editing, setEditing] = useState(false);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    try {
      const { data } = await api.get('/ranks/logs/daily_revision_config/');
      setConfig({
        timer_minutes: data.timer_minutes ?? 10,
        per_question_xp: data.per_question_xp ?? 5,
        overall_completion_xp: data.overall_completion_xp ?? 10,
        streak_count: data.streak_count ?? 1,
        daily_limit: data.daily_limit ?? 1,
      });
    } catch (err) {
      setMessage('Unable to load daily revision settings.');
    } finally {
      setLoading(false);
    }
  };

  const saveConfig = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      await api.post('/ranks/logs/daily_revision_config/', config);
      setMessage('Daily revision settings saved.');
      setEditing(false);
    } catch (err) {
      setMessage('Unable to save daily revision settings.');
    } finally {
      setSaving(false);
    }
  };

  const inputStyle = {
    width: '100%',
    padding: '10px 12px',
    borderRadius: '10px',
    border: '1px solid #d6dbe2',
    marginTop: '6px',
    fontSize: '14px',
  };

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h2 style={{ margin: 0 }}>Daily Revision</h2>
          <p style={{ margin: '4px 0 0', color: 'var(--text-muted)' }}>
            Control the revision session timer, XP rewards, streak growth, and daily attempt allowance.
          </p>
        </div>
        <button className="btn btn-primary" onClick={() => setEditing(true)}>
          Configure
        </button>
      </div>

      {message ? <div className="alert" style={{ marginBottom: 16 }}>{message}</div> : null}

      {loading ? (
        <div className="card">Loading...</div>
      ) : (
        <div className="card" style={{ display: 'grid', gap: 12 }}>
          <div><strong>Timer:</strong> {config.timer_minutes} minutes</div>
          <div><strong>Per-question XP:</strong> {config.per_question_xp}</div>
          <div><strong>Overall completion XP:</strong> {config.overall_completion_xp}</div>
          <div><strong>Streak count:</strong> {config.streak_count}</div>
          <div><strong>Daily limit:</strong> {config.daily_limit} attempts/day</div>
        </div>
      )}

      {editing ? (
        <div className="card" style={{ marginTop: 16 }}>
          <h3 style={{ marginTop: 0 }}>Daily Revision Settings</h3>
          <form onSubmit={saveConfig} style={{ display: 'grid', gap: 12 }}>
            <label>
              Timer (minutes)
              <input
                type="number"
                min="1"
                value={config.timer_minutes}
                onChange={(e) => setConfig({ ...config, timer_minutes: Number(e.target.value) })}
                style={inputStyle}
              />
            </label>
            <label>
              Per-question XP
              <input
                type="number"
                min="0"
                value={config.per_question_xp}
                onChange={(e) => setConfig({ ...config, per_question_xp: Number(e.target.value) })}
                style={inputStyle}
              />
            </label>
            <label>
              Overall completion XP
              <input
                type="number"
                min="0"
                value={config.overall_completion_xp}
                onChange={(e) => setConfig({ ...config, overall_completion_xp: Number(e.target.value) })}
                style={inputStyle}
              />
            </label>
            <label>
              Streak count
              <input
                type="number"
                min="0"
                value={config.streak_count}
                onChange={(e) => setConfig({ ...config, streak_count: Number(e.target.value) })}
                style={inputStyle}
              />
            </label>
            <label>
              Daily limit
              <input
                type="number"
                min="1"
                value={config.daily_limit}
                onChange={(e) => setConfig({ ...config, daily_limit: Number(e.target.value) })}
                style={inputStyle}
              />
            </label>
            <div style={{ display: 'flex', gap: 10 }}>
              <button className="btn btn-primary" type="submit" disabled={saving}>
                {saving ? 'Saving...' : 'Save Settings'}
              </button>
              <button className="btn btn-secondary" type="button" onClick={() => setEditing(false)}>
                Cancel
              </button>
            </div>
          </form>
        </div>
      ) : null}
    </div>
  );
}
