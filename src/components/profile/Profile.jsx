import {Image, StyleSheet, View, Text, TouchableOpacity, ScrollView} from 'react-native';
import * as React from 'react';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import Svg, {Defs, RadialGradient, Rect, Stop} from 'react-native-svg';
import XPBar from './XP';
import Icon from '@react-native-vector-icons/ionicons';
import Achievements from './Achievements';
import RecentVerses from './RecentVerses';

const ProfileScreen = () => {
  const {theme} = useContext(ThemeContext);

  const profileStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
      alignSelf: 'stretch',
    },
    buttonContainer: {
      position: 'absolute',
      top: 50,
      right: 30,
      zIndex: 1,
    },
    button: {
      padding: 10,
      paddingRight: 0,
    },
    gradientContainer: {
      height: '15%',
      width: '100%',
      backgroundColor: theme.colors.primary,
      ...theme.shadows.small,
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
      ...theme.shadows.small,
    },
    profileImage: {
      width: 125,
      height: 125,
      borderRadius: 62.5,
    },
    title: {
      marginTop: 62.5 + 20,
      marginBottom: 20,
      fontSize: theme.fontSizes.extraLarge,
      color: theme.colors.text,
      ...theme.fonts.regular,
    },
  });

  return (
    <ScrollView showsVerticalScrollIndicator={false} backgroundColor={theme.colors.primary}>
      <View style={profileStyles.container}>
        <View style={profileStyles.buttonContainer}>
          <TouchableOpacity
            style={profileStyles.button}
            onPress={() => {
              /* Handle button press */
            }}>
            <Icon name="ellipsis-horizontal" color={theme.colors.primary.toString()} size={24} />
          </TouchableOpacity>
        </View>
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
          <Achievements />
          <RecentVerses />
          <View style={{backgroundColor: theme.colors.primary, paddingVertical: 100}} />
        </View>
      </View>
    </ScrollView>
  );
};

export default ProfileScreen;
