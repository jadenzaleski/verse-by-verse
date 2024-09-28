import {StyleSheet, Text, View, Button} from 'react-native';
import * as React from 'react';
import {getUser} from '../../utils/api/APICalls'; // Ensure this path is correct
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';
import * as PrintAsyncStorage from '../../utils/PrintAsyncStorage';
import AuthContext from '../../context/AuthContext';

const HomeScreen = ({navigation}) => {
  const {theme} = useContext(ThemeContext);
  const [userText, setUserText] = React.useState(null);
  const {showLoginModal} = useContext(AuthContext);

  const fetchUser = async () => {
    const result = await getUser(showLoginModal); // Call the getUser API
    setUserText(result); // Set the result in the state
  };

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

      {/* Button to trigger getUser call */}
      <Button title="Get User Token" onPress={fetchUser} />

      {/* Button to print AsyncStorage values */}
      <Button title="Print AsyncStorage" onPress={doPrint} />

      {/* Display the result */}
      {userText !== null && (
        <View style={styles.resultContainer}>
          <Text style={styles.resultText}>Result: {JSON.stringify(userText, null, 4)}</Text>
        </View>
      )}
    </View>
  );
};

export default HomeScreen;
