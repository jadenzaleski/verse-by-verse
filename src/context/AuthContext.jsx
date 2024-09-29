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

  // Hide the login modal and resolve the promise with the login result (true for success, false for cancel)
  const hideLoginModal = (loginSuccess = false) => {
    setIsModalVisible(false);
    if (modalPromise) {
      modalPromise(loginSuccess); // Resolve the promise with login result
      setModalPromise(null); // Clear the stored promise after resolving it
    }
  };

  return (
    <AuthContext.Provider value={{isModalVisible, showLoginModal, hideLoginModal}}>{children}</AuthContext.Provider>
  );
};

export default AuthContext;
