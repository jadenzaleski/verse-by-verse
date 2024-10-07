import {useCallback, useContext, useRef} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Toast from 'react-native-toast-message';
import * as Globals from '../Globals'; // Import global constants (like API base URL)
import AuthContext from '../../context/AuthContext'; // Import the Auth context for managing authentication state

/**
 * Helper function to retrieve the JWT token from AsyncStorage.
 *
 * This function asynchronously retrieves the JWT token stored in AsyncStorage.
 * It parses the JSON string and returns the token.
 *
 * @returns {Promise<string|null>} The JWT token as a string, or null if not found.
 */
const getToken = async () => {
  let jwt = await AsyncStorage.getItem('jwt'); // Get JWT from AsyncStorage
  return JSON.parse(jwt); // Parse and return the JWT
};

/**
 * Function to perform API calls with error handling and JWT authentication.
 *
 * This function handles making HTTP requests to the API, automatically adds
 * the JWT token in the headers, manages unauthorized responses by showing
 * a login modal, and handles errors.
 *
 * @param {string} endpoint - The API endpoint to call.
 * @param {string} method - The HTTP method (e.g., 'GET', 'POST'). Defaults to 'GET'.
 * @param {object|null} body - The request body for methods like POST. Defaults to null.
 * @param {object} headers - Any additional headers to include in the request. Defaults to an empty object.
 * @param {function} showLoginModal - A function to show the login modal when the JWT is expired.
 * @returns {Promise<object|null>} The parsed response data, or null in case of error.
 */
const apiCall = async (endpoint, method = 'GET', body = null, headers = {}, showLoginModal) => {
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
    if (response.status === 401) {
      await showLoginModal(); // Show the login modal if the token is expired
      return apiCall(endpoint, method, body, headers, showLoginModal); // Retry the API call after login
    }

    // Handle non-OK responses
    if (!response.ok) {
      const errorResponse = await response.json(); // Parse the error response
      const errorMessage = errorResponse.message || `Failed to ${method} ${endpoint}`; // Set the error message
      Toast.show({type: 'error', text1: errorMessage}); // Show an error toast message
      return null; // Return null for non-OK responses
    }

    return await response.json(); // Return the parsed response data
  } catch (error) {
    console.error(`[API] Error calling: ${method} ${endpoint}:`, error); // Log the error
    Toast.show({type: 'error', text1: error.toString()}); // Show an error toast message
    return null; // Return null in case of error
  }
};

/**
 * Custom hook for making API calls.
 *
 * This hook provides a function to perform authenticated API calls using JWT.
 *
 * @returns {object} An object containing the callApi function.
 */
export const useApi = () => {
  const {showLoginModal} = useContext(AuthContext); // Get the showLoginModal function from AuthContext

  // Wrapper function for making API calls
  const callApi = async (endpoint, method = 'GET', body = null, headers = {}) => {
    return await apiCall(endpoint, method, body, headers, showLoginModal); // Call the apiCall function
  };

  return {callApi}; // Return the callApi function for external use
};

export const useRefreshToken = () => {
  const {callApi} = useApi();
  const refreshToken = useCallback(
    async (email, password) => {
      console.log('[API] Refreshing token...');
      const result = await callApi('/refresh', 'POST', {email: email, password: password});
      if (result) {
        await AsyncStorage.setItem('jwt', JSON.stringify(result.jwt));
        console.log('[AS] Set jwt.');
      }
      return result;
    },
    [callApi],
  );

  return {refreshToken};
};

/**
 * Custom hook to get user data.
 *
 * This hook provides a function to fetch user data from the API and store it in AsyncStorage.
 *
 * @returns {object} An object containing the getUser function.
 */
export const useGetUser = () => {
  const {callApi} = useApi(); // Use the callApi function from the useApi hook
  const {showLoginModal} = useContext(AuthContext); // Get the showLoginModal function from AuthContext

  // Memoized getUser function to prevent re-creation on each render
  const getUser = useCallback(async () => {
    console.log('[API] Getting user...');
    const result = await callApi('/user', 'GET'); // Call the API to get user data
    if (result) {
      if (result.user.force_login) {
        console.log('[API] Forcing login...');
        showLoginModal();
      }

      await AsyncStorage.setItem('user', JSON.stringify(result.user)); // Store the user data in AsyncStorage
      console.log('[AS] Set user.');
    }
    return result; // Return the user data
  }, [callApi]); // Add callApi as dependency since it's used in getUser

  return {getUser}; // Return the memoized getUser function
};

/**
 * Custom hook to post user data.
 *
 * This hook provides a function to post user data to the API.
 *
 * @returns {object} An object containing the postUser function.
 */
export const usePostUser = () => {
  const {callApi} = useApi(); // Use the callApi function from the useApi hook

  // Function to post user data
  const postUser = async (name, email, password) => {
    const body = {name, email, password}; // Create the body object
    return await callApi('/user', 'POST', body); // Call the API to post user data
  };

  return {postUser}; // Return the postUser function for external use
};
