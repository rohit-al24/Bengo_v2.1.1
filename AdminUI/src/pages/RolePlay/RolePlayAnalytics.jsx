import React from 'react';
import './RolePlay.css';

const TOP_STORIES = [
  { title:'Restaurant Conversation', emoji:'🍜', plays:284, accuracy:82, jlpt:'N5' },
  { title:'Cafe Order',              emoji:'☕', plays:201, accuracy:89, jlpt:'N5' },
  { title:'Hospital Visit',          emoji:'🏥', plays:156, accuracy:74, jlpt:'N4' },
  { title:'Airport Check-In',        emoji:'✈️',  plays:143, accuracy:68, jlpt:'N3' },
  { title:'School Introduction',     emoji:'🏫', plays:112, accuracy:91, jlpt:'N5' },
];

const ACCURACY_DIST = [
  { range:'90-100%', count:38, color:'#2D9D4A' },
  { range:'80-89%',  count:62, color:'#4ECDC4' },
  { range:'70-79%',  count:74, color:'#667eea' },
  { range:'60-69%',  count:45, color:'#F59E0B' },
  { range:'<60%',    count:21, color:'#BF1B2C' },
];
const maxCount = Math.max(...ACCURACY_DIST.map(d => d.count));

export default function RolePlayAnalytics() {
  return (
    <div className="rp-page">
      <div className="rp-page-header">
        <div>
          <h2 className="rp-page-title">📈 Story Analytics</h2>
          <p className="rp-page-sub">Performance overview across all RolePlay stories.</p>
        </div>
      </div>

      {/* Summary stats */}
      <div className="rp-stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))', marginBottom: 24 }}>
        {[
          { icon:'🎭', label:'Total Sessions', value:'1,024', color:'#BF1B2C' },
          { icon:'👥', label:'Unique Players',  value:'342',   color:'#6366F1' },
          { icon:'📊', label:'Avg Accuracy',    value:'78%',   color:'#2D9D4A' },
          { icon:'⏱',  label:'Avg Duration',   value:'7m 12s',color:'#0EA5E9' },
        ].map(s => (
          <div key={s.label} className="rp-stat-card">
            <div className="rp-stat-icon" style={{ background: s.color + '18' }}>
              <span>{s.icon}</span>
            </div>
            <div>
              <div className="rp-stat-value" style={{ color: s.color }}>{s.value}</div>
              <div className="rp-stat-label">{s.label}</div>
            </div>
          </div>
        ))}
      </div>

      <div className="rp-analytics-grid">
        {/* Top stories */}
        <div className="card">
          <div className="section-header" style={{ marginBottom: 16 }}>
            <h3>🏆 Top Stories</h3>
          </div>
          {TOP_STORIES.map((s, i) => (
            <div key={s.title} className="rp-analytics-story-row">
              <div className="rp-analytics-rank">#{i + 1}</div>
              <div className="rp-analytics-story-info">
                <span className="rp-analytics-story-emoji">{s.emoji}</span>
                <div>
                  <div className="rp-analytics-story-title">{s.title}</div>
                  <span className="badge badge-blue" style={{ fontSize: 10 }}>{s.jlpt}</span>
                </div>
              </div>
              <div className="rp-analytics-story-stats">
                <div className="rp-analytics-plays">{s.plays} plays</div>
                <div
                  className="rp-analytics-acc"
                  style={{ color: s.accuracy >= 80 ? '#2D9D4A' : s.accuracy >= 70 ? '#F59E0B' : '#BF1B2C' }}
                >
                  {s.accuracy}% avg
                </div>
              </div>
              {/* Bar */}
              <div className="rp-analytics-bar-bg">
                <div
                  className="rp-analytics-bar"
                  style={{
                    width: `${(s.plays / TOP_STORIES[0].plays) * 100}%`,
                    background: `linear-gradient(90deg, #EB4B6E, #BF1B2C)`,
                  }}
                />
              </div>
            </div>
          ))}
        </div>

        {/* Accuracy distribution */}
        <div className="card">
          <div className="section-header" style={{ marginBottom: 20 }}>
            <h3>📊 Accuracy Distribution</h3>
          </div>
          <div className="rp-acc-dist">
            {ACCURACY_DIST.map(d => (
              <div key={d.range} className="rp-acc-bar-row">
                <div className="rp-acc-label">{d.range}</div>
                <div className="rp-acc-bar-bg">
                  <div
                    className="rp-acc-bar"
                    style={{
                      width: `${(d.count / maxCount) * 100}%`,
                      background: d.color,
                    }}
                  />
                </div>
                <div className="rp-acc-count">{d.count}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
