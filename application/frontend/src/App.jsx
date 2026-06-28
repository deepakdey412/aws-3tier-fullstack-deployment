import { useState } from 'react'
import ItemForm from './components/ItemForm'
import ItemTable from './components/ItemTable'
import SearchBar from './components/SearchBar'
import useItems from './hooks/useItems'

function App() {
  const { items, loading, error, fetchItems, createItem, updateItem, deleteItem } = useItems()
  const [editingItem, setEditingItem] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')

  const handleSubmit = async (itemData) => {
    if (editingItem) {
      await updateItem(editingItem.id, itemData)
      setEditingItem(null)
    } else {
      await createItem(itemData)
    }
  }

  const handleEdit = (item) => {
    setEditingItem(item)
  }

  const handleCancelEdit = () => {
    setEditingItem(null)
  }

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this item?')) {
      await deleteItem(id)
    }
  }

  const handleSearch = (term) => {
    setSearchTerm(term)
  }

  const filteredItems = items.filter(item =>
    item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.description.toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="app">
      <header className="app-header">
        <h1>📦 Inventory Management System</h1>
        <p>AWS 3-Tier Full-Stack Application</p>
      </header>

      <main className="app-main">
        <div className="container">
          <ItemForm
            onSubmit={handleSubmit}
            editingItem={editingItem}
            onCancel={handleCancelEdit}
          />

          <div className="items-section">
            <SearchBar onSearch={handleSearch} />
            
            {error && <div className="error-message">{error}</div>}
            
            {loading ? (
              <div className="loading">Loading items...</div>
            ) : (
              <ItemTable
                items={filteredItems}
                onEdit={handleEdit}
                onDelete={handleDelete}
              />
            )}
          </div>
        </div>
      </main>

      <footer className="app-footer">
        <p>Built with React + Spring Boot + MySQL | Deployed on AWS</p>
      </footer>
    </div>
  )
}

export default App
