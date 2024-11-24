import React, { useContext } from 'react';
import { StyleSheet, Text } from 'react-native';
import { createStackNavigator } from '@react-navigation/stack';
import ColorPickerScreen from './ColorPicker';
import SettingsScreen from './Settings';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons'; // Import your ColorPickerScreen here

const Stack = createStackNavigator();

const SettingsNavigator = () => {
  const { theme } = useContext(ThemeContext);

  const navigatorStyles = StyleSheet.create({
    headerTitle: {
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.medium,
      color: theme.colors.text,
    },
    header: {
      backgroundColor: theme.colors.primary,
      borderWidth: 0,
      borderColor: theme.colors.primary,
      shadowColor: 'transparent',
    },
    backButton: {
      color: theme.colors.accent,
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.medium,
    },
    backButtonIcon: {
      marginLeft: 0,
    },
  });

  const renderBackImage = () => (
    <Icon style={navigatorStyles.backButtonIcon} color={theme.colors.accent} name={'chevron-back-outline'} size={25} />
  );

  return (
    <Stack.Navigator>
      <Stack.Screen options={{ headerShown: false }} name="SettingsScreen" component={SettingsScreen} />
      <Stack.Screen
        options={{
          headerTitle: props => <Text style={navigatorStyles.headerTitle}>Accent Color</Text>,
          headerStyle: navigatorStyles.header,
          headerBackTitle: 'Back',
          headerBackTitleStyle: navigatorStyles.backButton,
          headerTintColor: theme.colors.accent,
          headerBackImage: renderBackImage,
        }}
        name="ColorPicker"
        component={ColorPickerScreen}
      />
    </Stack.Navigator>
  );
};

export default SettingsNavigator;
