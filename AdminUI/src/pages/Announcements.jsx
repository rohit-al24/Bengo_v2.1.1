import React, { useEffect, useMemo, useRef, useState } from 'react';
import { createAnnouncement, getAnnouncements, updateAnnouncement } from '../api/client';

const emptyForm = {
  title: '',
  description: '',
  link_enabled: false,
  link_url: '',
  button_text: 'Learn more',
  is_active: true,
};

export default function Announcements() {
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(emptyForm);
  const [imageFile, setImageFile] = useState(null);
  const [editingId, setEditingId] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const imageInputRef = useRef(null);

  const loadAnnouncements = async () => {
    try {
      setLoading(true);
      const res = await getAnnouncements();
      setAnnouncements(res.data || []);
    } catch (err) {
      setError('Could not load announcements.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAnnouncements();
  }, []);

  const { activeAnnouncements, inactiveAnnouncements } = useMemo(() => ({
    activeAnnouncements: announcements.filter(item => item.is_active),
    inactiveAnnouncements: announcements.filter(item => !item.is_active),
  }), [announcements]);

  const resetForm = () => {
    setForm(emptyForm);
    setImageFile(null);
    setEditingId(null);
    if (imageInputRef.current) imageInputRef.current.value = '';
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');

    try {
      const fd = new FormData();
      fd.append('title', form.title);
      fd.append('description', form.description);
      fd.append('is_active', String(form.is_active));
      fd.append('link_enabled', String(form.link_enabled));
      fd.append('button_text', form.button_text || 'Learn more');
      if (form.link_url) fd.append('link_url', form.link_url);
      if (imageFile) fd.append('image', imageFile);

      if (editingId) {
        await updateAnnouncement(editingId, fd);
      } else {
        await createAnnouncement(fd);
      }
      resetForm();
      await loadAnnouncements();
    } catch (err) {
      setError(editingId ? 'Unable to update announcement.' : 'Unable to create announcement.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggle = async (announcement) => {
    try {
      await updateAnnouncement(announcement.id, { is_active: !announcement.is_active });
      await loadAnnouncements();
    } catch (err) {
      setError('Unable to update announcement.');
    }
  };

  const handleEdit = (announcement) => {
    setEditingId(announcement.id);
    setForm({
      title: announcement.title || '',
      description: announcement.description || '',
      link_enabled: Boolean(announcement.link_enabled),
      link_url: announcement.link_url || '',
      button_text: announcement.button_text || 'Learn more',
      is_active: Boolean(announcement.is_active),
    });
    setImageFile(null);
    if (imageInputRef.current) imageInputRef.current.value = '';
  };

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h2 style={{ margin: 0 }}>Announcements</h2>
          <p style={{ margin: '4px 0 0', color: '#666' }}>Publish updates for learners and keep the mobile dashboard fresh.</p>
        </div>
      </div>

      {error ? <div style={{ marginBottom: 12, color: '#b91c1c' }}>{error}</div> : null}

      <div style={{ display: 'grid', gridTemplateColumns: '1.1fr 0.9fr', gap: 20, alignItems: 'start' }}>
        <div style={{ background: '#fff', borderRadius: 16, padding: 20, boxShadow: '0 10px 30px rgba(0,0,0,0.06)' }}>
          <h3 style={{ marginTop: 0 }}>{editingId ? 'Edit announcement' : 'Create announcement'}</h3>
          <form onSubmit={handleSubmit} style={{ display: 'grid', gap: 12 }}>
            <input
              placeholder="Title"
              value={form.title}
              onChange={e => setForm({ ...form, title: e.target.value })}
              required
              style={inputStyle}
            />
            <textarea
              placeholder="Description"
              rows={4}
              value={form.description}
              onChange={e => setForm({ ...form, description: e.target.value })}
              required
              style={{ ...inputStyle, minHeight: 92, resize: 'vertical' }}
            />
            <input
              ref={imageInputRef}
              id="announcement-image"
              type="file"
              accept="image/*"
              onChange={e => setImageFile(e.target.files?.[0] || null)}
              style={inputStyle}
            />
            <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />
              Publish immediately
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <input type="checkbox" checked={form.link_enabled} onChange={e => setForm({ ...form, link_enabled: e.target.checked })} />
              Add call-to-action link
            </label>
            {form.link_enabled ? (
              <>
                <input
                  placeholder="Link URL"
                  value={form.link_url}
                  onChange={e => setForm({ ...form, link_url: e.target.value })}
                  style={inputStyle}
                />
                <input
                  placeholder="Button text"
                  value={form.button_text}
                  onChange={e => setForm({ ...form, button_text: e.target.value })}
                  style={inputStyle}
                />
              </>
            ) : null}
            <div style={{ display: 'flex', gap: 8 }}>
              <button type="submit" disabled={submitting} style={buttonStyle}>
                {submitting ? 'Saving...' : editingId ? 'Update announcement' : 'Save announcement'}
              </button>
              {editingId ? (
                <button type="button" onClick={resetForm} style={secondaryButtonStyle}>
                  Cancel
                </button>
              ) : null}
            </div>
          </form>
        </div>

        <div style={{ display: 'grid', gap: 16 }}>
          <Section title="Active" items={activeAnnouncements} onToggle={handleToggle} onEdit={handleEdit} />
          <Section title="Inactive" items={inactiveAnnouncements} onToggle={handleToggle} onEdit={handleEdit} />
        </div>
      </div>

      {loading ? <p style={{ color: '#666' }}>Loading announcements…</p> : null}
    </div>
  );
}

function Section({ title, items, onToggle, onEdit }) {
  return (
    <div style={{ background: '#fff', borderRadius: 16, padding: 16, boxShadow: '0 10px 30px rgba(0,0,0,0.06)' }}>
      <h3 style={{ marginTop: 0 }}>{title}</h3>
      {items.length === 0 ? <p style={{ color: '#666' }}>No announcements yet.</p> : (
        <div style={{ display: 'grid', gap: 10 }}>
          {items.map(item => (
            <div key={item.id} style={{ border: '1px solid #eee', borderRadius: 12, padding: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
                <strong>{item.title}</strong>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button onClick={() => onEdit(item)} style={secondaryButtonStyle}>
                    Edit
                  </button>
                  <button onClick={() => onToggle(item)} style={secondaryButtonStyle}>
                    {item.is_active ? 'Deactivate' : 'Activate'}
                  </button>
                </div>
              </div>
              <p style={{ margin: '6px 0', color: '#555' }}>{item.description}</p>
              {item.image ? <img src={item.image} alt={item.title} style={{ width: '100%', maxHeight: 120, objectFit: 'cover', borderRadius: 8 }} /> : null}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

const inputStyle = {
  width: '100%',
  padding: '10px 12px',
  borderRadius: 10,
  border: '1px solid #ddd',
  fontSize: 14,
};

const buttonStyle = {
  padding: '10px 14px',
  borderRadius: 10,
  border: 'none',
  background: '#c41230',
  color: '#fff',
  cursor: 'pointer',
  fontWeight: 700,
};

const secondaryButtonStyle = {
  padding: '6px 10px',
  borderRadius: 8,
  border: '1px solid #c41230',
  background: '#fff',
  color: '#c41230',
  cursor: 'pointer',
};
