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
  const {theme, toggleTheme, useSystemTheme} = useContext(ThemeContext);
  const HandleSystemTheme = () => {
    useSystemTheme();
  };

  const settingsStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme === 'dark' ? 'black' : 'white',
    },
    text: {
      color: theme === 'dark' ? 'white' : 'black',
    },
    button: {
      color: theme === 'dark' ? 'black' : 'white',
    },
  });
  return (
    <View style={settingsStyles.container}>
      <Text style={settingsStyles.text}>Current Theme: {theme}</Text>
      <Text style={settingsStyles.text}>System Theme: {systemTheme}</Text>
      <TouchableOpacity
        onPress={() => toggleTheme('light')}
        style={{
          marginTop: 10,
          paddingVertical: 5,
          paddingHorizontal: 10,
          backgroundColor: theme === 'dark' ? '#fff' : '#000',
        }}>
        <Text style={settingsStyles.button}>Light Theme</Text>
      </TouchableOpacity>
      <TouchableOpacity
        onPress={() => toggleTheme('dark')}
        style={{
          marginTop: 20,
          paddingVertical: 5,
          paddingHorizontal: 10,
          backgroundColor: theme === 'dark' ? '#fff' : '#000',
        }}>
        <Text style={settingsStyles.button}>Dark Theme</Text>
      </TouchableOpacity>
      <TouchableOpacity
        onPress={() => HandleSystemTheme()}
        style={{
          marginTop: 20,
          paddingVertical: 5,
          paddingHorizontal: 10,
          backgroundColor: theme === 'dark' ? '#fff' : '#000',
        }}>
        <Text style={settingsStyles.button}>System Theme</Text>
      </TouchableOpacity>
    </View>
  );
};

export default SettingsScreen;
