import React, { useContext, useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { createStackNavigator } from '@react-navigation/stack';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import CollectionsScreen from './Collections';
import CollectionDetail from './CollectionDetail';
import log from '../../utils/Logger';
import AddModal from './AddModal';

const Stack = createStackNavigator();

const CollectionsNavigator = () => {
  const { theme } = useContext(ThemeContext);
  const DEFAULT_COLLECTION_TITLE = 'Collection Detail';
  const [add, setAdd] = useState(false);

  const navigatorStyles = StyleSheet.create({
    headerTitle: {
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.medium,
      color: theme.colors.text,
    },
    header: {
      backgroundColor: theme.colors.primary,
      borderWidth: 0,
      borderColor: theme.colors.primary,
      shadowColor: 'transparent',
    },
    backButton: {
      color: theme.colors.accent,
      fontSize: theme.fontSizes.subtitle,
      ...theme.fonts.medium,
    },
    backButtonIcon: {
      marginLeft: 0,
    },
    headerButtonsContainer: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: 7,
      marginRight: 10,
    },
  });

  const renderHeaderTitle = (route, styles) => {
    const collectionName = route.params.item.collection_name ?? DEFAULT_COLLECTION_TITLE;
    // Truncate the title if it's too long
    const truncateTitle = (title, maxLength) => (title.length > maxLength ? `${title.slice(0, maxLength)}...` : title);

    const truncatedName = truncateTitle(collectionName, 20); // Limit to 20 characters

    return <Text style={styles.headerTitle}>{truncatedName}</Text>;
  };

  const renderBackImage = () => (
    <Icon style={navigatorStyles.backButtonIcon} color={theme.colors.accent} name={'chevron-back-outline'} size={25} />
  );

  const renderButtons = () => (
    <View style={navigatorStyles.headerButtonsContainer}>
      <TouchableOpacity onPress={() => setAdd(true)}>
        <Icon name="add-outline" size={32} color={theme.colors.accent} />
      </TouchableOpacity>
      <TouchableOpacity onPress={() => console.log('Filter button pressed')}>
        <Icon name="filter-circle-outline" size={32} color={theme.colors.accent} />
      </TouchableOpacity>
      <TouchableOpacity onPress={() => console.log('Info button pressed')}>
        <Icon name="information-outline" size={32} color={theme.colors.accent} />
      </TouchableOpacity>

      <AddModal visible={add} onClose={() => setAdd(false)} />
    </View>
  );

  return (
    <Stack.Navigator>
      <Stack.Screen options={{ headerShown: false }} name="CollectionsScreen" component={CollectionsScreen} />
      <Stack.Screen
        options={({ route }) => ({
          headerTitle: () => renderHeaderTitle(route, navigatorStyles),
          headerStyle: navigatorStyles.header,
          headerBackTitle: 'Back',
          headerBackTitleStyle: navigatorStyles.backButton,
          headerTintColor: theme.colors.accent,
          headerBackImage: renderBackImage,
          headerRight: renderButtons,
        })}
        name="CollectionDetail"
        component={CollectionDetail}
      />
    </Stack.Navigator>
  );
};

export default CollectionsNavigator;
