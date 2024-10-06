import React, {createContext, useState} from 'react';

const AuthContext = createContext();

export const AuthProvider = ({children}) => {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [modalPromise, setModalPromise] = useState(null); // To hold the promise resolver
  // Show login modal and return a Promise
  const showLoginModal = () => {
    setIsModalVisible(true);
    return new Promise(resolve => {
      setModalPromise(() => resolve); // Store the resolver to resolve later when modal closes
    });
  };

  // Hide the login modal and resolve the promise (no value passed)
  const hideLoginModal = () => {
    setIsModalVisible(false);
    if (modalPromise) {
      modalPromise(true); // Resolve the promise without any value
      setModalPromise(null); // Clear the stored promise after resolving it
    }
  };

  return (
    <AuthContext.Provider value={{isModalVisible, showLoginModal, hideLoginModal}}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;
