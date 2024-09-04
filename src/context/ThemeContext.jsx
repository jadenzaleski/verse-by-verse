import React, {createContext, useState, useEffect} from 'react';
import {useColorScheme} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {getCustomTheme} from '../styles/themes/Theme';

const ThemeContext = createContext(undefined);

export const ThemeProvider = ({children}) => {
  const colorScheme = useColorScheme();
  const [themeName, setThemeName] = useState(colorScheme || 'light');
  const [isBold, setIsBold] = useState(false); // State for font boldness
  const theme = getCustomTheme(themeName, isBold);

  useEffect(() => {
    const loadSettings = async () => {
      try {
        const savedTheme = await AsyncStorage.getItem('theme');
        const savedBold = await AsyncStorage.getItem('isBold');

        // If no saved theme is found, fall back to system color scheme
        if (savedTheme) {
          setThemeName(savedTheme);
        } else if (colorScheme) {
          setThemeName(colorScheme);
        }

        if (savedBold !== null) {
          setIsBold(JSON.parse(savedBold));
        }
      } catch (error) {
        console.log('Error loading settings:', error);
      }
    };

    loadSettings().then(() => console.log('Settings retrieved.'));
  }, [colorScheme]);

  const toggleTheme = newTheme => {
    setThemeName(newTheme);
    AsyncStorage.setItem('theme', newTheme).then(() => console.log('Theme value saved to storage.'));
  };

  const useSystemTheme = () => {
    setThemeName(colorScheme);
    AsyncStorage.setItem('theme', colorScheme).then(() => console.log('System theme value saved to storage.'));
  };

  const toggleBold = () => {
    setIsBold(previousState => !previousState);
    AsyncStorage.setItem('isBold', JSON.stringify(!isBold)).then(() => console.log('Bold setting saved to storage.'));
  };

  return (
    <ThemeContext.Provider value={{theme, themeName, toggleTheme, useSystemTheme, isBold, toggleBold}}>
      {children}
    </ThemeContext.Provider>
  );
};

export default ThemeContext;
