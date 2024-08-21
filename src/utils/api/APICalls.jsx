import {Platform} from 'react-native';

// Define local and remote URLs
const LOCAL_URL = Platform.select({
  ios: 'http://127.0.0.1:3000',
  android: 'http://10.0.2.2:3000',
  default: 'http://10.0.2.2:3000', // Fallback for Android emulators
});
const REMOTE_URL = 'https://your-production-url.com';

const LOCAL = true;
const BASE_URL = LOCAL ? LOCAL_URL : REMOTE_URL;

/**
 * Sends a request to refresh the user's JWT token.
 *
 * @param {string} email - The email address of the user requesting the token refresh.
 * @param {string} password - The password of the user requesting the token refresh.
 * @returns {Promise<Object|null>} A promise that resolves to the JSON response data from the API,
 * or `null` if an error occurs. The shape of the response data depends on the API implementation.
 */
export const refreshUserToken = async (email, password) => {
  try {
    const response = await fetch(`${BASE_URL}/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({email, password}),
    });
    return await response.json();
  } catch (error) {
    console.log('Error refreshing token:', error);
    // Optionally, return null in case of an error
    return null;
  }
};
