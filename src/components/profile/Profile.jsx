import {Image, StyleSheet, View, Text} from 'react-native';
import * as React from 'react';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import Svg, {Defs, RadialGradient, Rect, Stop} from 'react-native-svg';
import XPBar from './XP';

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
    shadowContainer: {
      width: 125,
      height: 125,
      borderRadius: 62.5,
      backgroundColor: theme.colors.primary,
      bottom: 62.5,
      alignSelf: 'center',
      justifyContent: 'center',
      alignItems: 'center',
      ...themeSheet.shadowSmall,
    },
    profileImage: {
      width: 125,
      height: 125,
      borderRadius: 62.5,
    },
    title: {
      paddingTop: 62.5 + 20,
      paddingBottom: 20,
      fontSize: theme.fontSizes.extraLarge,
      color: theme.colors.text,
      ...theme.fonts.regular,
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
        <View style={profileStyles.shadowContainer}>
          <Image source={require('../../../assets/images/avatars/me.jpg')} style={profileStyles.profileImage} />
        </View>
      </View>
      <Text style={profileStyles.title}>Jaden Zaleski</Text>
      <View style={{...profileStyles.container, ...{paddingHorizontal: 30}}}>
        <XPBar />
      </View>
    </View>
  );
};

export default ProfileScreen;
