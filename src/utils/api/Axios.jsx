import Axios from 'axios';
import { buildStorage, setupCache } from 'axios-cache-interceptor';
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
const axios = setupCache(Axios, {
  debug: console.log, // Optional: Log cache behavior
  storage: asyncStorage,
});

// Create an async function to handle the API calls
export async function fetchData() {
  console.log('Fetching data');
  try {
    // Make two requests, the second should come from the cache
    const req1 = axios.get('https://fake-json-api.mock.beeceptor.com/users');
    const req2 = axios.get('https://fake-json-api.mock.beeceptor.com/users');

    // Use Promise.all to wait for both requests to resolve
    const [res1, res2] = await Promise.all([req1, req2]);

    // Check if responses were cached
    console.log('Response 1 cached:', res1.cached); // Should be false
    console.log('Response 2 cached:', res2.cached); // Should be true
  } catch (error) {
    console.error('Error during API calls:', error);
  }
}

// Call the function
fetchData();
