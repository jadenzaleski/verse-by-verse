import React, {useContext} from 'react';
import {View, Text, Button, StyleSheet} from 'react-native';
import ThemeContext from '../../context/ThemeContext';

const ColorPicker = ({navigation}) => {
  const {theme} = useContext(ThemeContext);

  const colorPickerStyles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
    },
  });

  return (
    <View style={colorPickerStyles.container}>
      <Text>Color Picker Screen</Text>
      <Button title="Back to Settings" onPress={() => navigation.goBack()} />
    </View>
  );
};

export default ColorPicker;
