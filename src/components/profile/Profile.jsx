import {Image, StyleSheet, View, Text, ScrollView, ActivityIndicator, RefreshControl} from 'react-native';
import * as React from 'react';
import {useCallback, useContext, useState} from 'react';
import ThemeContext from '../../context/ThemeContext';
import Svg, {Defs, RadialGradient, Rect, Stop} from 'react-native-svg';
import XPBar from './XP';
import Icon from '@react-native-vector-icons/ionicons';
import Achievements from './Achievements';
import RecentVerses from './RecentVerses';
import {useFocusEffect} from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {useGetUser} from '../../utils/api/APICalls';
import AuthContext from '../../context/AuthContext';
import Users from '../../utils/db/Users';
import log from '../../utils/Logger';

const ProfileScreen = () => {
  const {theme} = useContext(ThemeContext);
  const [user, setUser] = useState(null);
  const [refreshing, setRefreshing] = useState(false);
  const avatarImages = {
    0: require('../../../assets/images/avatars/crab.png'),
    5: require('../../../assets/images/avatars/crab.png'),
    6: require('../../../assets/images/avatars/crab.png'),
  };

  const updateUser = useCallback(async () => {
    const data = await Users.getUser();
    if (data.ok) {
      log.debug('[Profile] Got user:', data);
      setUser(data.response);
    } else {
      log.error('[Profile] Error getting user:', data);
    }
  }, []);

  // useFocusEffect to call updateUser when the screen is focused
  useFocusEffect(
    useCallback(() => {
      const fetchData = async () => {
        await updateUser();
      };

      fetchData().then(r => {
        log.debug('[Profile] Fetched user');
      }); // Call the async function inside useFocusEffect
    }, [updateUser]),
  );

  // onRefresh function with async/await
  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    log.debug('[Profile] Refreshing...');
    await updateUser(); // Wait for updateUser to complete
    setRefreshing(false); // Set refreshing to false after updateUser completes
  }, [updateUser]);

  const profileStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
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
      height: 200,
      width: '100%',
      backgroundColor: theme.colors.primary,
      ...theme.shadows.small,
      borderTopLeftRadius: 300,
      borderTopRightRadius: 300,
      borderTopWidth: 0,
      borderTopColor: 'transparent',
    },
    gradientWrapper: {
      overflow: 'hidden',
    },
    shadowContainer: {
      width: 125,
      height: 125,
      borderRadius: 62.5,
      backgroundColor: theme.colors.secondary,
      bottom: 62.5,
      alignSelf: 'center',
      justifyContent: 'center',
      alignItems: 'center',
      ...theme.shadows.small,
    },

    profileImage: {
      width: 90,
      height: 90,
      backgroundColor: 'transparent',
    },

    title: {
      marginTop: 62.5 + 20,
      marginBottom: 20,
      fontSize: theme.fontSizes.extraLarge,
      color: theme.colors.text,
      ...theme.fonts.regular,
    },

    loader: {
      backgroundColor: theme.colors.primary,
      flex: 1,
      justifyContent: 'center',
      alignSelf: 'stretch',
    },
  });

  return user ? (
    <ScrollView
      showsVerticalScrollIndicator={false}
      backgroundColor={theme.colors.primary}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}>
      <View style={profileStyles.container}>
        {/*<View style={profileStyles.buttonContainer}>*/}
        {/*  <TouchableOpacity*/}
        {/*    style={profileStyles.button}*/}
        {/*    onPress={() => {*/}
        {/*      /* Handle button press */}
        {/*    }}>*/}
        {/*    <Icon name="ellipsis-horizontal" color={theme.colors.primary.toString()} size={24} />*/}
        {/*  </TouchableOpacity>*/}
        {/*</View>*/}
        <View style={profileStyles.gradientContainer}>
          <Svg style={profileStyles.gradientWrapper}>
            <Defs>
              <RadialGradient id="grad" cx="50%" cy="90%" r="100%" fx="50%" fy="90%" gradientUnits="userSpaceOnUse">
                <Stop offset="0%" stopColor={theme.colors.accent.toString()} stopOpacity="1" />
                <Stop offset="100%" stopColor={theme.colors.primary.toString()} stopOpacity="1" />
              </RadialGradient>
            </Defs>
            <Rect width="100%" height="200" fill="url(#grad)" />
          </Svg>
          <View style={profileStyles.shadowContainer}>
            <Image source={avatarImages[parseInt(user.avatar_id, 10)]} style={profileStyles.profileImage} />
          </View>
        </View>
        <Text style={profileStyles.title}>{user.name}</Text>
        <View style={{...profileStyles.container, ...{paddingHorizontal: 30}}}>
          <XPBar user={user} />
          {/*<Achievements />*/}
          {/*<RecentVerses />*/}
          <View style={{backgroundColor: theme.colors.primary, paddingVertical: 100}} />
        </View>
      </View>
    </ScrollView>
  ) : (
    // The user is being found in storage so we show this
    <ActivityIndicator style={profileStyles.loader} size="small" color={theme.colors.accent.toString()} />
  );
};

export default ProfileScreen;
