import { useState, useEffect } from 'react';
import './AdrenalineDuelConfig.css';

const BASE = '/api/clan/config/duel/';

async function apiFetch(method, body) {
  const token = localStorage.getItem('access_token');
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(BASE, opts);
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

function Field({ label, hint, name, value, onChange, type = 'number', min, max, step = '1' }) {
  return (
    <div className="adc-field">
      <label className="adc-label">
        {label}
        {hint && <span className="adc-hint">{hint}</span>}
      </label>
      <input
        type={type}
        name={name}
        value={value ?? ''}
        min={min}
        max={max}
        step={step}
        className="adc-input"
        onChange={e => onChange(name, type === 'number' ? Number(e.target.value) : e.target.value)}
      />
    </div>
  );
}

function Toggle({ label, hint, name, value, onChange }) {
  return (
    <div className="adc-field adc-toggle-row">
      <div>
        <span className="adc-label">{label}</span>
        {hint && <span className="adc-hint">{hint}</span>}
      </div>
      <button
        type="button"
        className={`adc-toggle ${value ? 'on' : 'off'}`}
        onClick={() => onChange(name, !value)}
      >
        <span className="adc-toggle-knob" />
      </button>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div className="adc-section">
      <div className="adc-section-title">{title}</div>
      <div className="adc-section-body">{children}</div>
    </div>
  );
}

export default function AdrenalineDuelConfig() {
  const [cfg, setCfg]       = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved]   = useState(false);
  const [error, setError]   = useState('');

  useEffect(() => {
    apiFetch('GET')
      .then(setCfg)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const update = (key, val) => setCfg(prev => ({ ...prev, [key]: val }));

  const save = async () => {
    setSaving(true); setError(''); setSaved(false);
    try {
      const updated = await apiFetch('PATCH', cfg);
      setCfg(updated);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div className="adc-loading"><div className="adc-spinner" />Loading config…</div>;

  return (
    <div className="adc-root">
      {/* ── Header ── */}
      <div className="adc-header">
        <div>
          <h1 className="adc-title">Adrenaline Duel Config</h1>
          <p className="adc-subtitle">Tune the tug-of-war duel mechanics, timer, and shield logic.</p>
        </div>
        <button className={`adc-save-btn ${saving ? 'loading' : ''} ${saved ? 'saved' : ''}`} onClick={save} disabled={saving}>
          {saving ? 'Saving…' : saved ? '✓ Saved' : 'Save Changes'}
        </button>
      </div>

      {error && <div className="adc-error">{error}</div>}

      <div className="adc-grid">

        {/* ── Match-wide settings (most prominent) ── */}
        <Section title="⏱  Match Settings">
          <Field label="Match Timer (seconds)" hint="Global countdown. When it reaches 0, higher BP wins."
            name="duel_timer_seconds" value={cfg?.duel_timer_seconds} onChange={update} min={30} max={600} />
          <Field label="Questions Per Duel" hint="How many random questions to load from active banks."
            name="questions_per_duel" value={cfg?.questions_per_duel} onChange={update} min={5} max={50} />
          <Field label="Shield Combo Threshold" hint="Defender needs this many combos to be offered a Shield block."
            name="shield_combo_threshold" value={cfg?.shield_combo_threshold} onChange={update} min={1} max={10} />
        </Section>

        {/* ── Bar fill rates ── */}
        <Section title="📊  Bar Fill Rates">
          <Field label="BP Per Correct Answer (%)" name="fill_per_correct_answer" value={cfg?.fill_per_correct_answer} onChange={update} step="0.5" />
          <Field label="Bonus BP Per Combo Tier (%)" name="fill_per_combo_tier" value={cfg?.fill_per_combo_tier} onChange={update} step="0.5" />
          <Field label="Idle Decay Rate (%/s)" name="decay_rate_idle" value={cfg?.decay_rate_idle} onChange={update} step="0.1" />
          <Field label="Wrong Answer Decay (%)" name="decay_rate_wrong_answer" value={cfg?.decay_rate_wrong_answer} onChange={update} step="0.5" />
        </Section>

        {/* ── Momentum steal ── */}
        <Section title="⚡  Momentum Steal">
          <Field label="Combo Tier Steal Threshold" hint="Combos above this count trigger steal."
            name="combo_tier_steal_threshold" value={cfg?.combo_tier_steal_threshold} onChange={update} />
          <Field label="Steal % Per Combo Tick" name="steal_pct_per_combo_tick" value={cfg?.steal_pct_per_combo_tick} onChange={update} step="0.5" />
          <Field label="Max Steal Per Match (%)" name="max_steal_per_match" value={cfg?.max_steal_per_match} onChange={update} step="1" />
        </Section>

        {/* ── Shield ── */}
        <Section title="🛡  Shield Reflect">
          <Field label="Shield Reflect %" hint="% of adrenaline reflected back to attacker on block."
            name="shield_reflect_pct" value={cfg?.shield_reflect_pct} onChange={update} step="0.5" />
        </Section>

        {/* ── Overdrive Clash ── */}
        <Section title="🔥  Overdrive Clash">
          <Field label="Trigger Threshold (%)" name="overdrive_trigger_threshold" value={cfg?.overdrive_trigger_threshold} onChange={update} />
          <Field label="Overdrive Question Count" name="overdrive_question_count" value={cfg?.overdrive_question_count} onChange={update} />
          <Field label="Per-Question Timer (s)" name="overdrive_question_timer_sec" value={cfg?.overdrive_question_timer_sec} onChange={update} />
          <Field label="Score Multiplier" name="overdrive_score_multiplier" value={cfg?.overdrive_score_multiplier} onChange={update} step="0.1" />
          <Field label="Loser BP Penalty" name="overdrive_loser_bp_penalty" value={cfg?.overdrive_loser_bp_penalty} onChange={update} />
          <Toggle label="Award Winner Badge" name="overdrive_winner_badge" value={cfg?.overdrive_winner_badge} onChange={update} />
        </Section>

        {/* ── Adrenaline Mode ── */}
        <Section title="💥  Adrenaline Mode">
          <Field label="Duration (seconds)" name="adrenaline_mode_duration_sec" value={cfg?.adrenaline_mode_duration_sec} onChange={update} />
          <Field label="BP Multiplier" name="adrenaline_mode_bp_multiplier" value={cfg?.adrenaline_mode_bp_multiplier} onChange={update} step="0.1" />
          <Field label="Speed Multiplier" name="adrenaline_mode_speed_mult" value={cfg?.adrenaline_mode_speed_mult} onChange={update} step="0.1" />
          <Field label="Timer Reduction (s)" name="adrenaline_mode_timer_reduction_sec" value={cfg?.adrenaline_mode_timer_reduction_sec} onChange={update} />
          <Toggle label="Screen Shake" name="adrenaline_screen_shake" value={cfg?.adrenaline_screen_shake} onChange={update} />
          <Toggle label="Heartbeat Sound" name="adrenaline_heartbeat_sound" value={cfg?.adrenaline_heartbeat_sound} onChange={update} />
          <Toggle label="Red Aura Effect" name="adrenaline_red_aura" value={cfg?.adrenaline_red_aura} onChange={update} />
          <Toggle label="Voice Announcement" name="adrenaline_voice_announcement" value={cfg?.adrenaline_voice_announcement} onChange={update} />
        </Section>

        {/* ── Sabotage ── */}
        <Section title="🗡  Sabotage Strike">
          <Field label="Opponent Adrenaline Threshold (%)" hint="Knife deals bonus steal above this."
            name="sabotage_opponent_adrenaline_threshold" value={cfg?.sabotage_opponent_adrenaline_threshold} onChange={update} />
          <Field label="Bonus Steal (%)" name="sabotage_bonus_steal_pct" value={cfg?.sabotage_bonus_steal_pct} onChange={update} step="0.5" />
        </Section>

      </div>

      {/* ── Bottom save bar ── */}
      <div className="adc-bottom-bar">
        <span className="adc-last-saved">Changes are saved to the singleton config and reflected immediately.</span>
        <button className={`adc-save-btn ${saving ? 'loading' : ''} ${saved ? 'saved' : ''}`} onClick={save} disabled={saving}>
          {saving ? 'Saving…' : saved ? '✓ Saved' : 'Save Changes'}
        </button>
      </div>
    </div>
  );
}
