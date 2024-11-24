module.exports = {
  root: true,
  extends: [
    '@react-native', // React Native rules
    'prettier', // Disables ESLint rules that conflict with Prettier
    'plugin:prettier/recommended', // Enables Prettier as an ESLint rule
  ],
  plugins: ['prettier'],
  rules: {
    'prettier/prettier': ['error'], // Prettier formatting issues as ESLint errors
    'max-len': ['warn', { code: 120 }], // Warn if lines exceed 120 characters
    'object-curly-spacing': ['error', 'always'], // Require spacing inside curly braces
  },
};
