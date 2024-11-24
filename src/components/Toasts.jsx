import { useContext } from 'react';
import ThemeContext from '../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import Toast from 'react-native-toast-message';
import * as React from 'react';
import { View, Text, StyleSheet } from 'react-native';

/* eslint-disable react/no-unstable-nested-components */
function CustomToasts() {
  const { theme } = useContext(ThemeContext);
  const toastStyles = StyleSheet.create({
    container: {
      alignSelf: 'stretch',
      top: 15,
      marginHorizontal: 15,
      backgroundColor: theme.colors.secondary,
      borderRadius: 10,
      padding: 10,
      borderLeftWidth: 10,
      ...theme.shadows.small,
    },
    header: {
      ...theme.fonts.semiBold,
      fontSize: theme.fontSizes.medium,
      color: theme.colors.text,
      marginBottom: 3,
    },
    body: {
      ...theme.fonts.regular,
      fontSize: theme.fontSizes.small,
      color: theme.colors.text,
    },
  });

  const toastConfig = {
    success: ({ text1 }) => (
      <View style={{ ...toastStyles.container, ...{ borderColor: theme.colors.green } }}>
        <Text style={toastStyles.header}>Success</Text>
        <Text style={toastStyles.body}>{text1}</Text>
      </View>
    ),

    error: ({ text1 }) => (
      <View style={{ ...toastStyles.container, ...{ borderColor: theme.colors.red } }}>
        <Text style={toastStyles.header}>Error</Text>
        <Text style={toastStyles.body}>{text1}</Text>
      </View>
    ),

    network_error: () => (
      <View style={{ ...toastStyles.container, ...{ borderColor: theme.colors.red } }}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
          <Icon name="cloud-offline-outline" size={20} color={theme.colors.text} style={{ marginBottom: 2 }} />
          <Text style={toastStyles.header}>No Internet Connection</Text>
        </View>
        <Text style={toastStyles.body}>Check your connection and try again.</Text>
      </View>
    ),

    info: ({ text1 }) => (
      <View style={{ ...toastStyles.container, ...{ borderColor: theme.colors.accent } }}>
        <Text style={toastStyles.header}>Info</Text>
        <Text style={toastStyles.body}>{text1}</Text>
      </View>
    ),
  };

  return <Toast config={toastConfig} />;
}

export default CustomToasts;
