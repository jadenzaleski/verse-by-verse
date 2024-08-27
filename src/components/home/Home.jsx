import {StyleSheet, Text, View, Button} from 'react-native';
import * as React from 'react';
import { getUser, refreshUserToken } from '../../utils/api/APICalls';
import {useContext} from 'react';
import ThemeContext from '../../context/ThemeContext';

const HomeScreen = ({navigation}) => {
  const {theme} = useContext(ThemeContext);
  const [result, setResult] = React.useState(null);

  const handleTokenRefresh = async () => {
    const response = await refreshUserToken('jadenzaleski@icloud.com', 'august30');
    setResult(response); // Store the response (token) in state
  };

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
  });

  return (
    <View style={styles.container}>
      <Text style={styles.plain}>Home</Text>

      {/* Button to trigger token refresh */}
      <Button title="Refresh Token" onPress={handleTokenRefresh} />
      <Button title="getUser Token" onPress={getUser} />
      {/* Display the result */}
      {result !== null && (
        <View style={styles.resultContainer}>
          <Text style={styles.resultText}>Result: {JSON.stringify(result)}</Text>
        </View>
      )}
    </View>
  );
};

export default HomeScreen;
