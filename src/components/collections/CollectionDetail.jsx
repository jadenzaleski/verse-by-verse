import { StyleSheet, Text, View, FlatList, TouchableOpacity } from 'react-native';
import * as React from 'react';
import { useCallback, useContext, useEffect, useRef, useState } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import log from '../../utils/Logger';

const CollectionDetail = ({ route }) => {
  const { theme } = useContext(ThemeContext);
  const [refreshing, setRefreshing] = useState(false);
  const { item } = route.params || {}; // Extract the passed `item` data from `route.params`

  const handleRefresh = async () => {
    setRefreshing(true);
    setRefreshing(false);
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
  });

  return (
    <View style={collectionsStyles.container}>
      <Text>Collection: {item.collection_name}</Text>
    </View>
  );
};

export default CollectionDetail;
