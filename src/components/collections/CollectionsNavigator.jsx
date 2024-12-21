import React, { useContext } from 'react';
import { StyleSheet, Text } from 'react-native';
import { createStackNavigator } from '@react-navigation/stack';
import ThemeContext from '../../context/ThemeContext';
import Icon from '@react-native-vector-icons/ionicons';
import CollectionsScreen from './Collections';
import CollectionDetail from './CollectionDetail';

const Stack = createStackNavigator();

const CollectionsNavigator = () => {
  const { theme } = useContext(ThemeContext);

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
  });

  const DEFAULT_COLLECTION_TITLE = 'Collection Detail';

  const renderHeaderTitle = (route, styles) => {
    const collectionName = route.params.item.collection_name ?? DEFAULT_COLLECTION_TITLE;
    return <Text style={styles.headerTitle}>{collectionName}</Text>;
  };

  const renderBackImage = () => (
    <Icon style={navigatorStyles.backButtonIcon} color={theme.colors.accent} name={'chevron-back-outline'} size={25} />
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
        })}
        name="CollectionDetail"
        component={CollectionDetail}
      />
    </Stack.Navigator>
  );
};

export default CollectionsNavigator;
