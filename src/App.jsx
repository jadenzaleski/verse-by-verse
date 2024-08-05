import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Icon from '@react-native-vector-icons/ionicons';

const App = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>Hello, World!!!</Text>
      <Icon name="cog-outline" style={styles.icon} size={30} color="#000" />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#e30000',
  },
  text: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },

  icon: {
    // Remove fill property
  },
});

export default App;
