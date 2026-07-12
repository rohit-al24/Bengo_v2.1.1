import React, { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { downloadStudyTemplate, importStudy, deleteStudyItems } from '../../api/client';
import api from '../../api/client';

export default function LessonEditor() {
  const { examId, catId, lessonId } = useParams();
  const [lesson,     setLesson]     = useState(null);
  const [studyItems, setStudyItems] = useState([]);
  const [selectedItemIds, setSelectedItemIds] = useState([]);
  const [importing,  setImporting]  = useState(false);
  const [showModal,  setShowModal]  = useState(false);
  const [msg,        setMsg]        = useState('');
  const fileRef = useRef();

  const loadLesson = () =>
    api.get(`/courses/lessons/${lessonId}/study/`).then(r => {
      setLesson(r.data.lesson);
      setStudyItems(r.data.study_items);
    }).catch(() => {
      // Might be locked for current user; try admin detail
      api.get(`/courses/admin/lessons/`, { params: { category: catId } })
         .then(r => setLesson(r.data.find(l => String(l.id) === lessonId)));
    });

  useEffect(() => { loadLesson(); }, [lessonId]);

  const toggleItemSelection = id => {
    setSelectedItemIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  };

  const toggleSelectAllItems = () => {
    if (selectedItemIds.length === studyItems.length) setSelectedItemIds([]);
    else setSelectedItemIds(studyItems.map(i => i.id));
  };

  const bulkDeleteSelected = async () => {
    if (selectedItemIds.length === 0) return;
    if (!window.confirm(`Delete ${selectedItemIds.length} selected item(s)?`)) return;
    try {
      await deleteStudyItems(selectedItemIds);
      setSelectedItemIds([]);
      loadLesson();
      setMsg(`✅ Deleted ${selectedItemIds.length} items.`);
    } catch (e) {
      setMsg('❌ Delete failed: ' + JSON.stringify(e.response?.data));
    }
  };

  const downloadTemplate = async () => {
    const res = await downloadStudyTemplate(lessonId);
    const url = URL.createObjectURL(new Blob([res.data]));
    const a   = document.createElement('a');
    a.href = url;
    // filename based on lesson type and category show type
    if (lesson?.category_show_type === 'topic_wise' && lesson?.lesson_type === 'study') a.download = 'topic_wise_template.xlsx';
    else if (lesson?.lesson_type === 'exam') a.download = 'exam_template.xlsx';
    else a.download = 'study_template.xlsx';
    a.click();
  };

  const handleImport = async file => {
    if (!file) return;
    setImporting(true); setMsg('');
    try {
      const res = await importStudy(lessonId, file);
      setMsg(`✅ Imported ${res.data.created} rows successfully.`);
      loadLesson();
    } catch (e) {
      setMsg('❌ Import failed: ' + JSON.stringify(e.response?.data));
    } finally {
      setImporting(false); setShowModal(false);
    }
  };

  let requiredColumns = '';
  if (lesson?.category_show_type === 'topic_wise' && lesson?.lesson_type === 'study') {
    requiredColumns = 'target | exp1 | exp2 | exp3 | exp4 | exp5 | exp6';
  } else {
    requiredColumns = lesson?.lesson_type === 'exam'
      ? 'target | correct_answer | wrong_1 | wrong_2 | wrong_3'
      : 'target | correct_answer | wrong_1 | wrong_2 | wrong_3';
  }

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/courses">Course Editor</Link> ›{' '}
        <Link to={`/courses/${examId}`}>Exam</Link> ›{' '}
        <Link to={`/courses/${examId}/categories/${catId}`}>Category</Link> ›{' '}
        <span>{lesson?.name || '…'}</span>
      </div>

        <div className="page-header">
        <div>
          <h2>📝 {lesson?.name}</h2>
          {lesson && (
            <p style={{ fontSize:13, color:'var(--text-muted)', marginTop:4 }}>
              Type: <b>{lesson.lesson_type}</b> · Show: <b>{lesson.show_type}</b> ·
              Test Source: <b>{lesson.test_source}</b>
              <span style={{ marginLeft:12, color:'var(--primary)', fontWeight:600 }}>
                ⏱ Timer &amp; pass % set in <a href="/ranks" style={{ color:'var(--primary)' }}>Ranks →</a>
              </span>
            </p>
          )}
        </div>
        <div style={{ display:'flex', gap:8, alignItems:'center' }}>
          {selectedItemIds.length > 0 && (
            <button className="btn btn-secondary" onClick={bulkDeleteSelected}>🗑️ Delete Selected ({selectedItemIds.length})</button>
          )}
          <button className="btn btn-primary" onClick={() => setShowModal(true)}>
            📥 Import Study Content
          </button>
        </div>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      {/* Study Items Table */}
      <div className="table-wrap">
          <table>
            <thead>
              <tr>
              <th><input type="checkbox" checked={studyItems.length > 0 && selectedItemIds.length === studyItems.length} onChange={toggleSelectAllItems} /></th>
                <th>#</th>
                <th>Target (Japanese)</th>
                {lesson?.category_show_type === 'topic_wise' ? (
                  (lesson?.lesson_type === 'study' ? (
                    <>
                      <th>Exp 1</th>
                      <th>Exp 2</th>
                      <th>Exp 3</th>
                      <th>Exp 4</th>
                      <th>Exp 5</th>
                      <th>Exp 6</th>
                    </>
                  ) : (
                    <>
                      <th>Correct Answer</th>
                      <th>Wrong 1</th>
                      <th>Wrong 2</th>
                      <th>Wrong 3</th>
                    </>
                  ))
                ) : (
                  <>
                    <th>Correct Answer</th>
                    <th>Wrong 1</th>
                    <th>Wrong 2</th>
                    <th>Wrong 3</th>
                    {lesson?.lesson_type === 'exam' && <th>Wrong 4</th>}
                  </>
                )}
              </tr>
            </thead>
            <tbody>
              {studyItems.map((item, i) => (
                <tr key={item.id}>
                  <td><input type="checkbox" checked={selectedItemIds.includes(item.id)} onChange={() => toggleItemSelection(item.id)} /></td>
                  <td>{i+1}</td>
                  <td style={{ fontWeight:600, fontSize:16 }}>{item.target}</td>
                  {lesson?.category_show_type === 'topic_wise' && lesson?.lesson_type === 'study' ? (
                    <>
                      <td style={{ color:'var(--text-muted)' }}>{item.exp1}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.exp2}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.exp3}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.exp4}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.exp5}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.exp6}</td>
                    </>
                  ) : (
                    <>
                      <td style={{ color:'var(--green)', fontWeight:600 }}>{item.correct_answer}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.wrong_1}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.wrong_2}</td>
                      <td style={{ color:'var(--text-muted)' }}>{item.wrong_3}</td>
                    </>
                  )}
                </tr>
              ))}
              {studyItems.length === 0 && (
                <tr>
                  <td colSpan={(lesson?.category_show_type === 'topic_wise' && lesson?.lesson_type === 'study') ? 8 : (lesson?.lesson_type === 'exam' ? 7 : 6)} style={{ textAlign:'center', color:'var(--text-muted)', padding:40 }}>
                    No study content yet. Import an Excel file to add content.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Import Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>📥 Import Study Content</h3>
              <button className="btn btn-icon" onClick={() => setShowModal(false)}>✕</button>
            </div>

            <div style={{ background:'#F6F9FF', borderRadius:10, padding:16, marginBottom:16 }}>
              <p style={{ fontSize:13, marginBottom:8 }}>
                Excel columns required: <code>{requiredColumns}</code>
              </p>
              <button className="btn btn-secondary btn-sm" onClick={downloadTemplate}>
                ⬇️ Download Template
              </button>
            </div>

            <div className="form-group">
              <label>Upload Filled Excel File (.xlsx)</label>
              <input
                type="file" accept=".xlsx,.xls"
                ref={fileRef}
                style={{ padding:'10px', background:'#F6F9FF', border:'2px dashed var(--border)', borderRadius:10 }}
              />
            </div>

            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
              <button
                className="btn btn-primary"
                disabled={importing}
                onClick={() => handleImport(fileRef.current?.files?.[0])}
              >
                {importing ? 'Importing…' : 'Import'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
