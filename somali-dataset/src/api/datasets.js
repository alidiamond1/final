import api from './auth';

// Get dataset statistics (total downloads and storage used)
export const getStats = async () => {
  try {
    const response = await api.get('/datasets/stats');
    // Only return total downloads and storage used
    return {
      downloads: response.data.downloads,
      storage: response.data.storage,
    };
  } catch (error) {
    throw error.response?.data || error.message || 'Failed to fetch stats';
  }
};

// Dataset Management APIs
export const getAllDatasets = async () => {
  try {
    const response = await api.get('/datasets');
    return response.data.datasets;
  } catch (error) {
    throw error.response?.data || error.message || 'Failed to fetch datasets';
  }
};

export const getDatasetById = async (datasetId) => {
  try {
    const response = await api.get(`/datasets/${datasetId}`);
    return response.data.dataset;
  } catch (error) {
    throw error.response?.data || error.message || 'Failed to fetch dataset';
  }
};

export const createDataset = async (formData) => {
  try {
    // Log the FormData contents for debugging
    console.log('FormData being sent:');
    for (let [key, value] of formData.entries()) {
      if (key === 'file') {
        console.log('File:', value.name, value.type, value.size, 'bytes');
      } else {
        console.log(key, ':', value);
      }
    }
    
    // Send the FormData with the file
    const response = await api.post('/datasets', formData, {
      headers: {
        // Important: Let the browser set the correct Content-Type with boundary
        'Content-Type': 'multipart/form-data',
      },
      // Add timeout for large files
      timeout: 60000, // 1 minute timeout
    });
    
    return response.data;
  } catch (error) {
    console.error('API error details:', error.response?.data || error);
    
    // Provide more descriptive error messages based on the error
    if (error.code === 'ECONNABORTED') {
      throw new Error('Upload timed out. The file may be too large or the server is busy.');
    }
    
    if (error.response?.status === 413) {
      throw new Error('File is too large. Maximum size is 100MB.');
    }
    
    if (error.response?.status === 415) {
      throw new Error('File type not supported. Please upload a different file format.');
    }
    
    if (error.response?.data?.error) {
      throw new Error(error.response.data.error);
    }
    
    throw new Error(error.message || 'Failed to upload dataset');
  }
};

export const updateDataset = async (datasetId, datasetData) => {
  try {
    console.log(`Updating dataset with ID: ${datasetId}`, datasetData);
    
    const formData = new FormData();
    
    // Append text fields
    Object.keys(datasetData).forEach(key => {
      if (key !== 'file') {
        formData.append(key, datasetData[key]);
      }
    });
    
    // Append file if it exists
    if (datasetData.file) {
      formData.append('file', datasetData.file);
    }
    
    // Log the request being sent
    console.log(`Sending PUT request to: /datasets/${datasetId}`);
    
    const response = await api.put(`/datasets/${datasetId}`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    
    console.log('Update response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error updating dataset:', error);
    console.error('Error details:', error.response?.data);
    throw error.response?.data?.error || error.message || 'Failed to update dataset';
  }
};

export const deleteDataset = async (datasetId) => {
  try {
    console.log(`Deleting dataset with ID: ${datasetId}`);
    
    // Log the request being sent
    console.log(`Sending DELETE request to: /datasets/${datasetId}`);
    
    const response = await api.delete(`/datasets/${datasetId}`);
    
    console.log('Delete response:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error deleting dataset:', error);
    console.error('Error details:', error.response?.data);
    throw error.response?.data?.error || error.message || 'Failed to delete dataset';
  }
};