import {StyleSheet, Text, TouchableOpacity, useColorScheme, View} from 'react-native';
import {useContext, useState} from 'react';
import ThemeContext from '../../context/ThemeContext';
import * as React from 'react';
import Icon from '@react-native-vector-icons/ionicons';

const SettingsScreen = () => {
  const {theme, themeSheet, themeName, toggleTheme, useSystemTheme} = useContext(ThemeContext);
  const systemTheme = useColorScheme();
  const [themeNum, setThemeNum] = useState(0);

  function UseSystemTheme() {
    useSystemTheme();
  }

  function HandleNextTheme() {
    if (themeNum === 0) {
      toggleTheme('dark');
    } else if (themeNum === 1) {
      UseSystemTheme();
    } else {
      toggleTheme('light');
    }
    if (themeNum < 2) {
      setThemeNum(themeNum + 1);
    } else {
      setThemeNum(0);
    }
  }

  const getIconName = () => {
    switch (themeNum) {
      case 1:
        return 'moon-outline'; // Dark theme icon
      case 2:
        return 'phone-portrait-outline'; // System theme icon
      case 0:
        return 'sunny-outline'; // Light theme icon
      default:
        return 'sunny-outline'; // Default icon
    }
  };

  const settingsStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.primary,
    },
    container2: {
      padding: 20,
      margin: 20,
      borderRadius: 15,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.secondary,
    },
    text: {
      color: theme.colors.text,
      fontFamily: theme.font,
      fontSize: theme.fontSizes.large,
      // fontWeight: theme.fontWeights.thin,
    },
    button: {
      color: theme.colors.text,
      backgroundColor: theme.colors.accent,
      padding: 12,
      margin: 20,
      borderRadius: 50,
    },
  });

  return (
    <View style={settingsStyles.container}>
      <Text style={{fontSize: 24}}>Plain Text</Text>
      <Text style={settingsStyles.text}>Current Theme: {themeName}</Text>
      <Text style={settingsStyles.text}>System Theme: {systemTheme}</Text>
      <View style={settingsStyles.container2}>
        <TouchableOpacity
          activeOpacity={0.4}
          onPress={HandleNextTheme}
          style={{...settingsStyles.button, ...themeSheet.shadowSmall}}>
          <Icon name={getIconName()} size={24} />
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default SettingsScreen;
