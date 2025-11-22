import React, { useContext, useState, useMemo } from 'react';
import { Modal, StyleSheet, Text, View, Button } from 'react-native';
import { Picker } from '@react-native-picker/picker';
import ThemeContext from '../../context/ThemeContext';
import booksData from '../../bible.json'; // Ensure correct import
import CustomSheetModal from '../CustomSheetModal';

const AddModal = ({ visible, onClose }) => {
  const { theme } = useContext(ThemeContext);
  const [selectedBook, setSelectedBook] = useState(Object.keys(booksData.books)[0]); // Get first book
  const [selectedChapter, setSelectedChapter] = useState(1);
  const [selectedVerse, setSelectedVerse] = useState(1);
  const [isPickerVisible, setIsPickerVisible] = useState(false); // New state for picker visibility

  // Load chapters only for the selected book using useMemo
  const chapters = useMemo(() => {
    return Object.keys(booksData.books[selectedBook]?.chapters || {}).map(Number); // Convert to array of numbers
  }, [selectedBook]);

  // Load verses only for the selected chapter of the selected book using useMemo
  const verses = useMemo(() => {
    return Array.from(
      { length: booksData.books[selectedBook]?.chapters[selectedChapter]?.verse_count || 0 },
      (_, i) => i + 1,
    );
  }, [selectedBook, selectedChapter]);

  const handleAdd = () => {
    console.log(`Book: ${selectedBook}, Chapter: ${selectedChapter}, Verse: ${selectedVerse}`);
    onClose(); // Close the modal after adding
  };

  const togglePicker = () => {
    setIsPickerVisible(!isPickerVisible);
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      padding: 10,
    },
    label: {
      fontSize: theme.fontSizes.subtitle,
      color: theme.colors.text,
      marginBottom: 5,
    },
    pickerRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginVertical: 10,
    },
    pickerContainer: {
      flex: 1,
      borderTopWidth: 1,
      borderColor: theme.colors.text,
    },
    picker: {
      backgroundColor: theme.colors.secondary,
      color: theme.colors.red,
      ...theme.fonts.regular,
      fontSize: 10,
    },
    button: {
      marginTop: 20,
    },
  });

  return (
    <CustomSheetModal visible={visible} onSave={handleAdd} onClose={onClose} title="Add Verse(s)" saveButtonText="Add">
      <View style={styles.container}>
        <Text style={styles.label}>Select a Book, Chapter, and Verse:</Text>

        {/* Button to show pickers */}
        <Button title="Select Book, Chapter, and Verse" onPress={togglePicker} style={styles.button} />

        {/* Show picker modal when picker is visible */}
        <Modal animationType="slide" transparent={true} visible={isPickerVisible} onRequestClose={togglePicker}>
          <View style={{ flex: 1, justifyContent: 'flex-end' }}>
            <View>
              <View style={styles.pickerRow}>
                {/* Book Picker */}
                <View style={styles.pickerContainer}>
                  <Picker
                    selectedValue={selectedBook}
                    onValueChange={itemValue => {
                      setSelectedBook(itemValue);
                      setSelectedChapter(1); // Reset chapter on book change
                      setSelectedVerse(1); // Reset verse on book change
                    }}
                    style={styles.picker}>
                    {Object.keys(booksData.books).map(book => (
                      <Picker.Item key={book} label={book} value={book} />
                    ))}
                  </Picker>
                </View>
                {/* Chapter Picker */}
                <View style={styles.pickerContainer}>
                  <Picker
                    selectedValue={selectedChapter}
                    onValueChange={itemValue => {
                      setSelectedChapter(itemValue);
                      setSelectedVerse(1); // Reset verse on chapter change
                    }}
                    style={styles.picker}>
                    {chapters.map(chapter => (
                      <Picker.Item key={chapter} label={chapter.toString()} value={chapter} />
                    ))}
                  </Picker>
                </View>
                {/* Verse Picker */}
                <View style={styles.pickerContainer}>
                  <Picker
                    selectedValue={selectedVerse}
                    onValueChange={itemValue => setSelectedVerse(itemValue)}
                    style={styles.picker}>
                    {verses.map(verse => (
                      <Picker.Item key={verse} label={verse.toString()} value={verse} />
                    ))}
                  </Picker>
                </View>
              </View>
              <Button title="Close" onPress={togglePicker} />
            </View>
          </View>
        </Modal>
      </View>
    </CustomSheetModal>
  );
};

export default AddModal;
