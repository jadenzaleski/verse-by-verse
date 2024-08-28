import * as React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {View, StyleSheet, TouchableOpacity, StatusBar} from 'react-native';
import Icon from '@react-native-vector-icons/ionicons';
import ThemeContext, {ThemeProvider} from '../context/ThemeContext';
import HomeScreen from './home/Home';
import VersesScreen from './verses/Verses';
import ProfileScreen from './profile/Profile';
import SettingsScreen from './settings/Settings';
import {useContext, useState} from 'react';
import LoadingScreen from './LoadingScreen';
import CustomToasts from './Toasts';
import {DarkTheme as theme} from '@react-navigation/native/src';

const Tab = createBottomTabNavigator();
// Define icon mapping for each screen
const ICONS = {
  Home: {
    focused: 'home',
    unfocused: 'home-outline',
  },
  Verses: {
    focused: 'book',
    unfocused: 'book-outline',
  },
  Profile: {
    focused: 'person',
    unfocused: 'person-outline',
  },
  Settings: {
    focused: 'cog',
    unfocused: 'cog-outline',
  },
};

// Custom Tab Bar
function MyTabBar({state, descriptors, navigation}) {
  const {theme} = useContext(ThemeContext);

  const tabStyles = StyleSheet.create({
    tabContainer: {
      flexDirection: 'row',
      justifyContent: 'space-around',
      alignItems: 'center',
      position: 'absolute',
      bottom: 25,
      left: 30,
      right: 30,
      borderRadius: 50,
      paddingVertical: 15,
    },
    tabButton: {
      alignItems: 'center',
    },
  });

  return (
    <View style={{...theme.shadows.small, ...{backgroundColor: theme.colors.secondary}, ...tabStyles.tabContainer}}>
      <StatusBar hidden={false} translucent={true} backgroundColor={'transparent'} />
      {state.routes.map((route, index) => {
        const {options} = descriptors[route.key];
        const isFocused = state.index === index;

        // Determine the icon based on focus state
        const iconName = isFocused
          ? ICONS[route.name]?.focused || 'help-circle'
          : ICONS[route.name]?.unfocused || 'help-circle-outline';

        const icon = <Icon name={iconName} color={isFocused ? theme.colors.accent : theme.colors.text} size={24} />;

        const onPress = () => {
          const event = navigation.emit({
            type: 'tabPress',
            target: route.key,
          });

          if (!isFocused && !event.defaultPrevented) {
            navigation.navigate(route.name);
          }
        };

        const onLongPress = () => {
          const event = navigation.emit({
            type: 'tabLongPress',
            target: route.key,
          });

          if (!isFocused && !event.defaultPrevented) {
            navigation.navigate(route.name);
          }
        };

        return (
          <TouchableOpacity
            key={route.key}
            activeOpacity={0.4}
            onPress={onPress}
            onLongPress={onLongPress}
            style={tabStyles.tabButton}>
            {icon}
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

// Define the tab bar function outside the component
const renderTabBar = props => <MyTabBar {...props} />;

const App = () => {
  const [isLoading, setIsLoading] = useState(true);
  const handleFinishLoading = () => {
    setIsLoading(false);
  };
  return (
    <ThemeProvider>
      <NavigationContainer>
        {isLoading ? (
          <LoadingScreen onFinishLoading={handleFinishLoading} />
        ) : (
          <Tab.Navigator
            screenOptions={{
              headerShown: false,
              tabBarShowLabel: false,
            }}
            tabBar={renderTabBar}>
            <Tab.Screen name="Home" component={HomeScreen} />
            <Tab.Screen name="Verses" component={VersesScreen} />
            <Tab.Screen name="Profile" component={ProfileScreen} />
            <Tab.Screen name="Settings" component={SettingsScreen} />
          </Tab.Navigator>
        )}
      </NavigationContainer>
      {/*Allow for Toast displays*/}
      <CustomToasts />
    </ThemeProvider>
  );
};

export default App;
