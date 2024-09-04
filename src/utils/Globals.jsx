import {Platform} from 'react-native';

export const LOCAL_URL = Platform.select({
  ios: 'http://127.0.0.1:3000',
  android: 'http://10.0.2.2:3000',
  default: 'http://10.0.2.2:3000', // Fallback for Android emulators
});
export const REMOTE_URL = 'https://myapi.com';
export const USE_LOCAL_API = true;

export const BASE_API_URL = USE_LOCAL_API ? LOCAL_URL : REMOTE_URL;
