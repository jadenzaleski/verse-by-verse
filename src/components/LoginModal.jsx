import React, {useContext} from 'react';
import {Modal, View, Text, Button} from 'react-native';
import AuthContext from '../context/AuthContext';

export const LoginModal = () => {
  const {isModalVisible, hideLoginModal} = useContext(AuthContext);

  return (
    <Modal transparent={true} visible={isModalVisible} onRequestClose={hideLoginModal}>
      <View style={{flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.5)'}}>
        <View style={{width: 300, padding: 20, backgroundColor: 'white', borderRadius: 10}}>
          <Text style={{fontSize: 18, marginBottom: 10}}>Session Expired</Text>
          <Text style={{fontSize: 14, marginBottom: 20}}>Please log in again.</Text>
          <Button title="Close" onPress={hideLoginModal} />
        </View>
      </View>
    </Modal>
  );
};
