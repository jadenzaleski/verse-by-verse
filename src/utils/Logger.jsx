import {logger, consoleTransport} from 'react-native-logs';
import RNFS from 'react-native-fs';
import {LOGS_FOLDER, MAX_LOG_DAYS} from './Globals';

/**
 * Creates the logs folder if it does not already exist.
 */
const createLogsFolder = async () => {
  const folderExists = await RNFS.exists(LOGS_FOLDER);
  if (!folderExists) {
    await RNFS.mkdir(LOGS_FOLDER);
  }
};

/**
 * Custom date formatting function to include hours, minutes, seconds, and milliseconds.
 * HH:MM:SS.SSS will format the timestamp for each log entry.
 * @param {Date} date - The date object to format.
 * @returns {string} - Formatted timestamp.
 */
const customDateFormat = date => {
  const padZeroes = (num, size = 3) => {
    let s = String(num);
    while (s.length < size) s = '0' + s;
    return s;
  };

  const hours = padZeroes(date.getHours(), 2);
  const minutes = padZeroes(date.getMinutes(), 2);
  const seconds = padZeroes(date.getSeconds(), 2);
  const milliseconds = padZeroes(date.getMilliseconds(), 3);

  return `${hours}:${minutes}:${seconds}.${milliseconds} | `;
};

/**
 * Generates a log file name based on the current date.
 * This ensures each day has its own log file.
 * @param {Date} date - The current date.
 * @returns {string} - Log file name in the format 'log-YYYY-MM-DD.txt'.
 */
const getFileName = date => {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `log-${year}-${month}-${day}.txt`;
};

/**
 * Deletes log files that are older than the MAX_LOG_DAYS threshold.
 */
const cleanupOldLogs = async () => {
  const today = new Date();
  const cutoffDate = new Date();
  cutoffDate.setDate(today.getDate() - MAX_LOG_DAYS);

  try {
    const logFiles = await RNFS.readDir(LOGS_FOLDER);

    logFiles.forEach(file => {
      const fileName = file.name;
      const match = fileName.match(/log-(\d{4})-(\d{2})-(\d{2})\.txt/);
      if (match) {
        const logDate = new Date(`${match[1]}-${match[2]}-${match[3]}`);
        if (logDate < cutoffDate) {
          RNFS.unlink(file.path)
            .then(() => console.log('[LOGGER]', `Deleted old log file: ${fileName}`))
            .catch(err => console.error('[LOGGER]', `Failed to delete old log file: ${fileName}`, err));
        }
      }
    });
  } catch (err) {
    console.error('[LOGGER]', 'Failed to read log directory or delete files:', err);
  }
};

/**
 * Custom transport function to handle log writing.
 * Logs messages to the console in development mode and writes to a log file.
 * This also ensures the logs folder exists and cleans up old logs.
 * @param {Object} props - can include the following:
 * - msg: any: the message formatted by logger "[time] | [namespace] | [level] | [msg]"
 * - rawMsg: any: the message (or array of messages) in its original form
 * - level: { severity: number; text: string }: the log level
 * - extension?: string | null: its namespace if it is an extended log
 * - options?: any: the transportOptions object
 */
const customTransport = async props => {
  // Log to console in development mode
  if (__DEV__) {
    consoleTransport(props);
  }

  const date = new Date();
  const logFileName = getFileName(date);

  // Ensure the logs folder exists
  await createLogsFolder();
  // Directory path for the logs (using the logs folder inside the DocumentDirectory)
  const logFilePath = `${LOGS_FOLDER}/${logFileName}`;
  // Log message to write to the file
  const logMessage = `${props.msg}\n`;

  try {
    // Write or append log to today's file
    const fileExists = await RNFS.exists(logFilePath);
    if (fileExists) {
      await RNFS.appendFile(logFilePath, logMessage, 'utf8');
    } else {
      await RNFS.writeFile(logFilePath, logMessage, 'utf8');
    }

    // Clean up old logs
    await cleanupOldLogs();
  } catch (err) {
    log.error('[LOGGER]', 'Failed to write log to file:', err);
  }
};

/**
 * Logger configuration using react-native-logs.
 * - Levels: debug, info, warn, error.
 * - Severity: can be any of the levels. Will print all logs >= the input.
 * - Transport: custom transport for file logging.
 * - Date Format: custom format with milliseconds.
 */
const config = {
  levels: {
    debug: 0,
    info: 1,
    warn: 2,
    error: 3,
  },
  severity: __DEV__ ? 'debug' : 'error',
  transport: customTransport,
  transportOptions: {
    colors: {
      info: 'blueBright',
      warn: 'yellowBright',
      error: 'redBright',
    },
  },
  dateFormat: customDateFormat,
  fixedExtLvlLength: true,
  enabled: true,
};

/**
 * Singleton logger instance for the entire application.
 * This logger can be used throughout the app with the following methods:
 * - `log.debug(message)`: Descriptive, locatable, logs that hold information on code execution,
 * objects, or values. (typically for development).
 * - `log.info(message)`: General information that aids in the understanding of the application architecture.
 * - `log.warn(message)`: Something should not of happened but is caught and/or does not directly affect the user.
 * - `log.error(message)`: Something has gone wrong
 * that has directly affected the user experience in any way.
 */
const log = logger.createLogger(config);

export default log;
