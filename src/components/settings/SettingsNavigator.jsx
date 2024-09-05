import React, {useContext} from 'react';
import {StyleSheet} from 'react-native';
import {createStackNavigator} from '@react-navigation/stack';
import ColorPicker from './ColorPicker';
import SettingsScreen from './Settings';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons'; // Import your ColorPickerScreen here

const Stack = createStackNavigator();

const SettingsNavigator = () => {
  const {theme} = useContext(ThemeContext);

  const navigatorStyles = StyleSheet.create({
    backButton: {
      color: theme.colors.accent,
      fontSize: theme.fontSizes.subtitle,
    },
    backButtonIcon: {marginLeft: 0},
  });

  const renderBackImage = () => (
    <Icon style={navigatorStyles.backButtonIcon} color={theme.colors.accent} name={'chevron-back-outline'} size={25} />
  );

  return (
    <Stack.Navigator>
      <Stack.Screen options={{headerShown: false}} name="Settings" component={SettingsScreen} />
      <Stack.Screen
        options={{
          headerTitle: '',
          headerTransparent: true,
          headerBackTitle: 'Back',
          headerBackTitleStyle: navigatorStyles.backButton,
          headerTintColor: theme.colors.accent,
          headerBackImage: renderBackImage,
        }}
        name="ColorPicker"
        component={ColorPicker}
      />
    </Stack.Navigator>
  );
};

export default SettingsNavigator;
