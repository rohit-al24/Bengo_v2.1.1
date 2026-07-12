import React, { useEffect, useState, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import {
  getBanks, createBank, updateBank, deleteBank,
  getBankDetail, downloadBankTemplate, importBank, getLessonDetail, updateLesson,
} from '../../api/client';

export default function QuestionBank() {
  const { examId, catId, lessonId } = useParams();
  const [banks,       setBanks]     = useState([]);
  const [selected,    setSelected]  = useState(null); // bank with questions
  const [addModal,    setAddModal]  = useState(false);
  const [importModal, setImportModal] = useState(null); // bank id
  const [form,        setForm]      = useState({ title:'', questions_count:40 });
  const [lessonConfig, setLessonConfig] = useState({ test_questions_count: 40 });
  const [msg,         setMsg]       = useState('');
  const [savingCount, setSavingCount] = useState(false);
  const fileRef = useRef();

  const load = async () => {
    if (!lessonId) return;
    const [banksRes, lessonRes] = await Promise.all([
      getBanks(lessonId),
      getLessonDetail(lessonId),
    ]);
    setBanks(banksRes.data);
    setLessonConfig({ test_questions_count: lessonRes.data?.test_questions_count ?? 40 });
  };
  useEffect(() => { load(); }, [lessonId]);

  const activeBanks   = banks.filter(b => b.is_active);
  const inactiveBanks = banks.filter(b => !b.is_active);

  const toggleActive = async (bank) => {
    await updateBank(bank.id, { is_active: !bank.is_active });
    load();
    if (selected?.id === bank.id) setSelected(null);
  };

  const removeBank = async id => {
    if (!window.confirm('Delete this bank?')) return;
    await deleteBank(id); load();
    if (selected?.id === id) setSelected(null);
  };

  const saveQuestionCount = async () => {
    try {
      setSavingCount(true);
      await updateLesson(lessonId, { test_questions_count: Math.max(1, Number(lessonConfig.test_questions_count || 1)) });
      setMsg('✅ Test question count saved.');
      await load();
    } catch (e) {
      setMsg('❌ ' + JSON.stringify(e.response?.data));
    } finally {
      setSavingCount(false);
    }
  };

  const saveBank = async () => {
    try {
      await createBank(lessonId, form);
      setAddModal(false); setForm({ title:'', questions_count:40 }); load();
    } catch (e) { alert(JSON.stringify(e.response?.data)); }
  };

  const openBank = async bank => {
    const res = await getBankDetail(bank.id);
    setSelected(res.data);
  };

  const downloadTpl = async bankId => {
    const res = await downloadBankTemplate(bankId);
    const url = URL.createObjectURL(new Blob([res.data]));
    const a = document.createElement('a'); a.href = url; a.download = 'bank_template.xlsx'; a.click();
  };

  const handleImport = async file => {
    if (!file) return;
    setMsg('');
    try {
      const res = await importBank(importModal, file);
      setMsg(`✅ Imported ${res.data.created} questions.`);
      if (selected?.id === importModal) openBank({ id: importModal });
      load();
    } catch (e) { setMsg('❌ ' + JSON.stringify(e.response?.data)); }
    finally { setImportModal(null); }
  };

  const BankGrid = ({ list, title }) => (
    <div style={{ marginBottom:28 }}>
      <div className="section-header">
        <h3>{title} <span style={{ fontSize:12, color:'var(--text-muted)', fontWeight:400 }}>({list.length})</span></h3>
      </div>
      <div className="grid-cards">
        {list.map(b => (
          <div key={b.id} className="card"
               style={{ borderLeft: b.is_active ? '4px solid var(--green)' : '4px solid var(--border)' }}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
              <h4 style={{ fontSize:15, fontWeight:700, cursor:'pointer' }} onClick={() => openBank(b)}>{b.title}</h4>
              <label className="toggle">
                <input type="checkbox" checked={b.is_active} onChange={() => toggleActive(b)} />
                <span className="toggle-slider" />
              </label>
            </div>
            <p style={{ fontSize:12, color:'var(--text-muted)', marginTop:6 }}>
              {b.questions_total} questions · draw {b.questions_count}
            </p>
            <div style={{ display:'flex', gap:8, marginTop:12 }}>
              <button className="btn btn-secondary btn-sm" onClick={() => openBank(b)}>View</button>
              <button className="btn btn-secondary btn-sm" onClick={() => setImportModal(b.id)}>📥 Import</button>
              <button className="btn btn-danger btn-sm" onClick={() => removeBank(b.id)}>🗑️</button>
            </div>
          </div>
        ))}
        {list.length === 0 && (
          <p style={{ color:'var(--text-muted)', fontSize:13 }}>None here.</p>
        )}
      </div>
    </div>
  );

  return (
    <div>
      <div className="breadcrumb">
        <Link to="/courses">Course Editor</Link> ›{' '}
        <Link to={`/courses/${examId}`}>Exam</Link> ›{' '}
        <Link to={`/courses/${examId}/categories/${catId}`}>Category</Link> ›{' '}
        <span>Question Banks</span>
      </div>

      <div className="page-header">
        <h2>🏦 Question Banks</h2>
        <div style={{ display:'flex', gap:10, alignItems:'center' }}>
          <button className="btn btn-primary" onClick={() => setAddModal(true)}>+ Add Bank</button>
        </div>
      </div>

      <div className="card" style={{ marginBottom:18, padding:16 }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', gap:12, flexWrap:'wrap' }}>
          <div>
            <h3 style={{ margin:0, fontSize:16 }}>🧪 Number of Questions for Each Test</h3>
            <p style={{ margin:'4px 0 0', fontSize:12, color:'var(--text-muted)' }}>
              If 2 active banks contain 30 questions each, setting this to 20 will randomly draw 20 questions from the 60 total for each student.
            </p>
          </div>
          <div style={{ display:'flex', gap:8, alignItems:'center' }}>
            <input
              type="number"
              min="1"
              value={lessonConfig.test_questions_count}
              onChange={e => setLessonConfig(f => ({ ...f, test_questions_count: +e.target.value }))}
              style={{ width:120, padding:'8px 10px', borderRadius:8, border:'1px solid var(--border)' }}
            />
            <button className="btn btn-primary btn-sm" onClick={saveQuestionCount} disabled={savingCount}>
              {savingCount ? 'Saving…' : 'Save'}
            </button>
          </div>
        </div>
      </div>

      {msg && <div className={`alert ${msg.startsWith('✅') ? 'alert-success' : 'alert-error'}`}>{msg}</div>}

      {/* Active */}
      <BankGrid list={activeBanks}   title="✅ Active Banks" />
      <BankGrid list={inactiveBanks} title="⛔ Inactive Banks" />

      {/* Bank Questions Panel */}
      {selected && (
        <div className="card" style={{ marginTop:8 }}>
          <div className="section-header">
            <h3>Questions in: {selected.title}</h3>
            <button className="btn btn-icon" onClick={() => setSelected(null)}>✕</button>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>#</th><th>Target</th><th>Correct Answer</th><th>Wrong 1</th><th>Wrong 2</th><th>Wrong 3</th></tr>
              </thead>
              <tbody>
                {selected.questions?.map((q, i) => (
                  <tr key={q.id}>
                    <td>{i+1}</td>
                    <td style={{ fontWeight:600 }}>{q.target}</td>
                    <td style={{ color:'var(--green)', fontWeight:600 }}>{q.correct_answer}</td>
                    <td style={{ color:'var(--text-muted)' }}>{q.wrong_1}</td>
                    <td style={{ color:'var(--text-muted)' }}>{q.wrong_2}</td>
                    <td style={{ color:'var(--text-muted)' }}>{q.wrong_3}</td>
                  </tr>
                ))}
                {(!selected.questions || selected.questions.length === 0) && (
                  <tr><td colSpan={7} style={{ textAlign:'center', color:'var(--text-muted)', padding:24 }}>No questions yet.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Add Bank Modal */}
      {addModal && (
        <div className="modal-overlay" onClick={() => setAddModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Add Question Bank</h3>
              <button className="btn btn-icon" onClick={() => setAddModal(false)}>✕</button>
            </div>
            <div className="form-group">
              <label>Bank Title</label>
              <input value={form.title} onChange={e => setForm(f=>({...f,title:e.target.value}))} placeholder="e.g. Bank A" />
            </div>
            <div className="form-group">
              <label>Questions to Draw for Test</label>
              <input type="number" min={1} value={form.questions_count}
                     onChange={e => setForm(f=>({...f,questions_count:+e.target.value}))} />
              <p style={{ fontSize:11, color:'var(--text-muted)', marginTop:4 }}>
                e.g. 40 = randomly pick 40 questions from this bank's active pool for each test.
              </p>
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setAddModal(false)}>Cancel</button>
              <button className="btn btn-primary" onClick={saveBank}>Create Bank</button>
            </div>
          </div>
        </div>
      )}

      {/* Import Questions Modal */}
      {importModal && (
        <div className="modal-overlay" onClick={() => setImportModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3>📥 Import Questions</h3>
              <button className="btn btn-icon" onClick={() => setImportModal(null)}>✕</button>
            </div>
            <div style={{ background:'#F6F9FF', borderRadius:10, padding:14, marginBottom:14 }}>
              <p style={{ fontSize:13, marginBottom:8 }}>
                Columns: <code>target | correct_answer | wrong_1 | wrong_2 | wrong_3</code>
              </p>
              <button className="btn btn-secondary btn-sm" onClick={() => downloadTpl(importModal)}>
                ⬇️ Download Template
              </button>
            </div>
            <div className="form-group">
              <label>Upload Excel (.xlsx)</label>
              <input type="file" accept=".xlsx,.xls" ref={fileRef}
                     style={{ padding:'10px', background:'#F6F9FF', border:'2px dashed var(--border)', borderRadius:10 }} />
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setImportModal(null)}>Cancel</button>
              <button className="btn btn-primary" onClick={() => handleImport(fileRef.current?.files?.[0])}>Import</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
