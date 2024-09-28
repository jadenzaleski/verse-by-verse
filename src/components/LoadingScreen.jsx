import React, {useContext, useEffect, useState} from 'react';
import {View, Text, StyleSheet, ActivityIndicator, Image} from 'react-native';
import ThemeContext from '../context/ThemeContext';
import {getUser} from '../utils/api/APICalls';
import * as Globals from '../utils/Globals';
import * as PrintAsyncStorage from '../utils/PrintAsyncStorage';
import AuthContext from '../context/AuthContext';

const LoadingScreen = ({onFinishLoading}) => {
  const [loadingMessage, setLoadingMessage] = useState('Initializing...');
  const {theme} = useContext(ThemeContext);
  const {showLoginModal} = useContext(AuthContext);

  useEffect(() => {
    const performLoadingTasks = async () => {
      setLoadingMessage('Updating User...');
      await getUser(showLoginModal);
      // example:
      await new Promise(resolve => setTimeout(resolve, 500));

      // Log the storage
      if (Globals.DEBUG) {
        await PrintAsyncStorage.print();
      }

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
