import React, {useContext, useState} from 'react';
import {View, StyleSheet, ActivityIndicator, TouchableOpacity, Text} from 'react-native';
import ThemeContext from '../../context/ThemeContext';
import ColorPicker from 'react-native-wheel-color-picker';

const ColorPickerScreen = ({navigation}) => {
  const {theme} = useContext(ThemeContext);

  // Initialize state using useState hook
  const [currentColor, setCurrentColor] = useState('#A2C2BA');

  const onColorChange = (color) => {
    setCurrentColor(color);
  };

  const colorPickerStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
      paddingHorizontal: 30,
    },

    pickerContainer: {
      height: '50%',
      width: '100%',
      backgroundColor: theme.colors.primary,
    },

    currentBox: {
      backgroundColor: theme.colors.accent,
      alignSelf: 'stretch',
      borderRadius: 15,
      height: 75,
      marginVertical: 15,
      alignItems: 'center',
      justifyContent: 'center',
      ...theme.shadows.small
    },
    buttonContainer: {
      flex: 1, flexDirection: 'column', alignSelf: 'stretch', marginBottom: 100,
      alignItems: 'center',
      marginTop: 15,
      gap: 15,
    }, selectionText: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.regular,
    },
    setBox: {
      alignSelf: 'stretch',
      borderRadius: 15,
      height: 75,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: currentColor,
      ...theme.shadows.small

    },
    resetBox: {
      backgroundColor: theme.colors.accent,
      alignSelf: 'stretch',
      borderRadius: 15,
      height: 75,
      alignItems: 'center',
      justifyContent: 'center',
      ...theme.shadows.small
    },

  });

  return (
    <View style={colorPickerStyles.container}>
      <View style={colorPickerStyles.currentBox}><Text style={colorPickerStyles.selectionText}>Current Color</Text></View>
      <View style={colorPickerStyles.pickerContainer}>
        <ColorPicker
          ref={r => {
            this.picker = r;
          }}
          color={currentColor}
          onColorChange={onColorChange}
          onColorChangeComplete={onColorChange}
          thumbSize={50}
          sliderSize={35}
          sliderHidden={false}
          gapSize={0}
          noSnap={true}
          row={false}
          swatches={false}
          discrete={false}
          wheelLodingIndicator={<ActivityIndicator size={40} />}
          sliderLodingIndicator={<ActivityIndicator size={20} />}
          useNativeDriver={true}
          useNativeLayout={true}
        />
      </View>
      <View style={colorPickerStyles.buttonContainer}>
          <TouchableOpacity backgroundColor={'#000'} style={colorPickerStyles.setBox}  >
            <Text style={colorPickerStyles.selectionText}>Set Color</Text>
          </TouchableOpacity>
          <TouchableOpacity style={colorPickerStyles.resetBox}>
            <Text style={colorPickerStyles.selectionText}>Reset to Default Color</Text>
          </TouchableOpacity>
      </View>
    </View>
  );
};

export default ColorPickerScreen;
