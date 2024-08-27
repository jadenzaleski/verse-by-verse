import React, {useContext, useEffect, useState} from 'react';
import {View, Text, StyleSheet, ActivityIndicator, Image} from 'react-native';
import ThemeContext from '../context/ThemeContext';
import {getUser} from '../utils/api/APICalls';

const LoadingScreen = ({onFinishLoading}) => {
  const [loadingMessage, setLoadingMessage] = useState('Initializing...');
  const {theme} = useContext(ThemeContext);

  useEffect(() => {
    const performLoadingTasks = async () => {
      await getUser();
      setLoadingMessage('Updating User...');
      // example:
      await new Promise(resolve => setTimeout(resolve, 500));
      onFinishLoading();
    };

    performLoadingTasks();
  }, [onFinishLoading]);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
    },
    img: {
      width: 200,
      height: 200,
    },
    bottomContainer: {
      position: 'absolute',
      bottom: 30,
      alignItems: 'center',
    },
    loadingText: {
      marginTop: 10,
      ...theme.fonts.regular,
      fontSize: theme.fontSizes.medium,
      color: theme.colors.text,
    },
  });

  return (
    <View style={styles.container}>
      <Image style={styles.img} source={require('../../assets/images/VerseByVerseLogo.png')} />
      <View style={styles.bottomContainer}>
        <ActivityIndicator size="small" color={theme.colors.accent.toString()} />
        <Text style={styles.loadingText}>{loadingMessage}</Text>
      </View>
    </View>
  );
};

export default LoadingScreen;
