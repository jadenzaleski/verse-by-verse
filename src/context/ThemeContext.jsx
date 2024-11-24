import React, { createContext, useState, useEffect } from 'react';
import { useColorScheme } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getCustomTheme } from '../styles/Theme';
import log from '../utils/Logger';

const ThemeContext = createContext(undefined);

export const ThemeProvider = ({ children }) => {
  const colorScheme = useColorScheme();
  const [themeName, setThemeName] = useState(colorScheme || 'light');
  const [isBold, setIsBold] = useState(false); // State for font boldness
  const [accentColor, setAccentColor] = useState('#A2C2BA'); // Default accent color
  const theme = getCustomTheme(themeName, isBold, accentColor);

  useEffect(() => {
    const loadSettings = async () => {
      try {
        const savedTheme = await AsyncStorage.getItem('theme');
        const savedBold = await AsyncStorage.getItem('isBold');
        const savedAccentColor = await AsyncStorage.getItem('accentColor');

        // If no saved theme is found, fall back to system color scheme
        if (savedTheme) {
          setThemeName(savedTheme);
        } else if (colorScheme) {
          setThemeName(colorScheme);
        }

        if (savedBold !== null) {
          setIsBold(JSON.parse(savedBold));
        } else {
          // Set default bold value if not found in storage
          await AsyncStorage.setItem('isBold', JSON.stringify(false));
        }

        if (savedAccentColor) {
          setAccentColor(savedAccentColor);
        } else {
          // Set default accent color if not found in storage
          await AsyncStorage.setItem('accentColor', '#A2C2BA');
        }
      } catch (error) {
        console.log('Error loading settings:', error);
      }
    };

    loadSettings().then(() => log.debug('Settings retrieved.'));
  }, [colorScheme]);

  const toggleTheme = async newTheme => {
    setThemeName(newTheme);
    await AsyncStorage.setItem('theme', newTheme).then(() => console.log('Theme value saved to storage.'));
  };

  const useSystemTheme = async () => {
    setThemeName(colorScheme);
    await AsyncStorage.setItem('theme', colorScheme).then(() => console.log('System theme value saved to storage.'));
  };

  const toggleBold = async () => {
    setIsBold(previousState => !previousState);
    await AsyncStorage.setItem('isBold', JSON.stringify(!isBold)).then(() =>
      console.log('Bold setting saved to storage.'),
    );
  };

  const updateAccentColor = async color => {
    setAccentColor(color);
    await AsyncStorage.setItem('accentColor', color).then(() => console.log('Accent color saved to storage.'));
  };

  return (
    <ThemeContext.Provider
      value={{ theme, themeName, toggleTheme, useSystemTheme, isBold, toggleBold, accentColor, updateAccentColor }}>
      {children}
    </ThemeContext.Provider>
  );
};

export default ThemeContext;
