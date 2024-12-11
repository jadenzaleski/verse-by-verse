import React, { createContext, useState, useCallback } from 'react';

const AuthContext = createContext(undefined);

export const AuthProvider = ({ children }) => {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [modalPromise, setModalPromise] = useState(null);

  const showLoginModal = useCallback(() => {
    setIsModalVisible(true);
    return new Promise(resolve => {
      setModalPromise(() => resolve);
    });
  }, []);

  const hideLoginModal = useCallback(() => {
    setIsModalVisible(false);
    if (modalPromise) {
      modalPromise(true);
      setModalPromise(null);
    }
  }, [modalPromise]);

  return (
    <AuthContext.Provider value={{ isModalVisible, showLoginModal, hideLoginModal }}>{children}</AuthContext.Provider>
  );
};

export default AuthContext;
