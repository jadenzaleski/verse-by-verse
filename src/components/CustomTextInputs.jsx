import React, { forwardRef, useContext } from 'react';
import { View, TextInput, Text, StyleSheet, Platform } from 'react-native';
import ThemeContext from '../context/ThemeContext';

const CustomTextInput = forwardRef(
  (
    {
      label,
      value,
      onChangeText,
      borderColor = '#000', // Default border color
      textBackgroundColor = '#000',
      placeholder,
      style = {},
      secureTextEntry = false, // Option to hide text (for password fields)
      keyboardType = 'default', // Set the type of keyboard
      autoComplete = 'off', // Option to turn off autocomplete
      ...props
    },
    ref,
  ) => {
    const { theme } = useContext(ThemeContext);

    const CTIStyles = StyleSheet.create({
      container: {
        marginVertical: 10,
      },
      label: {
        position: 'absolute',
        top: -8,
        left: 10,
        backgroundColor: textBackgroundColor, // Ensure label doesn't overlap the border
        paddingHorizontal: 5,
        zIndex: 1,
        fontSize: theme.fontSizes.small,
        color: theme.colors.text,
        ...theme.fonts.regular,
      },
      input: {
        borderWidth: 1,
        borderRadius: 15,
        borderColor: borderColor,
        paddingHorizontal: 15,
        paddingVertical: 15,
        fontSize: theme.fontSizes.medium,
        color: theme.colors.text,
        ...theme.fonts.medium,
      },
    });

    return (
      <View style={{ ...style, ...CTIStyles.container }}>
        {label && <Text style={CTIStyles.label}>{label}</Text>}
        <TextInput
          ref={ref}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={Platform.OS === 'ios' ? theme.colors.text + '100' : '#ffffff40'}
          secureTextEntry={secureTextEntry} // Hides the text if true
          keyboardType={keyboardType} // Specifies the keyboard type
          autoComplete={autoComplete} // Controls autocomplete behavior
          style={CTIStyles.input} // Dynamic border color
          {...props}
        />
      </View>
    );
  },
);

export default CustomTextInput;
