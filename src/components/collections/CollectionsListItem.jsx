import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import Icon from '@react-native-vector-icons/ionicons';
import * as React from 'react';
import { useContext } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Animated, { interpolate, useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import * as Globals from '../../utils/Globals';
import log from '../../utils/Logger';

export default function CollectionsListItem({ navigation, item, onDelete }) {
  const { theme } = useContext(ThemeContext);
  const offset = useSharedValue(0);
  const editButtonVisibility = useSharedValue(0);
  const deleteButtonVisibility = useSharedValue(0);

  const pan = Gesture.Pan()
    .onChange(event => {
      const newOffset = offset.value + event.changeX;
      if (newOffset >= -Globals.ITEM_MAX_OFFSET && newOffset <= 0) {
        offset.value = newOffset;

        // Individual button visibility logic
        deleteButtonVisibility.value = withSpring(newOffset < -Globals.ITEM_MAX_OFFSET / 2 ? 1 : 0);
        editButtonVisibility.value = withSpring(newOffset < -Globals.ITEM_MAX_OFFSET + 15 ? 1 : 0);
      }
    })
    .onFinalize(() => {
      // Snap to either fully open (-150) or closed (0)
      const finalPosition = offset.value < -Globals.ITEM_MAX_OFFSET / 2 ? -Globals.ITEM_MAX_OFFSET : 0;
      offset.value = withSpring(finalPosition);

      // Ensure both buttons are fully visible if fully open
      if (finalPosition === -Globals.ITEM_MAX_OFFSET) {
        deleteButtonVisibility.value = withSpring(1);
        editButtonVisibility.value = withSpring(1);
      }
    })
    .activeOffsetX([-10, 10])
    .simultaneousWithExternalGesture();

  const animatedStyles = useAnimatedStyle(() => ({
    transform: [{ translateX: offset.value }],
  }));

  const editButtonStyle = useAnimatedStyle(() => {
    const opacity = interpolate(editButtonVisibility.value, [0, 1], [0, 1]);
    const scale = interpolate(editButtonVisibility.value, [0, 1], [0.8, 1]);
    return {
      opacity,
      transform: [{ scale }],
    };
  });

  const deleteButtonStyle = useAnimatedStyle(() => {
    const opacity = interpolate(deleteButtonVisibility.value, [0, 1], [0, 1]);
    const scale = interpolate(deleteButtonVisibility.value, [0, 1], [0.8, 1]);
    return {
      opacity,
      transform: [{ scale }],
    };
  });

  const handlePress = () => {
    navigation.navigate('CollectionDetail', { item });
  };

  const handleDelete = async () => {
    onDelete(item.collection_id);
  };

  const handleEdit = () => {
    console.log('Edit action triggered for:', item.title);
  };

  const collectionsStyles = StyleSheet.create({
    container: {
      position: 'relative',
      marginHorizontal: 30,
    },
    optionButtons: {
      flexDirection: 'row',
      position: 'absolute',
      right: 10,
      top: 0,
      bottom: 0,
      alignItems: 'center',
      justifyContent: 'flex-end',
      overflow: 'hidden',
      gap: 15,
    },
    deleteButton: {
      justifyContent: 'center',
      alignItems: 'center',
      width: 50,
      height: 50,
      padding: 5,
      backgroundColor: theme.colors.red,
      borderRadius: 25,
    },
    editButton: {
      justifyContent: 'center',
      alignItems: 'center',
      width: 50,
      height: 50,
      padding: 5,
      backgroundColor: theme.colors.blue,
      borderRadius: 25,
    },
    collectionBox: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      backgroundColor: theme.colors.secondary,
      borderRadius: 20,
      padding: 25,
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

  return (
    <View style={collectionsStyles.container}>
      <View style={collectionsStyles.optionButtons}>
        <Animated.View style={editButtonStyle}>
          <TouchableOpacity style={collectionsStyles.editButton} onPress={handleEdit}>
            <Icon name="create-outline" style={{ right: -1 }} size={24} color="white" />
          </TouchableOpacity>
        </Animated.View>

        <Animated.View style={deleteButtonStyle}>
          <TouchableOpacity style={collectionsStyles.deleteButton} onPress={handleDelete}>
            <Icon name="trash-outline" size={24} color="white" />
          </TouchableOpacity>
        </Animated.View>
      </View>

      <GestureDetector gesture={pan}>
        <Animated.View style={[animatedStyles]}>
          <TouchableOpacity style={collectionsStyles.collectionBox} onPress={handlePress} activeOpacity={0.7}>
            <Text style={collectionsStyles.collectionTitle}>{item.collection_name}</Text>
            <Icon color={theme.colors.accent} name={'chevron-forward-outline'} size={25} />
          </TouchableOpacity>
        </Animated.View>
      </GestureDetector>
    </View>
  );
}
