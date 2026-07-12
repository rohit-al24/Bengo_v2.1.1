import React, {useEffect, useState} from 'react'
import {useParams, useNavigate, Link} from 'react-router-dom'
import {getTeam, startTeam, sendInvite} from '../api/team'

export default function TeamLobby(){
  const {teamId} = useParams()
  const [team,setTeam]=useState<any>(null)
  const [inviteName,setInviteName]=useState('')
  const navigate = useNavigate()

  useEffect(()=>{ if(teamId) getTeam(teamId).then(r=>setTeam(r.data)).catch(()=>{}) },[teamId])

  const doStart = async ()=>{
    if(!teamId) return
    await startTeam(teamId)
    navigate(`/app/student/team/${teamId}/game`)
  }

  const doInvite = async ()=>{
    try{
      await sendInvite({team: teamId, to_user: inviteName})
      setInviteName('')
    }catch(e){console.error(e)}
  }

  if(!team) return <div className="container">Loading...</div>
  return (
    <div className="container">
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
        <h2>Lobby — {team.name}</h2>
        <div>
          <button className="btn" onClick={doStart} style={{marginRight:8}}>Start Game</button>
          <Link to="/app/student/team" className="btn">Back</Link>
        </div>
      </div>
      <div style={{marginTop:12}} className="card">
        <div>Members</div>
        <ul>
          {team.members?.map((m:any)=> <li key={m.id}>{m.user}</li>)}
        </ul>
        <div style={{marginTop:12}}>
          <input placeholder="username or id" value={inviteName} onChange={e=>setInviteName(e.target.value)} />
          <button className="btn" onClick={doInvite} style={{marginLeft:8}}>Invite</button>
        </div>
      </div>
    </div>
  )
}
