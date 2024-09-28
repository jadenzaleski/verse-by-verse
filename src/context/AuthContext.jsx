import React, {createContext, useState} from 'react';

const AuthContext = createContext();

export const AuthProvider = ({children}) => {
  const [isModalVisible, setIsModalVisible] = useState(false);

  const showLoginModal = () => setIsModalVisible(true);
  const hideLoginModal = () => setIsModalVisible(false);

  return (
    <AuthContext.Provider value={{isModalVisible, showLoginModal, hideLoginModal}}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;
