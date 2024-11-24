import { StyleSheet, View, Text, Image, TouchableOpacity } from 'react-native';
import * as React from 'react';
import { useContext } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';

const Achievements = () => {
  const { theme } = useContext(ThemeContext);

  const achievementsStyles = StyleSheet.create({
    container: {
      width: '100%',
      flexDirection: 'column',
      justifyContent: 'space-between',
    },
    title: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.regular,
      marginTop: 20,
    },
    achievementsList: {
      flexDirection: 'row',
      justifyContent: 'flex-start',
      alignItems: 'center',
      overflow: 'hidden',
      paddingLeft: 42.5,
    },
    box: {
      marginTop: 5,
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      borderColor: theme.colors.secondary,
      borderWidth: 2,
      borderRadius: 15,
      padding: 15,
    },
    achievement: {
      width: 85,
      height: 85,
      borderRadius: 42.5,
      borderColor: theme.colors.secondary,
      borderWidth: 4,
      backgroundColor: theme.colors.primary,
      ...theme.shadows.small,
      marginLeft: -42.5,
    },
  });

  return (
    <View style={achievementsStyles.container}>
      <Text style={achievementsStyles.title}>Achievements</Text>
      <TouchableOpacity
        activeOpacity={1}
        onPress={() => {
          /* Handle button press */
          console.log('go to achievements');
        }}
        style={achievementsStyles.box}>
        {/*max is 6*/}
        <View style={achievementsStyles.achievementsList}>
          <Image source={require('../../../assets/images/avatars/bear.png')} style={achievementsStyles.achievement} />
          <Image source={require('../../../assets/images/avatars/bear.png')} style={achievementsStyles.achievement} />
          <Image source={require('../../../assets/images/avatars/bear.png')} style={achievementsStyles.achievement} />
          <Image source={require('../../../assets/images/avatars/bear.png')} style={achievementsStyles.achievement} />
          <Image source={require('../../../assets/images/avatars/bear.png')} style={achievementsStyles.achievement} />
          <Image source={require('../../../assets/images/avatars/bear.png')} style={achievementsStyles.achievement} />
        </View>
        <Icon name="chevron-forward" color={theme.colors.accent.toString()} size={28} />
      </TouchableOpacity>
    </View>
  );
};

export default Achievements;
