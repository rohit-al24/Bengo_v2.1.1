import React from 'react'
import {useParams, useNavigate} from 'react-router-dom'

export default function TeamGame(){
  const {teamId} = useParams()
  const navigate = useNavigate()
  return (
    <div className="container">
      <h2>Team Game — {teamId}</h2>
      <div className="card" style={{marginTop:12}}>
        <div>Game UI placeholder: questions, timers, scoring will appear here.</div>
        <div style={{marginTop:12}}>
          <button className="btn" onClick={()=>navigate(`/app/student/team/${teamId}/result`)}>Finish (demo)</button>
        </div>
      </div>
    </div>
  )
}
