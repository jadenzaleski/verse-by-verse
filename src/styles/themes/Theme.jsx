const accent = '#A2C2BA';

const primaryDark = '#2d2d38';
const secondaryDark = '#676670';

const primaryLight = '#F7F7F8';
const secondaryLight = '#e8e8ea';

const textDark = '#131313';
const textLight = '#f3f3f3';

export const getCustomTheme = themeName => ({
  colors: {
    primary: themeName === 'dark' ? primaryDark : primaryLight,
    secondary: themeName === 'dark' ? secondaryDark : secondaryLight,
    accent: accent,
    text: themeName === 'dark' ? textLight : textDark,
    textDark: textDark,
    textLight: textLight,
  },
  font: 'Montserrat',

  fontSizes: {
    extraSmall: 10,
    small: 12,
    medium: 16,
    large: 24,
    extraLarge: 32,
  },

  fontWeights: {
    thin: 100,
    extraLight: 200,
    light: 300,
    regular: 400,
    heavy: 500,
    bold: 700,
    black: 900,
  }
});
