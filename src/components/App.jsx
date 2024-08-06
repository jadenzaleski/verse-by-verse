import * as React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {
  Text,
  View,
  StyleSheet,
  TouchableOpacity,
  useColorScheme,
} from 'react-native';
import Icon from '@react-native-vector-icons/ionicons';
import {Colors} from 'react-native/Libraries/NewAppScreen';
import ThemeContext, {ThemeProvider} from '../context/ThemeContext';
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
  return (
    <View style={styles.tabContainer}>
      {state.routes.map((route, index) => {
        const {options} = descriptors[route.key];
        const isFocused = state.index === index;

        // Determine the icon based on focus state
        const iconName = isFocused
          ? ICONS[route.name]?.focused || 'help-circle'
          : ICONS[route.name]?.unfocused || 'help-circle-outline';

        const icon = (
          <Icon
            name={iconName}
            color={isFocused ? '#3c63e5' : '#222'}
            size={24}
          />
        );

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
          tabBar={renderTabBar} // Use the extracted function here
        >
          <Tab.Screen name="Home" component={HomeScreen} />
          <Tab.Screen name="Verses" component={VersesScreen} />
          <Tab.Screen name="Profile" component={ProfileScreen} />
          <Tab.Screen name="Settings" component={SettingsScreen} />
        </Tab.Navigator>
      </NavigationContainer>
    </ThemeProvider>
  );
};

const HomeScreen = ({navigation}) => {
  const colorScheme = useColorScheme();
  const color = colorScheme === 'light' ? Colors.darker : Colors.lighter;

  return (
    <View style={styles.container}>
      <Text style={styles.plain}>Home</Text>
      <Text style={{color: color}}>Current Color Scheme: {colorScheme}</Text>

      <Text style={styles.variableFontText}>This is a variable font</Text>
      <Text style={{...styles.variableFontText, ...styles.boldText}}>
        This is bold
      </Text>
      <Text style={{...styles.variableFontText, ...styles.italicText}}>
        This is italic
      </Text>
    </View>
  );
};

const VersesScreen = ({navigation}) => {
  return (
    <View style={styles.container}>
      <Text>Verses</Text>
    </View>
  );
};

const ProfileScreen = ({route}) => {
  return (
    <View style={styles.container}>
      <Text>Profile</Text>
    </View>
  );
};

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
    backgroundColor: '#fff',
    position: 'absolute',
    bottom: 25,
    left: 50,
    right: 50,
    borderRadius: 50,
    shadowColor: '#777777',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.8,
    shadowRadius: 2,
    elevation: 5,
    paddingVertical: 15,
  },
  tabButton: {
    alignItems: 'center',
  },
});

export default App;
