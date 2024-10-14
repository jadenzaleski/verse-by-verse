import {axios} from './Axios';
import * as Globals from '../Globals';
import Toast from 'react-native-toast-message';

export default async function getUser(showLoginModal) {
  const url = Globals.BASE_API_URL + '/user';
  console.log('[GET /user] Attempting to get user at:', url);
  try {
    const response = await axios.get(url, {
      id: 'user',
      cache: {
        ttl: 1000 * 60,
      },
    });

    if (Globals.DEBUG && response.cached) {
      console.log('[GET /user] cached:', response.cached);
    }
    return response;
  } catch (error) {
    if (error.response?.status === 401 || error.response?.status === 403) {
      console.log('[GET /user] Unauthorized, showing login modal...');
      await showLoginModal(); // Call the modal to prompt for login
      return getUser(showLoginModal); // Retry after successful login
    } else if (error.code === 'ERR_NETWORK') {
      console.error(error.code);
      Toast.show({type: 'network_error'});
    } else {
      Toast.show({type: 'error', text1: error.toString()});
      console.error('[GET /user] Error fetching user data:', error);
      throw error; // Rethrow other errors for higher-level handling
    }
  }
}
