import {StyleSheet, Text, useColorScheme, View} from 'react-native';
import {Colors} from 'react-native/Libraries/NewAppScreen';
import * as React from 'react';

const HomeScreen = ({navigation}) => {
  const colorScheme = useColorScheme();
  const color = colorScheme === 'light' ? Colors.darker : Colors.lighter;

  return (
    <View style={styles.container}>
      <Text style={styles.plain}>Home</Text>
      <Text style={{color: color}}>Current Color Scheme: {colorScheme}</Text>

      <Text style={styles.variableFontText}>This is a variable font</Text>
      <Text style={{...styles.variableFontText, ...styles.boldText}}>
        This is bold
      </Text>
      <Text style={{...styles.variableFontText, ...styles.italicText}}>
        This is italic
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  plain: {
    fontSize: 20,
  },
  variableFontText: {
    fontFamily: 'Montserrat', // The name of the font file without extension
    fontSize: 20,
  },
  boldText: {
    fontWeight: '700', // Example: Bold
  },
  italicText: {
    fontFamily: 'Montserrat',
    fontStyle: 'italic',
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'gray',
  },
  tabContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    backgroundColor: '#fff',
    position: 'absolute',
    bottom: 25,
    left: 50,
    right: 50,
    borderRadius: 50,
    shadowColor: '#777777',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.8,
    shadowRadius: 2,
    elevation: 5,
    paddingVertical: 15,
  },
  tabButton: {
    alignItems: 'center',
  },
});

export default HomeScreen;
