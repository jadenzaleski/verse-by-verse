import { useCallback, useContext } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Toast from 'react-native-toast-message';
import * as Globals from '../Globals'; // Import global constants (like API base URL)
import AuthContext from '../../context/AuthContext'; // Import the Auth context for managing authentication state

const getToken = async () => {
  let jwt = await AsyncStorage.getItem('jwt'); // Get JWT from AsyncStorage
  return JSON.parse(jwt); // Parse and return the JWT
};

const apiCall = async (endpoint, method = 'GET', body = null, headers = {}, showLoginModal, isModalVisible) => {
  try {
    let jwt = await getToken(); // Get the JWT token
    const finalHeaders = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Bearer ${jwt}`, // Add the JWT to the Authorization header
      ...headers, // Spread any additional headers
    };

    // Make the API call
    const response = await fetch(`${Globals.BASE_API_URL}${endpoint}`, {
      method,
      headers: finalHeaders,
      body: body ? JSON.stringify(body) : null, // Stringify the body if it exists
    });

    // Handle unauthorized access (401)
    if (response.status === 401 && !isModalVisible) {
      await showLoginModal(); // Show the login modal if the token is expired
      return apiCall(endpoint, method, body, headers, showLoginModal); // Retry the API call after login
    }

    const responseJSON = await response.json();

    // Handle non-OK responses
    if (!response.ok) {
      const errorMessage = responseJSON.message || `Failed to ${method} ${endpoint}`; // Set the error message
      Toast.show({ type: 'error', text1: errorMessage }); // Show an error toast message
      return responseJSON; // Return null for non-OK responses
    }

    if (responseJSON?.user?.force_login === 1) {
      console.log('[API] Forcing login...');
      await showLoginModal();
    }

    return responseJSON; // Return the parsed response data
  } catch (error) {
    console.error(`[API] Error calling: ${method} ${endpoint}:`, error); // Log the error
    Toast.show({ type: 'error', text1: error.toString() }); // Show an error toast message
    return null; // Return null in case of error
  }
};

export const useApi = () => {
  // Get the showLoginModal function from AuthContext
  const { showLoginModal, isModalVisible } = useContext(AuthContext);
  // Wrapper function for making API calls
  const callApi = async (endpoint, method = 'GET', body = null, headers = {}) => {
    return await apiCall(endpoint, method, body, headers, showLoginModal, isModalVisible); // Call the apiCall function
  };

  return { callApi }; // Return the callApi function for external use
};

export const useRefreshToken = () => {
  const { callApi } = useApi();
  const refreshToken = useCallback(
    async (email, password) => {
      console.log('[API] Refreshing token...');
      const result = await callApi('/refresh', 'POST', { email: email, password: password });
      if (result && result.jwt) {
        await AsyncStorage.setItem('jwt', JSON.stringify(result.jwt));
        console.log('[AS] Set jwt:', result.jwt);
      }
      return result;
    },
    [callApi],
  );

  return { refreshToken };
};

export const useGetUser = () => {
  const { callApi } = useApi(); // Use the callApi function from the useApi hook

  // Memoized getUser function to prevent re-creation on each render
  const getUser = useCallback(async () => {
    console.log('[API] Getting user...');
    const result = await callApi('/user', 'GET'); // Call the API to get user data
    if (result?.user) {
      await AsyncStorage.setItem('user', JSON.stringify(result.user)); // Store the user data in AsyncStorage
      console.log('[AS] Set user.');
    }
    return result; // Return the user data
  }, [callApi]); // Add callApi as dependency since it's used in getUser

  return { getUser }; // Return the memoized getUser function
};

export const usePostUser = () => {
  const { callApi } = useApi(); // Use the callApi function from the useApi hook

  // Function to post user data
  const postUser = async (name, email, password) => {
    const body = { name, email, password }; // Create the body object
    return await callApi('/user', 'POST', body); // Call the API to post user data
  };

  return { postUser }; // Return the postUser function for external use
};
