import { StyleSheet, Text, View, FlatList, TouchableOpacity } from 'react-native';
import * as React from 'react';
import { useCallback, useContext, useEffect, useRef, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import CollectionsListItem from './CollectionsListItem';
import Collections from '../../utils/db/Collections';
import { useFocusEffect } from '@react-navigation/native';
import log from '../../utils/Logger';
import CustomSheetModal from '../CustomSheetModal';
import CustomTextInput from '../CustomTextInputs';

const CollectionsScreen = ({ navigation }) => {
  const { theme } = useContext(ThemeContext);
  const [collections, setCollections] = useState([]);
  const [isAddModalVisible, setAddModalVisible] = useState(false);
  const [newName, setNewName] = React.useState(null);
  const [nameBorderColor, setNameBorderColor] = React.useState(theme.colors.secondary);
  const [refreshing, setRefreshing] = useState(false);

  useFocusEffect(
    useCallback(() => {
      updateCollectionSet()
        .then(() => log.debug('[Collections] Updated collections'))
        .catch(error => log.error('[Collections] Error updating collections:', error));
    }, []),
  );

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await updateCollectionSet();
    } catch (error) {
      log.error('[Collections] Error refreshing collections:', error);
    } finally {
      setRefreshing(false);
    }
  };

  const updateCollectionSet = async () => {
    const result = await Collections.getAll();
    if (result.ok) {
      const rowsArray = Object.values(result.response.rows).filter(item => typeof item === 'object');
      setCollections(rowsArray);
    } else {
      log.error('[Collections] Failed to get all collections:', result);
    }
  };

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

  const handleAddCollection = async collectionName => {
    if (!collectionName || collectionName.trim() === '') {
      log.error('[Collections] Collection name cannot be empty');
      setNameBorderColor(theme.colors.red);
      return; // Exit the function early
    } else {
      setNameBorderColor(theme.colors.secondary);
    }
    try {
      const result = await Collections.add(collectionName.trim());
      if (result.ok) {
        await updateCollectionSet();
      } else {
        log.error('[Collections] Failed to add collection');
      }
    } catch (error) {
      log.error('[Collections] Error adding collection:', error);
    }
    setAddModalVisible(false);
  };

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

  const renderItem = ({ item }) => (
    <CollectionsListItem navigation={navigation} item={item} onDelete={handleDeleteItem} />
  );

  return (
    <View style={collectionsStyles.container}>
      <View style={collectionsStyles.titleBox}>
        <Text style={collectionsStyles.title}>Collections</Text>
        <View style={collectionsStyles.titleButtonBox}>
          <TouchableOpacity activeOpacity={0.6} onPress={() => setAddModalVisible(true)}>
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
        onRefresh={handleRefresh}
        refreshing={refreshing}
      />

      <CustomSheetModal
        visible={isAddModalVisible}
        onClose={() => setAddModalVisible(false)}
        onSave={() => handleAddCollection(newName)}
        title="Add Collection"
        saveButtonText="Add">
        <CustomTextInput
          borderColor={nameBorderColor}
          label="Collection Name"
          placeholder={'New Collection'}
          onChangeText={text => {
            setNewName(text);
            if (text.trim() === '') setNameBorderColor(theme.colors.red);
            else setNameBorderColor(theme.colors.secondary);
          }}
        />
      </CustomSheetModal>
    </View>
  );
};

export default CollectionsScreen;
