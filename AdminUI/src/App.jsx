import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login           from './pages/Login';
import Layout          from './components/Layout';
import Dashboard       from './pages/Dashboard';
import ExamList        from './pages/CourseEditor/ExamList';
import ExamDetail      from './pages/CourseEditor/ExamDetail';
import CategoryDetail  from './pages/CourseEditor/CategoryDetail';
import LessonEditor    from './pages/CourseEditor/LessonEditor';
import QuestionBank    from './pages/CourseEditor/QuestionBank';
import UserManagement  from './pages/UserManagement';
import Institutions     from './pages/Institutions';
import InstitutionDetail from './pages/InstitutionDetail';
import InstAdminStudents from './pages/institution_admin/Students';
import InstAdminMentors  from './pages/institution_admin/Mentors';
import InstAdminAuth     from './pages/institution_admin/Authentications';
import RankExamList    from './pages/Ranks/RankExamList';
import ExamRankDetail  from './pages/Ranks/ExamRankDetail';
import XPConfigPage    from './pages/Ranks/XPConfigPage';
import DailyRevisionPage from './pages/DailyRevisionPage';
import CertExamList    from './pages/Certificates/CertExamList';
import CertExamDetail  from './pages/Certificates/CertExamDetail';

function RequireAdmin({ children }) {
  const token = localStorage.getItem('access_token');
  if (!token) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<RequireAdmin><Layout /></RequireAdmin>}>
          <Route index element={<Dashboard />} />
          {/* Course Editor */}
          <Route path="daily-revision" element={<DailyRevisionPage />} />
          <Route path="courses" element={<ExamList />} />
          <Route path="courses/:examId" element={<ExamDetail />} />
          <Route path="courses/:examId/categories/:catId" element={<CategoryDetail />} />
          <Route path="courses/:examId/categories/:catId/lessons/:lessonId" element={<LessonEditor />} />
          <Route path="courses/:examId/categories/:catId/lessons/:lessonId/banks" element={<QuestionBank />} />
          {/* Users */}
          <Route path="users" element={<UserManagement />} />
          <Route path="institutions" element={<Institutions />} />
          <Route path="institutions/:id" element={<InstitutionDetail />} />
          {/* Institution-admin specific pages */}
          <Route path="institution-admin/students" element={<InstAdminStudents />} />
          <Route path="institution-admin/mentors" element={<InstAdminMentors />} />
          <Route path="institution-admin/auth" element={<InstAdminAuth />} />
          {/* Ranks */}
          <Route path="ranks" element={<RankExamList />} />
          <Route path="ranks/:examId" element={<ExamRankDetail />} />
          <Route path="ranks/:examId/:rankId/xp" element={<XPConfigPage />} />
          {/* Certificates */}
          <Route path="certificates" element={<CertExamList />} />
          <Route path="certificates/:examId" element={<CertExamDetail />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
