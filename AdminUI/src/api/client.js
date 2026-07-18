import axios from 'axios';

const BASE = 'https://jback2.zynix.us/api';

const api = axios.create({ baseURL: BASE });

// Attach token to every request
api.interceptors.request.use(cfg => {
  const token = localStorage.getItem('access_token');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  if (cfg.data instanceof FormData) {
    delete cfg.headers['Content-Type'];
  }
  return cfg;
});

// Auto-refresh on 401
api.interceptors.response.use(
  r => r,
  async err => {
    const orig = err.config;
    if (err.response?.status === 401 && !orig._retry) {
      orig._retry = true;
      try {
        const refresh = localStorage.getItem('refresh_token');
        const { data } = await axios.post(`${BASE}/auth/token/refresh/`, { refresh });
        localStorage.setItem('access_token', data.access);
        orig.headers.Authorization = `Bearer ${data.access}`;
        return api(orig);
      } catch {
        localStorage.clear();
        window.location.href = '/login';
      }
    }
    return Promise.reject(err);
  }
);

// ── Auth ──────────────────────────────────────────────────────────────────────
export const login    = d => api.post('/auth/login/', d);
export const me       = ()  => api.get('/auth/me/');
export const register = d => api.post('/auth/register/', d);
export const allUsers = ()  => api.get('/auth/admin/users/');
export const assignRole = (userId, role) =>
  api.post(`/auth/admin/users/${userId}/assign-role/`, { role });

export const updateUser = (userId, d) => api.patch(`/auth/admin/users/${userId}/`, d);
export const deleteUser = (userId) => api.delete(`/auth/admin/users/${userId}/`);
export const resetUserPassword = (userId, d) => api.post(`/auth/admin/users/${userId}/reset-password/`, d || {});

// ── Exams ─────────────────────────────────────────────────────────────────────
export const getAdminExams  = ()     => api.get('/courses/admin/exams/');
export const createExam     = d      => api.post('/courses/admin/exams/', d);
export const updateExam     = (id,d) => api.patch(`/courses/admin/exams/${id}/`, d);
export const deleteExam     = id     => api.delete(`/courses/admin/exams/${id}/`);

// ── Categories ────────────────────────────────────────────────────────────────
export const getCategories  = examId => api.get('/courses/admin/categories/', { params: { exam: examId } });
export const createCategory = d      => api.post('/courses/admin/categories/', d);
export const updateCategory = (id,d) => api.patch(`/courses/admin/categories/${id}/`, d);
export const deleteCategory = id     => api.delete(`/courses/admin/categories/${id}/`);

// ── Lessons ───────────────────────────────────────────────────────────────────
export const getLessons    = catId => api.get('/courses/admin/lessons/', { params: { category: catId } });
export const getLessonDetail = id => api.get(`/courses/admin/lessons/${id}/`);
export const createLesson  = d     => api.post('/courses/admin/lessons/', d);
export const updateLesson  = (id,d) => api.patch(`/courses/admin/lessons/${id}/`, d);
export const deleteLesson  = id    => api.delete(`/courses/admin/lessons/${id}/`);

// ── Study Import ──────────────────────────────────────────────────────────────
export const downloadStudyTemplate = lessonId =>
  api.get(`/courses/admin/lessons/${lessonId}/study-import/`, { responseType: 'blob' });
export const importStudy = (lessonId, file) => {
  const fd = new FormData();
  fd.append('file', file);
  return api.post(`/courses/admin/lessons/${lessonId}/study-import/`, fd);
};

export const deleteStudyItems = ids => api.post('/courses/admin/study-items/bulk-delete/', { ids });

// ── Question Banks ────────────────────────────────────────────────────────────
export const getBanks       = lessonId => api.get(`/courses/admin/lessons/${lessonId}/banks/`);
export const createBank     = (lessonId, d) => api.post(`/courses/admin/lessons/${lessonId}/banks/`, d);
export const getBankDetail  = id       => api.get(`/courses/admin/banks/${id}/`);
export const updateBank     = (id, d)  => api.patch(`/courses/admin/banks/${id}/`, d);
export const deleteBank     = id       => api.delete(`/courses/admin/banks/${id}/`);
export const downloadBankTemplate = bankId =>
  api.get(`/courses/admin/banks/${bankId}/import/`, { responseType: 'blob' });
export const importBank = (bankId, file) => {
  const fd = new FormData();
  fd.append('file', file);
  return api.post(`/courses/admin/banks/${bankId}/import/`, fd);
};

// ── Institutions ─────────────────────────────────────────────────────────────
export const getInstitutions = () => api.get('/institutions/');
export const createInstitution = d => api.post('/institutions/', d);
export const getInstitution = id => api.get(`/institutions/${id}/`);
export const updateInstitution = (id, d) => api.patch(`/institutions/${id}/`, d);
export const getInstitutionStudents = institutionId => api.get(`/auth/admin/users/?institution_id=${institutionId}`);
export const getInstitutionMentors = institutionId => api.get(`/institutions/${institutionId}/mentors/`);
export const getInstitutionAssignments = institutionId => api.get(`/institutions/${institutionId}/assignments/`);
export const assignMentor = (institutionId, studentId, mentorId) =>
  api.post(`/institutions/${institutionId}/assignments/`, { student_id: studentId, mentor_id: mentorId });
export const deleteMentorAssignment = assignmentId => api.delete(`/institutions/assignments/${assignmentId}/`);

// ── Announcements ───────────────────────────────────────────────────────────
export const getAnnouncements = () => api.get('/announcements/');
export const createAnnouncement = d => api.post('/announcements/', d);
export const updateAnnouncement = (id, d) => api.patch(`/announcements/${id}/`, d);

export default api;
