import { StyleSheet, Text, View, FlatList, TouchableOpacity } from 'react-native';
import * as React from 'react';
import { useCallback, useContext, useEffect, useRef, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import CollectionsListItem from './CollectionsListItem';
import Collections from '../../utils/db/Collections';
import { useFocusEffect } from '@react-navigation/native';
import log from '../../utils/Logger';

const CollectionsScreen = () => {
  const { theme } = useContext(ThemeContext);
  const [collections, setCollections] = useState([]);
  useFocusEffect(
    useCallback(() => {
      const fetchData = async () => {
        const result = await Collections.getAll();
        if (result.ok) {
          const rowsArray = Object.values(result.response.rows).filter(item => typeof item === 'object');
          setCollections(rowsArray);
        } else {
          log.error('[Collections] Failed to fetch collections:', result);
          setCollections([]);
        }
      };

      fetchData().then(() => log.debug('[Collections] Fetched collections'));
    }, []),
  );

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

  const handleDeleteItem = async collection_id => {
    try {
      // Perform the delete operation
      const result = await Collections.delete(collection_id);
      if (result.ok) {
        // Update state after successful delete
        setCollections(prevCollections => prevCollections.filter(item => item.collection_id !== collection_id));
      } else {
        log.error('[Collections] Failed to delete collection');
      }
    } catch (error) {
      log.error('[Collections] Error deleting collection:', error);
    }
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
        data={collections}
        renderItem={renderItem}
        keyExtractor={item => item.collection_id}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={collectionsStyles.list}
      />
    </View>
  );
};

export default CollectionsScreen;
