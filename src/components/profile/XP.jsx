import {StyleSheet, View, Text} from 'react-native';
import * as React from 'react';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import ProgressBar from 'react-native-progress/Bar';
import Icon from '@react-native-vector-icons/ionicons';

const XPBar = ({user}) => {
  const {theme} = useContext(ThemeContext);

  const xpStyles = StyleSheet.create({
    container: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    numberContainer: {
      width: 55,
      height: 55,
      borderRadius: 27.5,
      borderWidth: 4,
      borderColor: theme.colors.accent,
      backgroundColor: theme.colors.primary,
      justifyContent: 'center',
      alignItems: 'center',
      marginRight: 10,
    },
    numberText: {
      fontSize: theme.fontSizes.medium + 5,
      color: theme.colors.text,
      ...theme.fonts.regular,
    },
    detailsContainer: {
      flex: 1,
    },
    xpNumber: {
      marginRight: 2,
      fontSize: theme.fontSizes.medium,
      color: theme.colors.accent,
      ...theme.fonts.bold,
    },
    xpText: {
      fontSize: theme.fontSizes.small,
      color: theme.colors.text,
      ...theme.fonts.regular,
      borderWidth: 1,
      borderColor: theme.colors.text,
      borderRadius: 5,
      padding: 1,
    },
    progressBar: {
      marginVertical: 5,
      width: '100%',
      backgroundColor: theme.colors.secondary,
    },
    levelText: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.medium,
      ...theme.fonts.regular,
    },
    levelContainer: {
      flexDirection: 'row',
      justifyContent: 'space-between',
    },
  });

  return (
    <View style={xpStyles.container}>
      <View style={xpStyles.numberContainer}>
        <Text style={xpStyles.numberText}>123</Text>
      </View>
      <View style={xpStyles.detailsContainer}>
        <View style={{flexDirection: 'row', alignItems: 'center'}}>
          <Text style={xpStyles.xpNumber}>{user.xp}</Text>
          <Icon name="sparkles" color={theme.colors.accent.toString()} size={14} />
        </View>
        <ProgressBar
          progress={0.6}
          width={null}
          height={10}
          color={theme.colors.accent}
          borderWidth={0}
          borderRadius={5}
          style={xpStyles.progressBar}
        />
        <View style={xpStyles.levelContainer}>
          <Text style={xpStyles.levelText}>Level 5</Text>
          <Text style={xpStyles.levelText}> 120k until Level 6</Text>
        </View>
      </View>
    </View>
  );
};

export default XPBar;
