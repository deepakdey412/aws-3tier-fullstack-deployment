import { useState, useEffect } from 'react'

function ItemForm({ onSubmit, editingItem, onCancel }) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    quantity: ''
  })

  useEffect(() => {
    if (editingItem) {
      setFormData({
        name: editingItem.name,
        description: editingItem.description,
        quantity: editingItem.quantity
      })
    } else {
      setFormData({
        name: '',
        description: '',
        quantity: ''
      })
    }
  }, [editingItem])

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: name === 'quantity' ? parseInt(value) || '' : value
    }))
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    onSubmit(formData)
    if (!editingItem) {
      setFormData({ name: '', description: '', quantity: '' })
    }
  }

  return (
    <div className="form-card">
      <h2>{editingItem ? '✏️ Edit Item' : '➕ Add New Item'}</h2>
      <form onSubmit={handleSubmit} className="item-form">
        <div className="form-group">
          <label htmlFor="name">Item Name *</label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
            placeholder="Enter item name"
          />
        </div>

        <div className="form-group">
          <label htmlFor="description">Description *</label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleChange}
            required
            placeholder="Enter item description"
          />
        </div>

        <div className="form-group">
          <label htmlFor="quantity">Quantity *</label>
          <input
            type="number"
            id="quantity"
            name="quantity"
            value={formData.quantity}
            onChange={handleChange}
            required
            min="0"
            placeholder="Enter quantity"
          />
        </div>

        <div className="form-actions">
          <button type="submit" className="btn btn-primary">
            {editingItem ? '💾 Update Item' : '➕ Add Item'}
          </button>
          {editingItem && (
            <button type="button" onClick={onCancel} className="btn btn-secondary">
              ✖️ Cancel
            </button>
          )}
        </div>
      </form>
    </div>
  )
}

export default ItemForm
