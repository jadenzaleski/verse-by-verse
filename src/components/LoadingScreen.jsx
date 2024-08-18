import React, {useEffect, useState} from 'react';
import {View, Text, StyleSheet} from 'react-native';
import {SvgUri} from 'react-native-svg';

const LoadingScreen = ({onFinishLoading}) => {
  const [loadingMessage, setLoadingMessage] = useState('Initializing...');

  useEffect(() => {
    const performLoadingTasks = async () => {
      // Simulate a task with a timeout
      await new Promise(resolve => setTimeout(resolve, 2000));
      setLoadingMessage('Loading resources...');

      // Another simulated task
      await new Promise(resolve => setTimeout(resolve, 2000));
      setLoadingMessage('Almost there...');

      // Finish loading after all tasks are done
      await new Promise(resolve => setTimeout(resolve, 2000));
      onFinishLoading();
    };

    performLoadingTasks();
  });

  return (
    <View style={styles.container}>
      <Text style={styles.loadingText}>{loadingMessage}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#ffffff',
  },
  loadingText: {
    marginTop: 20,
    fontSize: 16,
    color: '#333333',
  },
});

export default LoadingScreen;
