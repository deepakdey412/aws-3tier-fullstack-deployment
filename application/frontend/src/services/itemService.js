import axios from 'axios'

const API_URL = '/api/items'

const itemService = {
  // Get all items
  async getAllItems() {
    const response = await axios.get(API_URL)
    return response.data.data
  },

  // Get item by ID
  async getItemById(id) {
    const response = await axios.get(`${API_URL}/${id}`)
    return response.data.data
  },

  // Create new item
  async createItem(itemData) {
    const response = await axios.post(API_URL, itemData)
    return response.data.data
  },

  // Update item
  async updateItem(id, itemData) {
    const response = await axios.put(`${API_URL}/${id}`, itemData)
    return response.data.data
  },

  // Delete item
  async deleteItem(id) {
    const response = await axios.delete(`${API_URL}/${id}`)
    return response.data.data
  },

  // Search items
  async searchItems(query) {
    const response = await axios.get(`${API_URL}/search`, {
      params: { q: query }
    })
    return response.data.data
  }
}

export default itemService
