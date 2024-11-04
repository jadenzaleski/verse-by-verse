import React, {useContext, useRef, useState} from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  Image,
  KeyboardAvoidingView,
  Platform,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import AuthContext from '../context/AuthContext';
import ThemeContext from '../context/ThemeContext';
import CustomTextInput from './CustomTextInputs';
import {useRefreshToken} from '../utils/api/APICalls';
import postRefresh from '../utils/api/PostRefresh';
import {createUser} from '../utils/db/Users';

export const LoginModal = () => {
  const {isModalVisible, hideLoginModal} = useContext(AuthContext);
  const {theme} = useContext(ThemeContext);

  const passwordRef = useRef();
  const [showLoader, setShowLoader] = useState(false);
  const [email, setEmail] = React.useState(' ');
  const [password, setPassword] = React.useState(' ');
  const [feedback, setFeedback] = React.useState(null);

  const [showRegister, setShowRegister] = React.useState(false);
  const regEmailRef = useRef();
  const regPasswordRef = useRef();
  const regPasswordConfirmRef = useRef();
  const [regName, setRegName] = React.useState(null);
  const [regEmail, setRegEmail] = React.useState(null);
  const [regPassword, setRegPassword] = React.useState(null);
  const [regPasswordConfirm, setRegPasswordConfirm] = React.useState(null);
  const [regFeedback, setRegFeedback] = React.useState(null);
  const [showRegLoader, setShowRegLoader] = useState(false);

  async function attemptLogin() {
    setShowLoader(true); // Show a loading indicator
    const result = await postRefresh(email, password); // This returns the token data or null
    console.log('tried token and got result:', result);
    if (result?.jwt) {
      hideLoginModal(); // Hide the login modal on successful token refresh
      setFeedback(''); // Clear any feedback message
    } else {
      setFeedback(result.message || `Login failed, code: ${result.message}`); // Set feedback message if available
    }

    setShowLoader(false); // Hide the loading indicator
  }

  async function attemptRegister() {
    setShowRegLoader(true);
    if (regPassword !== regPasswordConfirm) {
      setRegFeedback('Passwords do not match.');
      return;
    }
    const create = await createUser(regName, regEmail, regPassword);
    if (!create.ok) {
      setRegFeedback(create.error || 'Unable to create your profile.');
    } else {
      setRegFeedback('');
      hideLoginModal();
    }
    setShowRegLoader(false);
  }

  const loginModalStyles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
    },

    modalContainer: {
      backgroundColor: theme.colors.secondary,
      alignSelf: 'stretch',
      alignItems: 'center',
      justifyContent: 'center',
      margin: 30,
      borderRadius: 45,
      ...theme.shadows.large,
      paddingHorizontal: 30,
    },

    img: {
      width: 200,
      height: 200,
    },

    login: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.large,
      ...theme.fonts.regular,
      alignSelf: 'flex-start',
    },

    caption: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.small,
      ...theme.fonts.light,
      alignSelf: 'flex-start',
      marginBottom: 5,
    },

    textInput: {
      width: '100%',
    },

    buttonContainer: {
      marginTop: 5,
      flexDirection: 'row',
      alignSelf: 'stretch',
      justifyContent: 'center',
      gap: 10,
    },

    button: {
      flex: 1,
      alignSelf: 'stretch',
      alignItems: 'center',
      justifyContent: 'center',
      height: 50,
      borderRadius: 15,
      ...theme.shadows.small,
    },

    buttonText: {
      fontSize: theme.fontSizes.medium,
      ...theme.fonts.semiBold,
    },

    feedback: {
      marginTop: 5,
      color: theme.colors.red,
      fontSize: theme.fontSizes.small,
      ...theme.fonts.regular,
      marginBottom: Platform.OS === 'android' ? 30 : 30,
    },
  });

  return (
    <Modal
      // transparent={true}
      visible={isModalVisible}
      onRequestClose={null} // Android required back button close
      animationType="fade" // slide fade or none.
      presentationStyle="fullScreen">
      <SafeAreaView style={loginModalStyles.container}>
        <KeyboardAvoidingView style={{width: '100%'}} behavior="padding">
          {/*{!showRegister ? (*/}
          {/*  <View style={loginModalStyles.modalContainer}>*/}
          {/*    <Image style={loginModalStyles.img} source={require('../../assets/images/VerseByVerseLogo.png')} />*/}
          {/*    <Text style={loginModalStyles.login}>Login:</Text>*/}
          {/*    <CustomTextInput*/}
          {/*      onChangeText={text => setEmail(text)}*/}
          {/*      style={loginModalStyles.textInput}*/}
          {/*      borderColor={theme.colors.text}*/}
          {/*      textBackgroundColor={theme.colors.secondary}*/}
          {/*      placeholder="your.email@example.com"*/}
          {/*      label="Email"*/}
          {/*      autoComplete="email"*/}
          {/*      returnKeyType="next"*/}
          {/*      onSubmitEditing={() => passwordRef.current.focus()}*/}
          {/*    />*/}
          {/*    <CustomTextInput*/}
          {/*      onSubmitEditing={() => attemptLogin()}*/}
          {/*      onChangeText={text => setPassword(text)}*/}
          {/*      style={loginModalStyles.textInput}*/}
          {/*      borderColor={theme.colors.text}*/}
          {/*      textBackgroundColor={theme.colors.secondary}*/}
          {/*      placeholder="Your password"*/}
          {/*      label="Password"*/}
          {/*      autoComplete="current-password"*/}
          {/*      secureTextEntry={true}*/}
          {/*      ref={passwordRef}*/}
          {/*    />*/}
          {/*    <View style={loginModalStyles.buttonContainer}>*/}
          {/*      <TouchableOpacity*/}
          {/*        onPress={() => setShowRegister(true)}*/}
          {/*        style={{...loginModalStyles.button, ...{backgroundColor: theme.colors.blue}}}>*/}
          {/*        <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.textLight}}}>Register</Text>*/}
          {/*      </TouchableOpacity>*/}
          {/*      <TouchableOpacity*/}
          {/*        onPress={() => attemptLogin()}*/}
          {/*        disabled={showLoader}*/}
          {/*        style={{...loginModalStyles.button, ...{backgroundColor: theme.colors.green}}}>*/}
          {/*        {showLoader ? (*/}
          {/*          <ActivityIndicator size="small" color={theme.colors.textLight.toString()} />*/}
          {/*        ) : (*/}
          {/*          <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.textLight}}}>Login</Text>*/}
          {/*        )}*/}
          {/*      </TouchableOpacity>*/}
          {/*    </View>*/}
          {/*    <Text style={loginModalStyles.feedback}>{feedback} </Text>*/}
          {/*  </View>*/}
          {/*) : (*/}
          <View style={loginModalStyles.modalContainer}>
            <Image
              style={{width: 150, height: 150, marginTop: 5}}
              source={require('../../assets/images/VerseByVerseLogo.png')}
            />
            <Text style={loginModalStyles.login}>Welcome!</Text>
            <Text style={loginModalStyles.caption}>Please sign up to begin.</Text>
            <CustomTextInput
              onChangeText={text => setRegName(text)}
              style={loginModalStyles.textInput}
              borderColor={theme.colors.text}
              textBackgroundColor={theme.colors.secondary}
              placeholder="John Smith"
              label="Name"
              autoComplete="Name"
              returnKeyType="next"
            />
            <CustomTextInput
              onChangeText={text => setRegEmail(text)}
              style={loginModalStyles.textInput}
              borderColor={theme.colors.text}
              textBackgroundColor={theme.colors.secondary}
              placeholder="email@example.com"
              label="Email"
              keyboardType="email-address"
              ref={regEmailRef}
              returnKeyType="next"
            />
            <CustomTextInput
              onChangeText={text => setRegPassword(text)}
              style={loginModalStyles.textInput}
              borderColor={theme.colors.text}
              textBackgroundColor={theme.colors.secondary}
              placeholder="Your password"
              label="Password"
              secureTextEntry={true}
              ref={regPasswordRef}
              returnKeyType="next"
              autoComplete="new-password"
            />
            <CustomTextInput
              onSubmitEditing={() => attemptRegister()}
              onChangeText={text => setRegPasswordConfirm(text)}
              style={loginModalStyles.textInput}
              borderColor={theme.colors.text}
              textBackgroundColor={theme.colors.secondary}
              placeholder="Confirm Password"
              label="Your Confirmed Password"
              secureTextEntry={true}
              ref={regPasswordConfirmRef}
              autoComplete="new-password"
            />
            <View style={loginModalStyles.buttonContainer}>
              {/*<TouchableOpacity*/}
              {/*  onPress={() => setShowRegister(false)}*/}
              {/*  style={{...loginModalStyles.button, ...{backgroundColor: theme.colors.blue}}}>*/}
              {/*  <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.textLight}}}>Back</Text>*/}
              {/*</TouchableOpacity>*/}
              <TouchableOpacity
                onPress={() => attemptRegister()}
                disabled={showRegLoader}
                style={{...loginModalStyles.button, ...{backgroundColor: theme.colors.green}}}>
                {showRegLoader ? (
                  <ActivityIndicator size="small" color={theme.colors.textLight.toString()} />
                ) : (
                  <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.textLight}}}>Register</Text>
                )}
              </TouchableOpacity>
            </View>
            <Text style={loginModalStyles.feedback}>{regFeedback} </Text>
          </View>
          {/*)}*/}
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
};
