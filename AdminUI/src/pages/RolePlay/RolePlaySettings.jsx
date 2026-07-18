import React, { useState } from 'react';
import './RolePlay.css';

export default function RolePlaySettings() {
  const [settings, setSettings] = useState({
    maxAttempts: 3,
    pronunciationThreshold: 75,
    autoAdvanceDelay: 800,
    countdownSeconds: 30,
    showRomaji: false,
    showEnglish: true,
    xpPerCorrect: 15,
    coinsPerCorrect: 5,
  });

  const [saved, setSaved] = useState(false);

  const handle = (k, v) => {
    setSaved(false);
    setSettings(prev => ({ ...prev, [k]: v }));
  };

  const handleSave = async () => {
    await new Promise(r => setTimeout(r, 600));
    setSaved(true);
  };

  const Field = ({ label, hint, children }) => (
    <div className="form-group">
      <label>{label}</label>
      {hint && <div className="rp-field-hint">{hint}</div>}
      {children}
    </div>
  );

  return (
    <div className="rp-page">
      <div className="rp-page-header">
        <div>
          <h2 className="rp-page-title">⚙️ RolePlay Settings</h2>
          <p className="rp-page-sub">Configure gameplay behaviour for all RolePlay sessions.</p>
        </div>
      </div>

      <div className="rp-settings-layout">
        {/* Speech Recognition */}
        <div className="card">
          <h3 className="rp-settings-section-title">🎤 Speech Recognition</h3>

          <Field label="Max Attempts" hint="Maximum pronunciation retries allowed before the game skips the line.">
            <input
              type="number" className="input" min={1} max={5}
              value={settings.maxAttempts} onChange={e => handle('maxAttempts', parseInt(e.target.value))}
            />
          </Field>

          <Field label="Pronunciation Threshold (%)" hint={`Current: ${settings.pronunciationThreshold}%. Score below this will trigger a retry.`}>
            <input
              type="range" min={50} max={100} step={5}
              value={settings.pronunciationThreshold} onChange={e => handle('pronunciationThreshold', parseInt(e.target.value))}
            />
            <div className="rp-range-labels">
              <span>50% (Very Easy)</span>
              <span>100% (Strict)</span>
            </div>
          </Field>
        </div>

        {/* Display Settings */}
        <div className="card">
          <h3 className="rp-settings-section-title">🖥️ Gameplay Display</h3>

          <Field label="Show English Translations" hint="Display English subtitles under Japanese dialogue bubbles.">
            <label className="toggle">
              <input type="checkbox" checked={settings.showEnglish} onChange={e => handle('showEnglish', e.target.checked)} />
              <span className="toggle-slider" />
            </label>
          </Field>

          <Field label="Show Romaji Subtitles" hint="Show phonetic latin text under Japanese characters.">
            <label className="toggle">
              <input type="checkbox" checked={settings.showRomaji} onChange={e => handle('showRomaji', e.target.checked)} />
              <span className="toggle-slider" />
            </label>
          </Field>

          <Field label="Lobby Auto-countdown" hint="Seconds players have to manually pick a character before auto-assigning.">
            <input
              type="number" className="input" min={10} max={60} step={5}
              value={settings.countdownSeconds} onChange={e => handle('countdownSeconds', parseInt(e.target.value))}
            />
          </Field>
        </div>

        {/* Rewards */}
        <div className="card" style={{ gridColumn: 'span 2' }}>
          <h3 className="rp-settings-section-title">🏆 Rewards & Gamification</h3>
          <div className="rp-settings-layout" style={{ gap: 16 }}>
            <Field label="XP per Correct Dialogue" hint="Base XP awarded for each successful sentence match.">
              <input
                type="number" className="input" min={1} max={50}
                value={settings.xpPerCorrect} onChange={e => handle('xpPerCorrect', parseInt(e.target.value))}
              />
            </Field>

            <Field label="Coins per Correct Dialogue" hint="Base Gold Coins awarded for each successful sentence match.">
              <input
                type="number" className="input" min={1} max={20}
                value={settings.coinsPerCorrect} onChange={e => handle('coinsPerCorrect', parseInt(e.target.value))}
              />
            </Field>
          </div>
        </div>
      </div>

      <div className="rp-form-actions">
        {saved && <span className="rp-saved-msg">✓ Settings saved successfully</span>}
        <button className="btn btn-primary" onClick={handleSave}>Save Config</button>
      </div>
    </div>
  );
}
