import React, {createContext, useState, useEffect} from 'react';
import {useColorScheme} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const ThemeContext = createContext();

export const ThemeProvider = ({children}) => {
  const colorScheme = useColorScheme();
  const [theme, setTheme] = useState(colorScheme || 'light');

  useEffect(() => {
    // Load saved theme from storage
    const getTheme = async () => {
      try {
        const savedTheme = await AsyncStorage.getItem('theme');
        if (savedTheme) {
          setTheme(savedTheme);
        }
      } catch (error) {
        console.log('Error loading theme:', error);
      }
    };
    getTheme();
  }, []);

  useEffect(() => {
    // set theme to system selected theme
    if (colorScheme) {
      setTheme(colorScheme);
    }
  }, [colorScheme]);

  const toggleTheme = newTheme => {
    setTheme(newTheme);
    AsyncStorage.setItem('theme', newTheme); // Save selected theme to storage
  };

  const useSystemTheme = () => {
    setTheme(colorScheme);
    AsyncStorage.setItem('theme', colorScheme);
  };

  return (
    <ThemeContext.Provider value={{theme, toggleTheme, useSystemTheme}}>
      {children}
    </ThemeContext.Provider>
  );
};
export default ThemeContext;
