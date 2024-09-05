import React, { useContext, useState } from 'react';
import { View, StyleSheet, ActivityIndicator } from 'react-native';
import ThemeContext from '../../context/ThemeContext';
import ColorPicker from 'react-native-wheel-color-picker';

const ColorPickerScreen = ({ navigation }) => {
  const { theme } = useContext(ThemeContext);

  // Initialize state using useState hook
  const [currentColor, setCurrentColor] = useState('#a44646');
  const [swatchesOnly, setSwatchesOnly] = useState(false);
  const [swatchesLast, setSwatchesLast] = useState(false);
  const [swatchesEnabled, setSwatchesEnabled] = useState(false);
  const [discrete, setDiscrete] = useState(false);

  // Handlers for color changes
  const onColorChange = (color) => {
    setCurrentColor(color);
  };

  const onColorChangeComplete = (color) => {
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
      height: 400,
      padding: 0,
      margin: 0,
      gap: 0,
      backgroundColor: theme.colors.secondary,
    }
  });

  return (
    <View style={colorPickerStyles.container}>
      <View style={colorPickerStyles.pickerContainer}>
      <ColorPicker
        ref={r => { this.picker = r }}
        color={currentColor}
        swatchesOnly={false}
        onColorChange={onColorChange}
        onColorChangeComplete={onColorChangeComplete}
        thumbSize={50}
        sliderHidden={false}
        gapSize={0}
        noSnap={true}
        row={false}
        swatchesLast={swatchesLast}
        swatches={false}
        discrete={true}
        wheelLodingIndicator={<ActivityIndicator size={40} />}
        sliderLodingIndicator={<ActivityIndicator size={20} />}
        useNativeDriver={true}
        useNativeLayout={true}
      />
      </View>
    </View>
  );
};

export default ColorPickerScreen;
