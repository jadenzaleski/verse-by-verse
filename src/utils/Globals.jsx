import { Platform } from 'react-native';
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

// regexes
export const EMAIL_REGEX =
  // eslint-disable-next-line max-len,no-control-regex
  /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/;
export const PASSWORD_REGEX = /^(?=.*[0-9\W]).{8,}$/;

export const ITEM_MAX_OFFSET = 140;
