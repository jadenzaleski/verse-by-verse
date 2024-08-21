import React, { useContext, useEffect, useState } from "react";
import {View, Text, StyleSheet, ActivityIndicator} from 'react-native';
import ThemeContext from '../context/ThemeContext';

const LoadingScreen = ({onFinishLoading}) => {
  const [loadingMessage, setLoadingMessage] = useState('Initializing...');
  const {theme} = useContext(ThemeContext);

  useEffect(() => {
    const performLoadingTasks = async () => {
      // Simulate a task with a timeout
      await new Promise(resolve => setTimeout(resolve, 1000));
      setLoadingMessage('Loading resources...');

      // Another simulated task
      await new Promise(resolve => setTimeout(resolve, 1000));
      setLoadingMessage('Almost there...');

      // Finish loading after all tasks are done
      await new Promise(resolve => setTimeout(resolve, 1000));
      onFinishLoading();
    };

    performLoadingTasks();
  });

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
    },
    loadingText: {
      marginTop: 20,
      ...theme.fonts.regular,
      fontSize: theme.fontSizes.medium,
      color: theme.colors.text,
    },
  });

  return (
    <View style={styles.container}>
      <ActivityIndicator size="medium" color={theme.colors.accent.toString()} />
      <Text style={styles.loadingText}>{loadingMessage}</Text>
    </View>
  );
};

export default LoadingScreen;
