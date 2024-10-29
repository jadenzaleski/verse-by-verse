import {Platform} from 'react-native';
import RNFS from 'react-native-fs';

export const LOCAL_URL = Platform.select({
  ios: 'http://127.0.0.1:3000',
  android: 'http://10.0.2.2:3000',
  default: 'http://10.0.2.2:3000', // Fallback for Android emulators
});
export const REMOTE_URL = 'https://myapi.com';
export const USE_LOCAL_API = true;
export const BASE_API_URL = USE_LOCAL_API ? LOCAL_URL : REMOTE_URL;

export const DEBUG = true;

// the maximum amount of days to hold logs for
export const MAX_LOG_DAYS = 30;
export const LOGS_FOLDER = `${RNFS.DocumentDirectoryPath}/logs`;

// User level and xp calculation variables
export const SCALING_FACTOR = 100;
export const EXPONENT = 1.2;
