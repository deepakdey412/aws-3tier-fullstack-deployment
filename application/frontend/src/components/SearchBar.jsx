import { useState } from 'react'

function SearchBar({ onSearch }) {
  const [searchTerm, setSearchTerm] = useState('')

  const handleChange = (e) => {
    const value = e.target.value
    setSearchTerm(value)
    onSearch(value)
  }

  return (
    <div className="search-bar">
      <input
        type="text"
        placeholder="🔍 Search items by name or description..."
        value={searchTerm}
        onChange={handleChange}
      />
    </div>
  )
}

export default SearchBar
