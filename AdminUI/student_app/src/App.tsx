import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import TeamDashboard from './pages/TeamDashboard'
import TeamCreate from './pages/TeamCreate'
import TeamLobby from './pages/TeamLobby'
import TeamGame from './pages/TeamGame'
import TeamResult from './pages/TeamResult'

export default function App() {
  return (
    <Routes>
      <Route path="/app/student/team" element={<TeamDashboard />} />
      <Route path="/app/student/team/create" element={<TeamCreate />} />
      <Route path="/app/student/team/:teamId/lobby" element={<TeamLobby />} />
      <Route path="/app/student/team/:teamId/game" element={<TeamGame />} />
      <Route path="/app/student/team/:teamId/result" element={<TeamResult />} />
      <Route path="/" element={<Navigate to="/app/student/team" replace />} />
    </Routes>
  )
}
