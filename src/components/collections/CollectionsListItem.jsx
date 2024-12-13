import { StyleSheet, Text } from 'react-native';
import Icon from '@react-native-vector-icons/ionicons';
import * as React from 'react';
import { useContext } from 'react';
import ThemeContext from '../../context/ThemeContext';
import Animated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

export default function CollectionsListItem({ item, onDelete }) {
  const { theme } = useContext(ThemeContext);
  const offset = useSharedValue(0);

  const pan = Gesture.Pan()
    .onChange(event => {
      // Update offset incrementally based on gesture movement
      const newOffset = offset.value + event.changeX;
      // Clamp the offset between 0 and -100
      if (newOffset >= -100 && newOffset <= 0) {
        offset.value = newOffset;
      }
    })
    .onFinalize(() => {
      // If swiped more than halfway left, snap to -100; otherwise, snap back to 0
      if (offset.value < -50) {
        offset.value = withTiming(-100);
      } else {
        offset.value = withTiming(0);
      }
    });
  const animatedStyles = useAnimatedStyle(() => ({
    transform: [{ translateX: offset.value }],
  }));

  const collectionsStyles = StyleSheet.create({
    collectionBox: {
      flexDirection: 'row',
      alignSelf: 'stretch',
      backgroundColor: theme.colors.secondary,
      padding: 25,
      borderRadius: 20,
      marginHorizontal: 30,
      alignItems: 'center',
      justifyContent: 'space-between',
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
    <GestureDetector gesture={pan}>
      <Animated.View style={[animatedStyles, collectionsStyles.collectionBox]}>
        <Text style={collectionsStyles.collectionTitle}>{item.title}</Text>
        <Icon color={theme.colors.accent} name={'chevron-forward-outline'} size={25} />
      </Animated.View>
    </GestureDetector>
  );
}
