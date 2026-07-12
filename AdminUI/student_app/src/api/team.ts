import axios from 'axios'

const api = axios.create({ baseURL: import.meta.env.VITE_API_BASE || 'http://localhost:8000/api' })

export const listTeams = () => api.get('/teams/teams/')
export const createTeam = (payload: any) => api.post('/teams/teams/', payload)
export const getTeam = (teamId: string) => api.get(`/teams/teams/${teamId}/`)
export const startTeam = (teamId: string) => api.post(`/teams/teams/${teamId}/start/`)
export const endTeam = (teamId: string) => api.post(`/teams/teams/${teamId}/end/`)
export const sendInvite = (payload: any) => api.post('/teams/invites/', payload)

export default api
