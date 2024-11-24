import * as Globals from '../Globals';
import axios from 'axios';
import Toast from 'react-native-toast-message';

export default async function postRefresh(email, password) {
  const route = '/refresh';
  const url = Globals.BASE_API_URL + route;
  console.log(`[POST ${route}]Attempting to refresh jwt at:`, url);

  try {
    const response = await axios.post(
      url,
      {
        email: email,
        password: password,
      },
      {
        cache: false,
      },
    );

    if (Globals.DEBUG && response.cached) {
      console.log(`[POST ${route}] cached:`, response.cached);
    }
    return response;
  } catch (error) {
    Toast.show({ type: 'error', text1: error.toString() });
    console.error(`[POST ${route}] Error fetching user data:`, error);
    console.error(JSON.parse(error.response));
    return JSON.parse(error.response);
  }
}
