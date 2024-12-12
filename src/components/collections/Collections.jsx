import {
  StyleSheet,
  Text,
  View,
  FlatList,
  SafeAreaView,
  RefreshControl,
  TouchableOpacity,
  Image,
  Switch,
  ScrollView,
} from 'react-native';
import * as React from 'react';
import { useCallback, useContext, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';

const CollectionsScreen = () => {
  const { theme } = useContext(ThemeContext);

  const data = [
    { id: '1', title: 'List 1', targetScreen: 'List1Screen' },
    { id: '2', title: 'List 2', targetScreen: 'List2Screen' },
    { id: '3', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '4', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '5', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '6', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '7', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '8', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '9', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '10', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '11', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '12', title: 'List 3', targetScreen: 'List3Screen' },
    { id: '13', title: 'List 3', targetScreen: 'List3Screen' },
  ];

  const collectionsStyles = StyleSheet.create({
    container: {
      flex: 1,
      flexDirection: 'column',
      justifyContent: 'center',
      paddingHorizontal: 30,
      paddingTop: 75,
      backgroundColor: theme.colors.primary,
    },
    title: {
      marginBottom: 5,
      textTransform: 'uppercase',
      color: theme.colors.text,
      fontSize: theme.fontSizes.extraLarge,
      ...theme.fonts.light,
    },
    titleBox: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    titleButtonBox: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      gap: 5,
    },
    titleButton: {
      color: theme.colors.accent,
      padding: 1,
    },
    divider: {
      borderBottomColor: theme.colors.secondary,
      borderBottomWidth: 2,
    },

    list: {
      paddingTop: 15,
      gap: 15,
    },

    collectionBox: {
      flexDirection: 'row',
      alignSelf: 'stretch',
      backgroundColor: theme.colors.secondary,
      padding: 25,
      borderRadius: 20,
      alignItems: 'center',
      justifyContent: 'space-between',
    },

    collectionTitle: {
      color: theme.colors.text,
      ...theme.fonts.medium,
      fontSize: theme.fontSizes.subtitle,
    },

    chevronIcon: {
      color: theme.colors.accent,
    },
  });

  const renderItem = ({ item }) => (
    <TouchableOpacity activeOpacity={0.6} style={collectionsStyles.collectionBox}>
      <Text style={collectionsStyles.collectionTitle}>TESTER collection</Text>
      <Icon color={theme.colors.accent} name={'chevron-forward-outline'} size={25} />
    </TouchableOpacity>
  );

  return (
    <View style={collectionsStyles.container}>
      <View style={collectionsStyles.titleBox}>
        <Text style={collectionsStyles.title}>Collections</Text>
        <View style={collectionsStyles.titleButtonBox}>
          <TouchableOpacity activeOpacity={0.6}>
            <Icon style={collectionsStyles.titleButton} name={'add-outline'} size={32} />
          </TouchableOpacity>
          <TouchableOpacity activeOpacity={0.6}>
            <Icon
              style={collectionsStyles.titleButton}
              color={theme.colors.text}
              name={'information-outline'}
              size={32}
            />
          </TouchableOpacity>
        </View>
      </View>
      <View style={collectionsStyles.divider} />

      <FlatList
        data={data}
        renderItem={renderItem}
        keyExtractor={item => item.id}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={collectionsStyles.list}
      />
    </View>
  );
};

export default CollectionsScreen;
