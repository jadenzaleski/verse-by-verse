import React, {createContext, useState, useEffect} from 'react';
import {StyleSheet, useColorScheme} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {getCustomTheme} from '../styles/themes/Theme';

const ThemeContext = createContext(undefined);

export const ThemeProvider = ({children}) => {
  const colorScheme = useColorScheme();
  const [themeName, setThemeName] = useState(colorScheme || 'light');
  const theme = getCustomTheme(themeName);

  const themeSheet = StyleSheet.create({
    shadowSmall: {},
  });

  useEffect(() => {
    // Load saved theme from storage
    const getTheme = async () => {
      try {
        const savedTheme = await AsyncStorage.getItem('theme');
        if (savedTheme) {
          setThemeName(savedTheme);
        }
      } catch (error) {
        console.log('Error loading theme:', error);
      }
    };
    getTheme().then(() => console.log('Retrieved theme.'));
  }, []);

  useEffect(() => {
    // Set theme to system selected theme
    if (colorScheme) {
      setThemeName(colorScheme);
    }
  }, [colorScheme]);

  const toggleTheme = newTheme => {
    setThemeName(newTheme);
    AsyncStorage.setItem('theme', newTheme).then(() =>
      console.log('Theme value saved to storage.'),
    );
  };

  const useSystemTheme = () => {
    setThemeName(colorScheme);
    AsyncStorage.setItem('theme', colorScheme).then(() =>
      console.log('System theme value saved to storage.'),
    );
  };

  return (
    <ThemeContext.Provider
      value={{theme, themeName, toggleTheme, useSystemTheme}}>
      {children}
    </ThemeContext.Provider>
  );
};

export default ThemeContext;
