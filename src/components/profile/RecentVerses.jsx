import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import * as React from 'react';
import {Image, Text, View, StyleSheet} from 'react-native';
import ProgressBar from 'react-native-progress/Bar';
import Icon from '@react-native-vector-icons/ionicons';

const RecentVerses = () => {
  const {theme} = useContext(ThemeContext);

  const favoriteVerses = StyleSheet.create({
    container: {
      marginTop: 20,
      alignSelf: 'stretch',
      backgroundColor: theme.colors.primary,
    },
    title: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.regular,
    },
    divider: {
      marginVertical: 5,
      borderBottomColor: theme.colors.secondary,
      borderBottomWidth: 2,
    },
    versesList: {
      flexDirection: 'column',
    },
    verseDivider: {
      marginVertical: 5,
      borderBottomColor: theme.colors.secondary,
      borderBottomWidth: 1,
    },
  });

  return (
    <View style={favoriteVerses.container}>
      <Text style={favoriteVerses.title}>Recent Verses</Text>
      <View style={favoriteVerses.divider} />
      <View style={favoriteVerses.versesList}>
        <Verse
          title={'Romans 9:10-12'}
          verse={
            '10 Not only that, but Rebekah’s children were conceived at the same time' +
            ' by our father Isaac. 11 Yet, before the twins were born or had done anything' +
            ' good or bad—in order that God’s purpose in election might stand: 12 not by' +
            ' works but by him who calls—she was told, “The older will serve the younger.”'
          }
          trans={'ESV'}
        />
        <View style={favoriteVerses.verseDivider} />
        <Verse
          title={'Romans 9:10-12'}
          verse={
            '10 Not only that, but Rebekah’s children were conceived at the same time' +
            ' by our father Isaac. 11 Yet, before the twins were born or had done anything' +
            ' good or bad—in order that God’s purpose in election might stand: 12 not by' +
            ' works but by him who calls—she was told, “The older will serve the younger.”'
          }
          trans={'ESV'}
        />
        <View style={favoriteVerses.verseDivider} />
        <Verse
          title={'Romans 9:10-12'}
          verse={
            '10 Not only that, but Rebekah’s children were conceived at the same time' +
            ' by our father Isaac. 11 Yet, before the twins were born or had done anything' +
            ' good or bad—in order that God’s purpose in election might stand: 12 not by' +
            ' works but by him who calls—she was told, “The older will serve the younger.”'
          }
          trans={'ESV'}
        />
        <View style={favoriteVerses.verseDivider} />
        <Verse
          title={'Romans 9:10-12'}
          verse={
            '10 Not only that, but Rebekah’s children were conceived at the same time' +
            ' by our father Isaac. 11 Yet, before the twins were born or had done anything' +
            ' good or bad—in order that God’s purpose in election might stand: 12 not by' +
            ' works but by him who calls—she was told, “The older will serve the younger.”'
          }
          trans={'ESV'}
        />
        <View style={favoriteVerses.verseDivider} />
        <Verse
          title={'Romans 9:10-12'}
          verse={
            '10 Not only that, but Rebekah’s children were conceived at the same time' +
            ' by our father Isaac. 11 Yet, before the twins were born or had done anything' +
            ' good or bad—in order that God’s purpose in election might stand: 12 not by' +
            ' works but by him who calls—she was told, “The older will serve the younger.”'
          }
          trans={'ESV'}
        />
        <View style={favoriteVerses.verseDivider} />
      </View>
    </View>
  );
};

const Verse = ({title, verse, trans}) => {
  const {theme} = useContext(ThemeContext);

  const verseStyles = StyleSheet.create({
    container: {
      flexDirection: 'row',
      justifyContent: 'flex-start', // Align items at the start
      alignItems: 'flex-start', // Align items vertically at the top
      flexWrap: 'wrap',
      marginVertical: 5,
    },
    dateContainer: {
      marginRight: 10,
      alignItems: 'center',
      flexDirection: 'column',
    },
    dateText: {
      color: theme.colors.accent,
      ...theme.fonts.bold,
      fontSize: theme.fontSizes.medium,
      lineHeight: theme.fontSizes.medium + 1,
    },
    infoContainer: {
      flex: 1, // Take up the remaining space
      flexDirection: 'column',
    },
    title: {
      color: theme.colors.text,
      ...theme.fonts.semiBold,
      fontSize: theme.fontSizes.medium,
    },
    sample: {
      marginTop: 2,
      color: theme.colors.text,
      ...theme.fonts.regular,
      fontSize: theme.fontSizes.small,
    },
    barBox: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    progressBar: {
      flex: 1,
      backgroundColor: theme.colors.secondary,
      marginRight: 10,
    },
    percent: {
      color: theme.colors.accent,
      ...theme.fonts.semiBold,
      fontSize: theme.fontSizes.medium,
    },
    statsBox: {
      flexDirection: 'row',
      alignItems: 'center',
    },
    target: {
      width: 24,
      height: 24,
      tintColor: theme.colors.accent,
    },
    statText: {
      marginRight: 20,
      marginLeft: 3,
      color: theme.colors.text,
      ...theme.fonts.semiBold,
      fontSize: theme.fontSizes.medium,
    },
  });
  return (
    <View style={verseStyles.container}>
      <View style={verseStyles.dateContainer}>
        <Icon name="calendar-outline" color={theme.colors.accent.toString()} size={36} />
        <Text style={verseStyles.dateText}>Mar</Text>
        <Text style={verseStyles.dateText}>24</Text>
      </View>
      <View style={verseStyles.infoContainer}>
        <Text style={verseStyles.title}>
          {title} ({trans})
        </Text>
        <Text numberOfLines={2} style={verseStyles.sample}>
          {verse}
        </Text>
        <View style={verseStyles.barBox}>
          <ProgressBar
            progress={0.8}
            width={null}
            height={6}
            color={theme.colors.accent}
            borderWidth={0}
            borderRadius={3}
            style={verseStyles.progressBar}
          />
          <Text style={verseStyles.percent}>80%</Text>
        </View>
        <View style={verseStyles.statsBox}>
          <Icon name="checkmark" color={theme.colors.accent.toString()} size={24} />
          <Text style={verseStyles.statText}>12</Text>
          <Image source={require('../../../assets/images/target2.png')} style={verseStyles.target} />
          <Text style={verseStyles.statText}>87%</Text>
          <Icon name="calendar-outline" color={theme.colors.accent.toString()} size={24} />
          <Text style={verseStyles.statText}>08/30/2002</Text>
        </View>
      </View>
    </View>
  );
};

export default RecentVerses;
