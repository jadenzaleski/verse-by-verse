import React, {useContext, useState} from 'react';
import {View, StyleSheet, ActivityIndicator, TouchableOpacity, Text} from 'react-native';
import ThemeContext from '../../context/ThemeContext';
import ColorPicker from 'react-native-wheel-color-picker';

const ColorPickerScreen = ({navigation}) => {
  const {theme, updateAccentColor} = useContext(ThemeContext);

  // Initialize state using useState hook
  const [currentColor, setCurrentColor] = useState(theme.colors.accent);

  // Function to handle setting color
  const handleSetColor = async () => {
    try {
      updateAccentColor(currentColor);
      console.log('Accent color saved:', currentColor);
    } catch (error) {
      console.error('Error saving color:', error);
    }
  };

  // Function to handle resetting color
  const handleResetColor = async () => {
    const defaultColor = '#A2C2BA';
    setCurrentColor(defaultColor);
    try {
      updateAccentColor(defaultColor);
      console.log('Accent color reset to default:', defaultColor);
    } catch (error) {
      console.error('Error resetting color:', error);
    }
  };

  const onColorChange = color => {
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
      ...theme.shadows.small,
    },
    buttonContainer: {
      flex: 1,
      flexDirection: 'column',
      alignSelf: 'stretch',
      marginBottom: 100,
      alignItems: 'center',
      marginTop: 15,
      gap: 15,
    },
    selectionText: {
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
      ...theme.shadows.small,
    },
    resetBox: {
      backgroundColor: theme.colors.accent,
      alignSelf: 'stretch',
      borderRadius: 15,
      height: 75,
      alignItems: 'center',
      justifyContent: 'center',
      ...theme.shadows.small,
    },
  });

  return (
    <View style={colorPickerStyles.container}>
      <View style={colorPickerStyles.currentBox}>
        <Text style={colorPickerStyles.selectionText}>Current Color</Text>
      </View>
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
        <TouchableOpacity style={[colorPickerStyles.setBox, {backgroundColor: currentColor}]} onPress={handleSetColor}>
          <Text style={colorPickerStyles.selectionText}>Set Color</Text>
        </TouchableOpacity>
        <TouchableOpacity style={colorPickerStyles.resetBox} onPress={handleResetColor}>
          <Text style={colorPickerStyles.selectionText}>Reset to Default Color</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default ColorPickerScreen;
