const primary = '#36383f';
const secondary = '#F4F5FB';
const accent = '#A2C2BA';

const primaryDark = '#4D4852';
const secondaryDark = '#898891';

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
  },
  fonts: {
    regular: 'System',
    bold: 'System',
  },
  fontSizes: {
    small: 12,
    medium: 16,
    large: 24,
  },
});
