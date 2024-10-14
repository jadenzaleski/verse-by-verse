import Axios from 'axios';
import {buildStorage, setupCache} from 'axios-cache-interceptor';
import AsyncStorage from '@react-native-async-storage/async-storage';

const asyncStorage = buildStorage({
  // Set data into AsyncStorage
  set: async (key, value, currentRequest) => {
    try {
      await AsyncStorage.setItem(key, JSON.stringify(value));
    } catch (error) {
      console.error('Error setting data in custom storage:', error);
    }
  },

  // Remove data from AsyncStorage
  remove: async (key, currentRequest) => {
    try {
      await AsyncStorage.removeItem(key);
    } catch (error) {
      console.error('Error removing data from custom storage:', error);
    }
  },

  // Find data in AsyncStorage
  find: async (key, currentRequest) => {
    try {
      const value = await AsyncStorage.getItem(key);
      if (value !== null) {
        return JSON.parse(value);
      }
      return undefined; // If not found, return undefined
    } catch (error) {
      console.error('Error finding data in custom storage:', error);
      return undefined;
    }
  },

  // Clear all data from AsyncStorage
  clear: async () => {
    try {
      await AsyncStorage.clear();
    } catch (error) {
      console.error('Error clearing custom storage:', error);
    }
  },
});

// Set up the cache with axios
const axiosInstance = setupCache(Axios, {
  debug: console.log, // Optional: Log cache behavior, must also add /dev to import.
  storage: asyncStorage,
});

axiosInstance.interceptors.request.use(
  async config => {
    try {
      const token = await AsyncStorage.getItem('token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`; // Add token to headers
      }
      config.headers['Content-Type'] = 'application/json'; // Set content type
    } catch (error) {
      console.error('[AS] Error fetching token from AsyncStorage:', error);
    }
    return config;
  },
  (error) => {
    console.error(error);
    return Promise.reject(error);
  }
);

export const axios = axiosInstance;
