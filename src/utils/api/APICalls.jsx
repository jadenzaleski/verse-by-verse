import {Platform} from 'react-native';
import Toast from 'react-native-toast-message';
import AsyncStorage from '@react-native-async-storage/async-storage';
const LOCAL = true;

// Define local and remote URLs
const LOCAL_URL = Platform.select({
  ios: 'http://127.0.0.1:3000',
  android: 'http://10.0.2.2:3000',
  default: 'http://10.0.2.2:3000', // Fallback for Android emulators
});
const REMOTE_URL = 'https://your-production-url.com';
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

    if (!response.ok) {
      // If the response is not OK, handle the error directly
      const errorResponse = await response.json();
      const errorMessage = errorResponse.message || 'Failed to refresh token';
      console.log('Error refreshing token:', errorMessage);
      Toast.show({
        type: 'error',
        text1: errorMessage,
      });
      return null;
    }

    const data = await response.json();

    // Assuming the JWT is in the `token` field of the response
    const {jwt} = data;

    // Store JWT in AsyncStorage
    await AsyncStorage.setItem('jwt', JSON.stringify(jwt));
    console.log('JWT stored successfully');

    return data; // Return the entire response or relevant part
  } catch (error) {
    console.log('Error refreshing token:', error);

    // Show error toast
    Toast.show({
      type: 'error',
      text1: error.toString(),
    });

    return null;
  }
};

export const getUser = async () => {
  try {
    let jwt = await AsyncStorage.getItem('jwt');
    jwt = JSON.parse(jwt);
    // Make the fetch call with the constructed Authorization header
    const response = await fetch(`${BASE_URL}/user`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + jwt,
      },
    });

    if (!response.ok) {
      const errorResponse = await response.json();
      const errorMessage = errorResponse.message || 'Failed to get user';
      console.log('Error getting user:', errorMessage);
      Toast.show({
        type: 'error',
        text1: errorMessage,
      });
      return null;
    }

    const responseData = await response.json();
    console.log('Success getting user, /user:');
    await AsyncStorage.setItem('user', JSON.stringify(responseData.user));
    return responseData;
  } catch (error) {
    console.log('Error getting user, /user:', error);
    Toast.show({
      type: 'error',
      text1: error.toString(),
    });
    return null;
  }
};
