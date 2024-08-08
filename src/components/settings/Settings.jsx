import {
  StyleSheet,
  Text,
  TouchableOpacity,
  useColorScheme,
  View,
} from 'react-native';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import * as React from 'react';

const SettingsScreen = () => {
  const systemTheme = useColorScheme();
  const {theme, themeName, toggleTheme, useSystemTheme} =
    useContext(ThemeContext);

  const HandleSystemTheme = () => {
    useSystemTheme();
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
    },
    button: {
      color: theme.colors.text,
      backgroundColor: theme.colors.accent,
      padding: 10,
      margin: 20,
    },
  });

  return (
    <View style={settingsStyles.container}>
      <Text style={settingsStyles.text}>Current Theme: {themeName}</Text>
      <Text style={settingsStyles.text}>System Theme: {systemTheme}</Text>
      <View style={settingsStyles.container2}>
        <TouchableOpacity
          activeOpacity={0.9}
          onPress={() => toggleTheme('light')}>
          <Text style={settingsStyles.button}>Light Theme</Text>
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.9} onPress={() => toggleTheme('dark')}>
          <Text style={settingsStyles.button}>Dark Theme</Text>
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.9} onPress={() => HandleSystemTheme()}>
          <Text style={settingsStyles.button}>System Theme</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default SettingsScreen;
