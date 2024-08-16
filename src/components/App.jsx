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
import {useContext} from 'react';

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
  // Add more screens and their icons here
};

// Custom Tab Bar
function MyTabBar({state, descriptors, navigation}) {
  const {theme} = useContext(ThemeContext);

  return (
    <View style={{...theme.shadows.small, ...{backgroundColor: theme.colors.secondary}, ...styles.tabContainer}}>
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
          navigation.emit({
            type: 'tabLongPress',
            target: route.key,
          });
        };

        return (
          <TouchableOpacity
            key={route.key}
            activeOpacity={0.4}
            onPress={onPress}
            onLongPress={onLongPress}
            style={styles.tabButton}>
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
  return (
    <ThemeProvider>
      <NavigationContainer>
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
      </NavigationContainer>
    </ThemeProvider>
  );
};

const styles = StyleSheet.create({
  plain: {
    fontSize: 20,
  },
  variableFontText: {
    fontFamily: 'Montserrat', // The name of the font file without extension
    fontSize: 20,
  },
  boldText: {
    fontWeight: '700', // Example: Bold
  },
  italicText: {
    fontFamily: 'Montserrat',
    fontStyle: 'italic',
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'gray',
  },
  tabContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    position: 'absolute',
    bottom: 25,
    left: 50,
    right: 50,
    borderRadius: 50,
    paddingVertical: 15,
  },
  tabButton: {
    alignItems: 'center',
  },
});

export default App;
