import { StyleSheet, Text, View, FlatList, SafeAreaView } from 'react-native';
import * as React from 'react';
import { useContext } from 'react';
import ThemeContext from '../../context/ThemeContext';

const CollectionsScreen = () => {
  const { theme } = useContext(ThemeContext);

  const data = [
    { id: '1', title: 'List 1', targetScreen: 'List1Screen' },
    { id: '2', title: 'List 2', targetScreen: 'List2Screen' },
    { id: '3', title: 'List 3', targetScreen: 'List3Screen' },
  ];

  const collectionsStyles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.primary,
      padding: 30,
      gap: 10,
    },
    title: {
      fontSize: theme.fontSizes.extraLarge,
      color: theme.colors.text,
      ...theme.fonts.regular,
      alignSelf: 'flex-start',
    },

    itemContainer: {
      padding: 16,
      marginVertical: 8,
      backgroundColor: theme.colors.accent || '#ddd',
      borderRadius: 8,
    },
    itemText: {
      color: theme.colors.text || '#000',
      fontSize: 16,
    },
  });

  return (
    <View style={collectionsStyles.container}>
      <Text style={collectionsStyles.title}>Collections</Text>
      <FlatList
        data={data}
        keyExtractor={item => item.id}
        renderItem={({ item }) => (
          // <TouchableOpacity
          //   style={collectionsStyles.itemContainer}
          //   onPress={() => navigation.navigate(item.targetScreen)}
          // >
          <Text style={collectionsStyles.itemText}>{item.title}</Text>
          // </TouchableOpacity>
        )}
      />
    </View>
  );
};

export default CollectionsScreen;
