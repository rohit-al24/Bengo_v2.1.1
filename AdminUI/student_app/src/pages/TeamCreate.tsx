import React, {useState} from 'react'
import {useNavigate} from 'react-router-dom'
import {createTeam} from '../api/team'

export default function TeamCreate(){
  const [name,setName]=useState('')
  const navigate = useNavigate()
  const submit = async ()=>{
    try{
      const payload = {name, max_members:4, settings: {question_timer:15}}
      const r = await createTeam(payload)
      navigate(`/app/student/team/${r.data.id}/lobby`)
    }catch(e){console.error(e)}
  }
  return (
    <div className="container">
      <h2>Create Team</h2>
      <div className="card" style={{marginTop:12}}>
        <div style={{marginBottom:8}}>Team name</div>
        <input value={name} onChange={e=>setName(e.target.value)} style={{width:'100%',padding:10,borderRadius:8,marginBottom:12}} />
        <div style={{display:'flex',gap:12}}>
          <button className="btn" onClick={submit}>Create</button>
        </div>
      </div>
    </div>
  )
}
