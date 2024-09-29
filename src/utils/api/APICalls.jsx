import Toast from 'react-native-toast-message';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Globals from '../Globals';
// Helper to get JWT token from AsyncStorage
const getToken = async () => {
  let jwt = await AsyncStorage.getItem('jwt');
  return JSON.parse(jwt);
};

// Helper to set JWT token in AsyncStorage
const setToken = async jwt => {
  await AsyncStorage.setItem('jwt', JSON.stringify(jwt));
};

// Centralized API call function with token management and refresh logic
export const apiCall = async (endpoint, method = 'GET', body = null, headers = {}, showLoginModal) => {
  console.log('[API] Trying call:', method, endpoint);
  try {
    let jwt = await getToken();

    const finalHeaders = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Bearer ${jwt}`,
      ...headers,
    };

    const response = await fetch(`${Globals.BASE_API_URL}${endpoint}`, {
      method,
      headers: finalHeaders,
      body: body ? JSON.stringify(body) : null,
    });

    if (response.status === 401) {
      console.log('[API] Token may be expired, showing login modal...');

      // Await the modal to resolve before continuing
      const loggedIn = await showLoginModal();
      console.log('[API] Logged in', loggedIn);
      if (loggedIn) {
        console.log('[API] Retrying API call after login...');
        return apiCall(endpoint, method, body, headers, showLoginModal); // Retry with the new token
      } else {
        console.log('[API] Login canceled');
        return null; // If login is canceled, stop processing
      }
    }

    if (!response.ok) {
      const errorResponse = await response.json();
      const errorMessage = errorResponse.message || `Failed to ${method} ${endpoint}`;
      Toast.show({type: 'error', text1: errorMessage});
      return null;
    }

    return await response.json();
  } catch (error) {
    console.error(`[API] Error calling: ${method} ${endpoint}:`, error);
    Toast.show({type: 'error', text1: error.toString()});
    return null;
  }
};

// Token refresh function that handles getting a new token from the server
export const refreshToken = async (email, password) => {
  try {
    const response = await fetch(`${Globals.BASE_API_URL}/refresh`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({email: email, password: password}),
    });

    if (!response.ok) {
      const errorResponse = await response.json();
      const errorMessage = errorResponse.message || 'Failed to refresh token';
      Toast.show({type: 'error', text1: errorMessage});
      return null;
    }

    const data = await response.json();
    const {jwt} = data;
    await setToken(jwt); // Store new token
    return jwt;
  } catch (error) {
    console.error('Error refreshing token:', error);
    Toast.show({type: 'error', text1: error.toString()});
    return null;
  }
};

// Get user data
export const getUser = async showLoginModal => {
  const user = await apiCall('/user', 'GET', null, {}, showLoginModal);
  if (user) {
    if (Globals.DEBUG) console.log('[AS] Updating "user"');
    await AsyncStorage.setItem('user', JSON.stringify(user));
  }
  return user;
};
