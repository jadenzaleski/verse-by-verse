import React, { useContext } from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import ThemeContext from '../context/ThemeContext';

const CustomSheetModal = ({
  visible,
  onClose,
  onSave,
  title = 'Modal Title', // Default header title
  saveButtonText = 'Save', // Default save button text
  cancelButtonText = 'Cancel', // Default cancel button text
  children, // Custom content inside the modal
}) => {
  const { theme } = useContext(ThemeContext);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      flexDirection: 'column',
      justifyContent: 'flex-start',
      backgroundColor: theme.colors.primary,
    },
    header: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: 15,
      borderBottomWidth: 1,
      borderBottomColor: theme.colors.secondary,
      backgroundColor: theme.colors.primary,
    },
    headerTitle: {
      ...theme.fonts.semiBold,
      fontSize: theme.fontSizes.subtitle,
      color: theme.colors.text,
    },
    saveButton: {
      ...theme.fonts.bold,
      fontSize: theme.fontSizes.medium,
      color: theme.colors.accent,
    },
    cancelButton: {
      ...theme.fonts.medium,
      fontSize: theme.fontSizes.medium,
      color: theme.colors.accent,
    },
    content: {
      flex: 1,
      padding: 15,
      backgroundColor: theme.colors.primary,
    },
  });

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet" onRequestClose={onClose}>
      <View style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose}>
            <Text style={styles.cancelButton}>{cancelButtonText}</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>{title}</Text>
          <TouchableOpacity onPress={onSave}>
            <Text style={styles.saveButton}>{saveButtonText}</Text>
          </TouchableOpacity>
        </View>
        {/* Content */}
        <View style={styles.content}>{children}</View>
      </View>
    </Modal>
  );
};

export default CustomSheetModal;
