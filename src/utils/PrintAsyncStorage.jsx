import AsyncStorage from '@react-native-async-storage/async-storage';

export const print = async () => {
  console.log('============= ASYNC STORAGE START ===============');
  try {
    const keys = await AsyncStorage.getAllKeys(); // Get all keys from AsyncStorage
    const result = await AsyncStorage.multiGet(keys); // Get all key-value pairs

    // Log each key-value pair
    result.forEach(([key, value]) => {
      try {
        // Try to parse the value as JSON
        const parsedValue = JSON.parse(value);
        console.log(`Key: ${key}, Value (parsed):`, JSON.stringify(parsedValue, null, 2));
      } catch (e) {
        // If it fails to parse, just log the value as a string
        console.log(`Key: ${key}, Value (raw): ${value}`);
      }
    });
  } catch (error) {
    console.error('Error fetching AsyncStorage data:', error);
  }
  console.log('============== ASYNC STORAGE END ================');
};
