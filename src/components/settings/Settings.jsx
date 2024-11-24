import { ScrollView, StyleSheet, Text, TouchableOpacity, View, Image, RefreshControl, Switch } from 'react-native';
import { useCallback, useContext, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import * as React from 'react';
import Icon from '@react-native-vector-icons/ionicons';

const SettingsScreen = ({ navigation }) => {
  const { theme, themeName, toggleTheme, useSystemTheme, isBold, toggleBold } = useContext(ThemeContext);
  const [themeNum, setThemeNum] = useState(0);
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    console.log('Refreshing...');
    setRefreshing(false);
  }, []);

  function UseSystemTheme() {
    useSystemTheme();
  }

  function HandleNextTheme() {
    if (themeNum === 0) {
      toggleTheme('dark');
    } else if (themeNum === 1) {
      UseSystemTheme();
    } else {
      toggleTheme('light');
    }
    if (themeNum < 2) {
      setThemeNum(themeNum + 1);
    } else {
      setThemeNum(0);
    }
  }

  const getIconName = () => {
    switch (themeNum) {
      case 1:
        return 'moon-outline'; // Dark theme icon
      case 2:
        return 'phone-portrait-outline'; // System theme icon
      case 0:
        return 'sunny-outline'; // Light theme icon
      default:
        return 'sunny-outline'; // Default icon
    }
  };

  const settingsStyles = StyleSheet.create({
    container: {
      flex: 1,
      flexDirection: 'column',
      justifyContent: 'center',
      marginHorizontal: 30,
      marginTop: 75,
      backgroundColor: theme.colors.primary,
    },
    title: {
      marginBottom: 5,
      alignSelf: 'center',
      textTransform: 'uppercase',
      color: theme.colors.text,
      fontSize: theme.fontSizes.extraLarge,
      ...theme.fonts.light,
    },
    divider: {
      borderBottomColor: theme.colors.secondary,
      borderBottomWidth: 2,
    },
    header: {
      marginTop: 25,
      textTransform: 'uppercase',
      color: theme.colors.text,
      fontSize: theme.fontSizes.regular,
      ...theme.fonts.medium,
    },
    itemContainer: {
      flexDirection: 'row',
      alignSelf: 'stretch',
      backgroundColor: theme.colors.secondary,
      padding: 15,
      borderRadius: 15,
      alignItems: 'center',
      marginVertical: 5,
    },
    itemIcon: {
      marginRight: 10,
      overflow: 'hidden',
      width: 25,
      height: 25,
    },
    itemText: {
      color: theme.colors.text,
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.regular,
      textTransform: 'capitalize',
    },
    itemButton: {
      marginLeft: 'auto',
      color: theme.colors.accent,
    },
    accentColorContainer: {
      marginLeft: 'auto',
      width: 25,
      height: 25,
      borderRadius: 20,
      borderColor: theme.colors.text,
      borderWidth: 1,
      alignItems: 'center',
      justifyContent: 'center',
    },

    accentColorCircle: {
      backgroundColor: theme.colors.accent,
      width: 15,
      height: 15,
      borderRadius: 15,
    },
  });

  return (
    <ScrollView
      showsVerticalScrollIndicator={false}
      backgroundColor={theme.colors.primary}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}>
      <View style={settingsStyles.container}>
        <Text style={settingsStyles.title}>Settings</Text>
        <View style={settingsStyles.divider} />
        <Text style={settingsStyles.header}>appearance</Text>
        <TouchableOpacity activeOpacity={0.6} onPress={HandleNextTheme} style={settingsStyles.itemContainer}>
          <Image
            source={require('../../../assets/images/dayNight.png')}
            style={settingsStyles.itemIcon}
            name={'color-fill-outline'}
            size={25}
          />
          <Text style={settingsStyles.itemText}>theme</Text>
          <Icon style={settingsStyles.itemButton} name={getIconName()} size={25} />
        </TouchableOpacity>
        <TouchableOpacity
          activeOpacity={0.6}
          style={settingsStyles.itemContainer}
          onPress={() => navigation.navigate('ColorPicker')}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.accent} name={'color-palette-outline'} size={25} />
          <Text style={settingsStyles.itemText}>accent color</Text>
          <View style={settingsStyles.accentColorContainer}>
            <View style={settingsStyles.accentColorCircle} />
          </View>
        </TouchableOpacity>
        <View style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.text} name={'text-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Bold text</Text>
          <Switch
            style={settingsStyles.itemButton}
            trackColor={{ true: theme.colors.green, false: theme.colors.primary }}
            thumbColor={theme.colors.textLight}
            ios_backgroundColor={themeName === 'light' ? theme.colors.secondary : theme.colors.primary}
            onValueChange={toggleBold}
            value={isBold}
          />
        </View>

        <Text style={settingsStyles.header}>Notifications</Text>
        <View style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.blue} name={'hourglass-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Practice Reminders</Text>
          <Switch
            style={settingsStyles.itemButton}
            trackColor={{ true: theme.colors.green, false: theme.colors.primary }}
            thumbColor={theme.colors.textLight}
            ios_backgroundColor={themeName === 'light' ? theme.colors.secondary : theme.colors.primary}
            value={false}
          />
        </View>
        <View style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.text} name={'time-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Daily Verse: </Text>
          <TouchableOpacity activeOpacity={0.6}>
            <Text style={{ ...settingsStyles.itemText, ...{ color: theme.colors.blue } }}>23:59pm</Text>
          </TouchableOpacity>
          <Switch
            style={settingsStyles.itemButton}
            trackColor={{ true: theme.colors.green, false: theme.colors.primary }}
            thumbColor={theme.colors.textLight}
            ios_backgroundColor={themeName === 'light' ? theme.colors.secondary : theme.colors.primary}
            value={false}
          />
        </View>

        <Text style={settingsStyles.header}>resources</Text>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.yellow} name={'star-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Rate in App Store</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.red} name={'bug-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Report a Bug</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.blue} name={'mail-outline'} size={25} />
          <Text style={settingsStyles.itemText}>contact</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.text} name={'logo-github'} size={25} />
          <Text style={settingsStyles.itemText}>Contribute</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.green} name={'lock-closed-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Privacy policy</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon
            style={settingsStyles.itemIcon}
            color={theme.colors.text}
            name={'information-circle-outline'}
            size={25}
          />
          <Text style={settingsStyles.itemText}>about</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>

        <Text style={settingsStyles.header}>user data</Text>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.text} name={'download-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Export/import Data</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>
        <TouchableOpacity activeOpacity={0.6} style={settingsStyles.itemContainer}>
          <Icon style={settingsStyles.itemIcon} color={theme.colors.red} name={'trash-outline'} size={25} />
          <Text style={settingsStyles.itemText}>Delete Account</Text>
          <Icon style={settingsStyles.itemButton} name={'chevron-forward'} size={25} />
        </TouchableOpacity>

        {/*bottom padding*/}
        <View style={{ marginVertical: 50 }} />
      </View>
    </ScrollView>
  );
};

export default SettingsScreen;
