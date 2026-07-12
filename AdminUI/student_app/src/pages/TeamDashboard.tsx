import React, {useEffect, useState} from 'react'
import {Link} from 'react-router-dom'
import {listTeams} from '../api/team'

export default function TeamDashboard(){
  const [teams, setTeams] = useState<any[]>([])
  useEffect(()=>{listTeams().then(r=>setTeams(r.data)).catch(()=>{})},[])
  return (
    <div className="container">
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
        <h2>Teams</h2>
        <Link to="/app/student/team/create" className="btn">Create Team</Link>
      </div>
      <div style={{marginTop:18}}>
        {teams.length===0?
          <div className="card">No teams yet</div>
          : teams.map(t=> (
            <div key={t.id} className="card" style={{marginTop:12}}>
              <div style={{display:'flex',justifyContent:'space-between'}}>
                <div>
                  <div style={{fontWeight:700,fontSize:16}}>{t.name}</div>
                  <div style={{color:'#9aa4b2',fontSize:13}}>Members: {t.members?.length ?? 0} / {t.max_members}</div>
                </div>
                <div>
                  <Link to={`/app/student/team/${t.id}/lobby`} className="btn">Open</Link>
                </div>
              </div>
            </div>
          ))}
      </div>
    </div>
  )
}
