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
import { useCallback, useContext, useRef, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import CollectionsListItem from './CollectionsListItem';

const CollectionsScreen = () => {
  const { theme } = useContext(ThemeContext);

  const [data, setData] = useState([
    { id: '1', title: 'List 1', targetScreen: 'List1Screen' },
    { id: '2', title: 'List 2', targetScreen: 'List2Screen' },
    { id: '3', title: 'List 4', targetScreen: 'List3Screen' },
    { id: '4', title: 'List 5', targetScreen: 'List3Screen' },
    { id: '5', title: 'List 6', targetScreen: 'List3Screen' },
    { id: '6', title: 'List 7', targetScreen: 'List3Screen' },
    { id: '7', title: 'List 8', targetScreen: 'List3Screen' },
    { id: '8', title: 'List 9', targetScreen: 'List3Screen' },
    { id: '9', title: 'List 10', targetScreen: 'List3Screen' },
    { id: '10', title: 'List 11', targetScreen: 'List3Screen' },
    { id: '11', title: 'List 12', targetScreen: 'List3Screen' },
    { id: '12', title: 'List 13', targetScreen: 'List3Screen' },
    { id: '13', title: 'List 14', targetScreen: 'List3Screen' },
  ]);

  const collectionsStyles = StyleSheet.create({
    container: {
      flex: 1,
      flexDirection: 'column',
      justifyContent: 'center',
      paddingTop: 75,
      backgroundColor: theme.colors.primary,
      overflow: 'visible',
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
      marginHorizontal: 30,
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
      marginHorizontal: 30,
    },
    list: {
      paddingTop: 15,
      gap: 15,
      overflow: 'visible',
    },
  });

  const handleDeleteItem = id => {
    const updatedData = data.filter(item => item.id !== id);
    setData(updatedData);
  };

  const renderItem = ({ item }) => <CollectionsListItem item={item} onDelete={handleDeleteItem} />;

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
