import { StyleSheet, Text, View, Button } from 'react-native';
import * as React from 'react';
import { useContext } from 'react';
import ThemeContext from '../../context/ThemeContext';
import * as PrintAsyncStorage from '../../utils/PrintAsyncStorage';

const HomeScreen = ({ navigation }) => {
  const { theme } = useContext(ThemeContext);

  async function doPrint() {
    await PrintAsyncStorage.print();
  }

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: theme.colors.primary,
    },
    resultContainer: {
      marginTop: 20,
      paddingHorizontal: 20,
    },
    resultText: {
      fontSize: theme.fontSizes.medium,
      ...theme.fonts.regular,
      marginVertical: 5,
      color: theme.colors.text,
    },
    plain: {
      fontSize: theme.fontSizes.large,
      color: theme.colors.text,
    },
  });

  return (
    <View style={styles.container}>
      <Text style={styles.plain}>Home</Text>

      {/* Button to print AsyncStorage values */}
      <Button title="Print AsyncStorage" onPress={doPrint} />
    </View>
  );
};

export default HomeScreen;
