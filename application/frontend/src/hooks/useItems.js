import { useState, useEffect } from 'react'
import itemService from '../services/itemService'

const useItems = () => {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  // Fetch all items
  const fetchItems = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await itemService.getAllItems()
      setItems(data)
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch items')
      console.error('Error fetching items:', err)
    } finally {
      setLoading(false)
    }
  }

  // Create new item
  const createItem = async (itemData) => {
    setError(null)
    try {
      const newItem = await itemService.createItem(itemData)
      setItems(prevItems => [...prevItems, newItem])
      return newItem
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create item')
      console.error('Error creating item:', err)
      throw err
    }
  }

  // Update item
  const updateItem = async (id, itemData) => {
    setError(null)
    try {
      const updatedItem = await itemService.updateItem(id, itemData)
      setItems(prevItems =>
        prevItems.map(item => (item.id === id ? updatedItem : item))
      )
      return updatedItem
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to update item')
      console.error('Error updating item:', err)
      throw err
    }
  }

  // Delete item
  const deleteItem = async (id) => {
    setError(null)
    try {
      await itemService.deleteItem(id)
      setItems(prevItems => prevItems.filter(item => item.id !== id))
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to delete item')
      console.error('Error deleting item:', err)
      throw err
    }
  }

  // Fetch items on component mount
  useEffect(() => {
    fetchItems()
  }, [])

  return {
    items,
    loading,
    error,
    fetchItems,
    createItem,
    updateItem,
    deleteItem
  }
}

export default useItems
