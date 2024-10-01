import React, {useContext, useRef, useState} from 'react';
import {
  Modal,
  View,
  Text,
  Button,
  StyleSheet,
  SafeAreaView,
  Image,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import AuthContext from '../context/AuthContext';
import ThemeContext from '../context/ThemeContext';
import CustomTextInput from './CustomTextInputs';
import {refreshToken} from '../utils/api/APICalls';

export const LoginModal = () => {
  const {isModalVisible, hideLoginModal} = useContext(AuthContext);
  const {theme} = useContext(ThemeContext);

  const passwordRef = useRef();
  const [showLoader, setShowLoader] = useState(false);
  const [email, setEmail] = React.useState(null);
  const [password, setPassword] = React.useState(null);
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
    setShowLoader(true);
    const {response, data} = await refreshToken(email, password); // Destructure response and data
    if (response && response.ok) {
      hideLoginModal();
      setFeedback(' ');
    } else {
      console.log('Error refreshing token:', data);
      setFeedback(data?.message); // Set feedback message
    }
    setShowLoader(false);
  }

  async function attemptRegister() {
    setShowRegLoader(true);

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
      borderWidth: 2,
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
        <KeyboardAvoidingView style={{width: '100%'}} behavior={Platform.OS === 'ios' ? 'padding' : 'padding'}>
          {!showRegister ? (
            <View style={loginModalStyles.modalContainer}>
              <Image style={loginModalStyles.img} source={require('../../assets/images/VerseByVerseLogo.png')} />
              <Text style={loginModalStyles.login}>Login:</Text>
              <CustomTextInput
                onChangeText={text => setEmail(text)}
                style={loginModalStyles.textInput}
                borderColor={theme.colors.text}
                textBackgroundColor={theme.colors.secondary}
                placeholder="your.email@example.com"
                label="Email"
                autoComplete="email"
                returnKeyType="next"
                onSubmitEditing={() => passwordRef.current.focus()}
              />
              <CustomTextInput
                onSubmitEditing={attemptLogin}
                onChangeText={text => setPassword(text)}
                style={loginModalStyles.textInput}
                borderColor={theme.colors.text}
                textBackgroundColor={theme.colors.secondary}
                placeholder="Your passphrase"
                label="Password"
                autoComplete="current-password"
                secureTextEntry={true}
                ref={passwordRef}
              />
              <View style={loginModalStyles.buttonContainer}>
                <TouchableOpacity
                  onPress={() => setShowRegister(true)}
                  style={{...loginModalStyles.button, ...{borderColor: theme.colors.blue}}}>
                  <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.blue}}}>Register</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => attemptLogin()}
                  disabled={showLoader}
                  style={{...loginModalStyles.button, ...{borderColor: theme.colors.green}}}>
                  {showLoader ? (
                    <ActivityIndicator size="small" color={theme.colors.green.toString()} />
                  ) : (
                    <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.green}}}>Login</Text>
                  )}
                </TouchableOpacity>
              </View>
              <Text style={loginModalStyles.feedback}>{feedback} </Text>
            </View>
          ) : (
            <View style={loginModalStyles.modalContainer}>
              <Image style={loginModalStyles.img} source={require('../../assets/images/VerseByVerseLogo.png')} />
              <Text style={loginModalStyles.login}>Register:</Text>
              <CustomTextInput
                onChangeText={text => setRegName(text)}
                style={loginModalStyles.textInput}
                borderColor={theme.colors.text}
                textBackgroundColor={theme.colors.secondary}
                placeholder="John Smith"
                label="Name"
                autoComplete="Name"
                secureTextEntry={false}
                returnKeyType="next"
              />
              <CustomTextInput
                onChangeText={text => setRegEmail(text)}
                style={loginModalStyles.textInput}
                borderColor={theme.colors.text}
                textBackgroundColor={theme.colors.secondary}
                placeholder="youremail@example.com"
                label="Email"
                autoComplete="email"
                secureTextEntry={false}
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
                autoComplete="new-password"
                secureTextEntry={true}
                ref={regPasswordRef}
                returnKeyType="next"
              />
              <CustomTextInput
                onChangeText={text => setRegPasswordConfirm(text)}
                style={loginModalStyles.textInput}
                borderColor={theme.colors.text}
                textBackgroundColor={theme.colors.secondary}
                placeholder="Confirm Password"
                label="Your Confirmed Password"
                autoComplete="new-password"
                secureTextEntry={true}
                ref={regPasswordConfirmRef}
              />
              <View style={loginModalStyles.buttonContainer}>
                <TouchableOpacity
                  onPress={() => setShowRegister(false)}
                  style={{...loginModalStyles.button, ...{borderColor: theme.colors.blue}}}>
                  <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.blue}}}>Back</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => attemptRegister()}
                  disabled={showRegLoader}
                  style={{...loginModalStyles.button, ...{borderColor: theme.colors.green}}}>
                  {showRegLoader ? (
                    <ActivityIndicator size="small" color={theme.colors.green.toString()} />
                  ) : (
                    <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.green}}}>Register</Text>
                  )}
                </TouchableOpacity>
              </View>
              <Text style={loginModalStyles.feedback}>{regFeedback} </Text>
            </View>
          )}
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
};
