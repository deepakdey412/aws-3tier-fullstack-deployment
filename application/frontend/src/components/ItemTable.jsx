function ItemTable({ items, onEdit, onDelete }) {
  if (items.length === 0) {
    return (
      <div className="empty-state">
        <p>📦 No items found</p>
        <p style={{ fontSize: '0.9rem', marginTop: '0.5rem' }}>
          Add your first item using the form above
        </p>
      </div>
    )
  }

  return (
    <div className="table-container">
      <table className="items-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Description</th>
            <th>Quantity</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {items.map(item => (
            <tr key={item.id}>
              <td>{item.id}</td>
              <td>{item.name}</td>
              <td>{item.description}</td>
              <td>{item.quantity}</td>
              <td>
                <div className="item-actions">
                  <button
                    onClick={() => onEdit(item)}
                    className="btn btn-edit"
                  >
                    ✏️ Edit
                  </button>
                  <button
                    onClick={() => onDelete(item.id)}
                    className="btn btn-danger"
                  >
                    🗑️ Delete
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default ItemTable
