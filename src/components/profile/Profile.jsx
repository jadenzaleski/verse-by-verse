import {StyleSheet, Text, View, Image} from 'react-native';
import * as React from 'react';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import Svg, {Defs, RadialGradient, Rect, Stop} from 'react-native-svg';

const ProfileScreen = () => {
  const {theme, themeSheet} = useContext(ThemeContext);

  const profileStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
    },
    gradientContainer: {
      height: '25%',
      width: '100%',
      backgroundColor: theme.colors.primary,
      ...themeSheet.shadowSmall,
    },
    gradientWrapper: {
      overflow: 'hidden',
    },
    text: {
      marginTop: 20,
      color: theme.colors.text,
      fontSize: 20,
    },
  });

  return (
    <View style={profileStyles.container}>
      <View style={profileStyles.gradientContainer}>
        <Svg style={profileStyles.gradientWrapper}>
          <Defs>
            <RadialGradient id="grad" cx="50%" cy="90%" r="100%" fx="50%" fy="90%" gradientUnits="userSpaceOnUse">
              <Stop offset="0%" stopColor={theme.colors.accent.toString()} stopOpacity="1" />
              <Stop offset="100%" stopColor={theme.colors.primary.toString()} stopOpacity="1" />
            </RadialGradient>
          </Defs>
          <Rect width="100%" height="100%" fill="url(#grad)" />
        </Svg>
      </View>
      <Text style={profileStyles.text}>Hello World</Text>
    </View>
  );
};

export default ProfileScreen;
