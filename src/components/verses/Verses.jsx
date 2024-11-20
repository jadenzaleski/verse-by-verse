import {StyleSheet, Text, View, FlatList, TouchableOpacity, SafeAreaView} from 'react-native';
import * as React from 'react';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';

const VersesScreen = () => {
  const {theme} = useContext(ThemeContext);

  const data = [
    {id: '1', title: 'List 1', targetScreen: 'List1Screen'},
    {id: '2', title: 'List 2', targetScreen: 'List2Screen'},
    {id: '3', title: 'List 3', targetScreen: 'List3Screen'},
  ];

  const versesStyles = StyleSheet.create({
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
    <SafeAreaView style={{flex: 1, backgroundColor: theme.colors.background}}>
      <View style={versesStyles.container}>
        <Text style={versesStyles.title}>Collections</Text>
        <FlatList
          data={data}
          keyExtractor={item => item.id}
          renderItem={({item}) => (
            // <TouchableOpacity
            //   style={versesStyles.itemContainer}
            //   onPress={() => navigation.navigate(item.targetScreen)}
            // >
            <Text style={versesStyles.itemText}>{item.title}</Text>
            // </TouchableOpacity>
          )}
        />
      </View>
    </SafeAreaView>
  );
};

export default VersesScreen;
