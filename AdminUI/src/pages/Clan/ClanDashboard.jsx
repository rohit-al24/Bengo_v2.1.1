import React, { useState, useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import "./ClanDashboard.css";

// ─── KPI DATA (would come from /api/clan/admin/dashboard/) ─────────────────
const MOCK_STATS = {
  active_rushes_now: 14,
  rushes_completed_today: 82,
  avg_rush_completion_rate: 71.4,
  overdrive_clashes_today: 37,
  active_rivalries: 218,
  chests_opened_today: 543,
  legendary_chests_opened_today: 12,
  comeback_activations_today: 29,
  avg_duel_duration_seconds: 148,
  sabotage_strikes_today: 94,
  total_clans: 1342,
  total_clan_members: 6720,
};

const RECENT_EVENTS = [
  { id: 1, icon: "⚡", text: "Evening Sprint rush completed — Gold tier reached!", clan: "Sakura Storm", time: "2m ago", severity: "success" },
  { id: 2, icon: "⚔️", text: "Overdrive Clash triggered — 2x multiplier active", clan: "Iron Samurai", time: "5m ago", severity: "warning" },
  { id: 3, icon: "🗡️", text: "Knife strike landed — -150 BP dealt", clan: "Shadow Dojo", time: "8m ago", severity: "danger" },
  { id: 4, icon: "🔥", text: "Comeback Protocol activated — player was 40% down", clan: "Thunder Dojo", time: "11m ago", severity: "info" },
  { id: 5, icon: "🎁", text: "Legendary chest opened — Crimson Aura cosmetic awarded", clan: "Ninja Protocol", time: "14m ago", severity: "success" },
  { id: 6, icon: "🌙", text: "New clan created — Shadow Dojo #SD42", clan: "System", time: "20m ago", severity: "neutral" },
];

// Animated counter hook
function useCountUp(target, duration = 1200) {
  const [value, setValue] = useState(0);
  useEffect(() => {
    let start = 0;
    const steps = 60;
    const inc = target / steps;
    const interval = setInterval(() => {
      start += inc;
      if (start >= target) {
        setValue(target);
        clearInterval(interval);
      } else {
        setValue(Math.floor(start));
      }
    }, duration / steps);
    return () => clearInterval(interval);
  }, [target, duration]);
  return value;
}

// KPI Card with count-up
function KpiCard({ icon, label, value, sub, color, trend, to }) {
  const animated = useCountUp(typeof value === "number" ? value : 0);
  const display = typeof value === "number" ? animated : value;

  return (
    <Link to={to || "#"} className="kpi-card" style={{ "--accent": color }}>
      <div className="kpi-icon">{icon}</div>
      <div className="kpi-meta">
        <span className="kpi-value">
          {typeof value === "number"
            ? Number.isInteger(value)
              ? display.toLocaleString()
              : parseFloat(display).toFixed(1)
            : value}
        </span>
        <span className="kpi-label">{label}</span>
        {sub && <span className="kpi-sub">{sub}</span>}
      </div>
      {trend !== undefined && (
        <div className={`kpi-trend ${trend >= 0 ? "up" : "down"}`}>
          {trend >= 0 ? "▲" : "▼"} {Math.abs(trend)}%
        </div>
      )}
    </Link>
  );
}

// Live event feed
function EventFeed({ events }) {
  return (
    <div className="event-feed">
      {events.map((e) => (
        <div key={e.id} className={`event-item sev-${e.severity}`}>
          <span className="event-icon">{e.icon}</span>
          <div className="event-body">
            <span className="event-text">{e.text}</span>
            <span className="event-clan">{e.clan}</span>
          </div>
          <span className="event-time">{e.time}</span>
        </div>
      ))}
    </div>
  );
}

// Mini rush-completion arc
function RushArc({ pct }) {
  const r = 44;
  const circ = 2 * Math.PI * r;
  const dash = (pct / 100) * circ;

  return (
    <svg width="110" height="110" viewBox="0 0 110 110">
      <circle cx="55" cy="55" r={r} stroke="#ffffff0d" strokeWidth="10" fill="none" />
      <circle
        cx="55"
        cy="55"
        r={r}
        stroke="url(#rushGrad)"
        strokeWidth="10"
        fill="none"
        strokeDasharray={`${dash} ${circ}`}
        strokeLinecap="round"
        transform="rotate(-90 55 55)"
      />
      <defs>
        <linearGradient id="rushGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stopColor="#eb4b6e" />
          <stop offset="100%" stopColor="#ffd700" />
        </linearGradient>
      </defs>
      <text x="55" y="51" textAnchor="middle" fill="#fff" fontSize="18" fontWeight="900">
        {pct}%
      </text>
      <text x="55" y="66" textAnchor="middle" fill="#ffffff66" fontSize="9">
        completion
      </text>
    </svg>
  );
}

// Main dashboard
export default function ClanDashboard() {
  const [stats] = useState(MOCK_STATS);
  const [liveTime, setLiveTime] = useState(new Date());
  const [rushEvents] = useState(RECENT_EVENTS);
  const [pulseRush, setPulseRush] = useState(false);
  const pulseTimer = useRef();

  useEffect(() => {
    const t = setInterval(() => setLiveTime(new Date()), 1000);
    // Simulate a new rush starting
    pulseTimer.current = setTimeout(() => setPulseRush(true), 3000);
    return () => {
      clearInterval(t);
      clearTimeout(pulseTimer.current);
    };
  }, []);

  const fmt = (n) => n?.toLocaleString() ?? "—";
  const secs = (n) => `${Math.floor(n / 60)}m ${n % 60}s`;

  return (
    <div className="clan-dashboard">
      {/* ── Header ────────────────────────────────────────────────── */}
      <div className="dash-header">
        <div>
          <h1 className="dash-title">⛩️ Clan Command Center</h1>
          <p className="dash-sub">
            Real-time metrics across all {fmt(stats.total_clans)} active clans
          </p>
        </div>
        <div className="dash-header-right">
          <div className="live-badge">
            <span className="live-dot" />
            LIVE
          </div>
          <span className="live-time">{liveTime.toLocaleTimeString()}</span>
          <Link to="/clan/config/rush" className="btn-config">
            ⚙️ Rush Config
          </Link>
          <Link to="/clan/config/duel" className="btn-config">
            ⚙️ Duel Config
          </Link>
        </div>
      </div>

      {/* ── Active Rush Alert ─────────────────────────────────────── */}
      {pulseRush && (
        <div className="rush-alert">
          <span className="rush-alert-icon">⚡</span>
          <span>
            <strong>14 active rushes</strong> in progress right now — some ending in &lt;5 min!
          </span>
          <Link to="/clan/rushes" className="rush-alert-link">
            View All →
          </Link>
        </div>
      )}

      {/* ── KPI Grid ──────────────────────────────────────────────── */}
      <div className="kpi-grid">
        <KpiCard icon="⚡" label="Active Rushes" value={stats.active_rushes_now} color="#eb4b6e" trend={12} to="/clan/rushes" />
        <KpiCard icon="✅" label="Rushes Completed Today" value={stats.rushes_completed_today} color="#ffd700" to="/clan/rushes" />
        <KpiCard icon="🔥" label="Avg Rush Completion" value={stats.avg_rush_completion_rate} sub="%" color="#f59e0b" to="/clan/config/rush" />
        <KpiCard icon="⚔️" label="Overdrive Clashes" value={stats.overdrive_clashes_today} color="#8b5cf6" trend={-3} to="/clan/battles" />
        <KpiCard icon="🌙" label="Active Rivalries" value={stats.active_rivalries} color="#06b6d4" to="/clan/rivals" />
        <KpiCard icon="🎁" label="Chests Opened" value={stats.chests_opened_today} color="#10b981" to="/clan/chests" />
        <KpiCard icon="💎" label="Legendary Drops" value={stats.legendary_chests_opened_today} color="#a855f7" to="/clan/chests" />
        <KpiCard icon="🔄" label="Comeback Activations" value={stats.comeback_activations_today} color="#ef4444" to="/clan/config/comeback" />
        <KpiCard icon="⏱️" label="Avg Duel Duration" value={secs(stats.avg_duel_duration_seconds)} color="#64748b" />
        <KpiCard icon="🗡️" label="Sabotage Strikes" value={stats.sabotage_strikes_today} color="#dc2626" to="/clan/battles" />
        <KpiCard icon="🏯" label="Total Clans" value={stats.total_clans} color="#78716c" to="/clan/clans" />
        <KpiCard icon="👥" label="Total Members" value={stats.total_clan_members} color="#0ea5e9" to="/clan/clans" />
      </div>

      {/* ── Middle Section ────────────────────────────────────────── */}
      <div className="dash-mid">
        {/* Rush completion arc */}
        <div className="dash-card arc-card">
          <h3 className="card-title">Rush Completion Rate</h3>
          <p className="card-sub">Average across all today's completed rushes</p>
          <div className="arc-center">
            <RushArc pct={Math.round(stats.avg_rush_completion_rate)} />
          </div>
          <div className="arc-stats">
            <div className="arc-stat">
              <span className="arc-stat-val">{stats.rushes_completed_today}</span>
              <span className="arc-stat-label">Completed</span>
            </div>
            <div className="arc-stat">
              <span className="arc-stat-val">{stats.active_rushes_now}</span>
              <span className="arc-stat-label">In Progress</span>
            </div>
          </div>
        </div>

        {/* Event feed */}
        <div className="dash-card feed-card">
          <div className="card-header-row">
            <h3 className="card-title">Live Event Feed</h3>
            <span className="feed-badge">{rushEvents.length} events</span>
          </div>
          <EventFeed events={rushEvents} />
        </div>

        {/* Quick actions */}
        <div className="dash-card action-card">
          <h3 className="card-title">Quick Actions</h3>
          <div className="action-list">
            <Link to="/clan/config/rush" className="action-btn">
              <span>⚡</span>
              <div>
                <strong>Trigger Manual Rush</strong>
                <small>Fire a rush for a specific clan</small>
              </div>
            </Link>
            <Link to="/clan/config/duel" className="action-btn">
              <span>⚔️</span>
              <div>
                <strong>Edit Duel Config</strong>
                <small>Tune fill rates, steal %, overdrive</small>
              </div>
            </Link>
            <Link to="/clan/config/chests" className="action-btn">
              <span>🎁</span>
              <div>
                <strong>Reward Chest Pools</strong>
                <small>Adjust drop weights per tier</small>
              </div>
            </Link>
            <Link to="/clan/config/comeback" className="action-btn">
              <span>🔥</span>
              <div>
                <strong>Comeback Protocol</strong>
                <small>Set BP threshold &amp; boost mult</small>
              </div>
            </Link>
            <Link to="/clan/config/rivals" className="action-btn">
              <span>🌙</span>
              <div>
                <strong>Rival System</strong>
                <small>Configure auto-rival assignment</small>
              </div>
            </Link>
            <Link to="/clan/config/global" className="action-btn">
              <span>⚙️</span>
              <div>
                <strong>Global Settings</strong>
                <small>Creation requirements, slots, naming</small>
              </div>
            </Link>
          </div>
        </div>
      </div>

      {/* ── Data table links ──────────────────────────────────────── */}
      <div className="dash-tables">
        {[
          { to: "/clan/clans", icon: "🏯", label: "All Clans" },
          { to: "/clan/battles", icon: "⚔️", label: "Battle Log" },
          { to: "/clan/rushes", icon: "⚡", label: "Rush History" },
          { to: "/clan/chests", icon: "🎁", label: "Chest Log" },
          { to: "/clan/rivals", icon: "🌙", label: "Rival Pairs" },
        ].map((t) => (
          <Link key={t.to} to={t.to} className="table-link">
            <span>{t.icon}</span>
            {t.label}
            <span className="link-arrow">→</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
