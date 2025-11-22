import { StyleSheet, Text, View, FlatList, TouchableOpacity } from 'react-native';
import React, { useCallback, useContext, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import log from '../../utils/Logger';
import { useFocusEffect } from '@react-navigation/native';
import Collections from '../../utils/db/Collections';

const CollectionDetail = ({ route }) => {
  const { theme } = useContext(ThemeContext);
  const [refreshing, setRefreshing] = useState(false);
  const { item: routeItem } = route.params || {}; // Avoid variable shadowing
  const [contents, setContents] = useState([]);

  // Fetch collection contents when the screen gains focus
  useFocusEffect(
    useCallback(() => {
      updateContentSet()
        .then(() => log.debug('[CollectionDetail] Updated content set'))
        .catch(error => log.error('[CollectionDetail] Error updating content set:', error));
    }, []),
  );

  // Fetch collection contents from the database
  const updateContentSet = async () => {
    const result = await Collections.getContents(routeItem.collection_id);
    if (result.ok) {
      setContents(Object.values(result.response.rows).filter(row => typeof row === 'object'));
    } else {
      log.error('[CollectionDetail] Failed to get collection content:', result);
    }
  };

  // Handle pull-to-refresh functionality
  const handleRefresh = async () => {
    setRefreshing(true);
    await updateContentSet();
    setRefreshing(false);
  };

  const collectionsStyles = StyleSheet.create({
    container: {
      flex: 1,
      flexDirection: 'column',
      justifyContent: 'center',
      backgroundColor: theme.colors.primary,
    },
    list: {
      padding: 10,
    },
    allBox: {
      padding: 15,
      backgroundColor: theme.colors.secondary,
      marginVertical: 5,
      borderRadius: 8,
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    allTitle: {
      fontSize: theme.fontSizes.subtitle,
      color: theme.colors.text,
    },
  });

  const renderItem = ({ item }) => (
    <TouchableOpacity
      activeOpacity={0.6}
      onPress={() => log.debug('[CollectionDetail] Clicked on item with id:', item.id)}
      style={collectionsStyles.allBox}>
      <View style={collectionsStyles.allDetails}>
        <Text style={collectionsStyles.allTitle}>
          {item.id} - {item.type}
        </Text>
        <Icon color={theme.colors.accent} name={'chevron-forward-outline'} size={25} />
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={collectionsStyles.container}>
      <FlatList
        data={contents}
        renderItem={renderItem}
        keyExtractor={item => item.id}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={collectionsStyles.list}
        onRefresh={handleRefresh}
        refreshing={refreshing}
      />
    </View>
  );
};

export default CollectionDetail;
