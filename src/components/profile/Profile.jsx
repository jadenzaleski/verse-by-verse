import {StyleSheet, Text, View} from 'react-native';
import * as React from 'react';

const ProfileScreen = ({route}) => {
  return (
    <View style={styles.container}>
      <Text>Profile</Text>
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

export default ProfileScreen;
