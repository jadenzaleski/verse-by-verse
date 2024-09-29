import React, {useContext, useRef} from 'react';
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
} from 'react-native';
import AuthContext from '../context/AuthContext';
import ThemeContext from '../context/ThemeContext';
import CustomTextInput from './CustomTextInputs';

export const LoginModal = () => {
  const {isModalVisible, hideLoginModal} = useContext(AuthContext);
  const {theme} = useContext(ThemeContext);
  const passwordRef = useRef();
  // Simulate login process and close modal with success
  const handleLogin = () => {
    // Simulate successful login and close modal with "true"
    hideLoginModal(true);
  };

  // Handle modal close without login
  const handleClose = () => {
    // Close modal without login, pass "false"
    hideLoginModal(false);
  };

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
      marginBottom: Platform.OS === 'android' ? 30 : 30,
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
    }
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
          <View style={loginModalStyles.modalContainer}>
            <Image style={loginModalStyles.img} source={require('../../assets/images/VerseByVerseLogo.png')} />
            <Text style={loginModalStyles.login}>Login:</Text>
            <CustomTextInput
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
              <TouchableOpacity style={{...loginModalStyles.button, ...{borderColor: theme.colors.blue}}}>
                <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.blue}}}>Register</Text>
              </TouchableOpacity>
              <TouchableOpacity style={{...loginModalStyles.button, ...{borderColor: theme.colors.green}}} >
                <Text style={{...loginModalStyles.buttonText, ...{color: theme.colors.green}}}>Login</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
};
