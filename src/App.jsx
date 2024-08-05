import * as React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Button, Text, View, StyleSheet, TouchableOpacity } from 'react-native';
import Icon from '@react-native-vector-icons/ionicons';

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
  Collections: {
    focused: 'albums',
    unfocused: 'albums-outline',
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

const App = () => {
  return (
    <NavigationContainer>
      <Tab.Navigator screenOptions={{
        headerShown: false,
        tabBarShowLabel: false,
      }} tabBar={(props) => <MyTabBar {...props} />}>
        <Tab.Screen
          name="Home"
          component={HomeScreen}
        />
        <Tab.Screen
          name="Verses"
          component={VersesScreen}
        />
        <Tab.Screen
          name="Collections"
          component={CollectionsScreen}
        />
        <Tab.Screen
          name="Profile"
          component={ProfileScreen}
        />
        <Tab.Screen
          name="Settings"
          component={SettingsScreen}
        />
        {/* Add more Tab.Screen components here */}
      </Tab.Navigator>
    </NavigationContainer>
  );
};

const HomeScreen = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Text>Home</Text>
    </View>
  );
};

const VersesScreen = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Text>Verses</Text>
    </View>
  );
};
const CollectionsScreen = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Text>Collections</Text>
    </View>
  );
};

const ProfileScreen = ({ route }) => {
  return (
    <View style={styles.container}>
      <Text>Profile</Text>
    </View>
  );
};

const SettingsScreen = () => {
  return (
    <View style={styles.container}>
      <Text>Settings</Text>
    </View>
  );
};

// Custom Tab Bar
function MyTabBar({ state, descriptors, navigation }) {
  return (
    <View style={styles.tabContainer}>
      {state.routes.map((route, index) => {
        const { options } = descriptors[route.key];
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
            style={styles.tabButton}
          >
            {icon}
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  tabContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    backgroundColor: '#fff',
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    borderRadius: 50,
    shadowColor: '#777777',
    shadowOffset: { width: 0, height: 2 },
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
