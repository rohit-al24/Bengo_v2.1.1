import React from 'react'
import {useParams, Link} from 'react-router-dom'

export default function TeamResult(){
  const {teamId} = useParams()
  return (
    <div className="container">
      <h2>Team Results — {teamId}</h2>
      <div className="card" style={{marginTop:12}}>
        <div>Results placeholder: scoreboard, logs, and exports.</div>
      </div>
      <div style={{marginTop:12}}>
        <Link to="/app/student/team" className="btn">Back to Teams</Link>
      </div>
    </div>
  )
}
