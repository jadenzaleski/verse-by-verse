const accent = '#A2C2BA';

const primaryDark = '#2d2d38';
const secondaryDark = '#676670';

const primaryLight = '#F7F7F8';
const secondaryLight = '#e8e8ea';

const textDark = '#131313';
const textLight = '#f3f3f3';

const Montserrat = {
  Black: 'Montserrat-Black',
  BlackItalic: 'Montserrat-BlackItalic',
  Bold: 'Montserrat-Bold',
  BoldItalic: 'Montserrat-BoldItalic',
  ExtraBold: 'Montserrat-ExtraBold',
  ExtraBoldItalic: 'Montserrat-ExtraBoldItalic',
  ExtraLight: 'Montserrat-ExtraLight',
  ExtraLightItalic: 'Montserrat-ExtraLightItalic',
  Italic: 'Montserrat-Italic',
  Light: 'Montserrat-Light',
  LightItalic: 'Montserrat-LightItalic',
  Medium: 'Montserrat-Medium',
  MediumItalic: 'Montserrat-MediumItalic',
  Regular: 'Montserrat-Regular',
  SemiBold: 'Montserrat-SemiBold',
  SemiBoldItalic: 'Montserrat-SemiBoldItalic',
  Thin: 'Montserrat-Thin',
  ThinItalic: 'Montserrat-ThinItalic',
};

export const getCustomTheme = themeName => ({
  colors: {
    primary: themeName === 'dark' ? primaryDark : primaryLight,
    secondary: themeName === 'dark' ? secondaryDark : secondaryLight,
    accent: accent,
    text: themeName === 'dark' ? textLight : textDark,
    textDark: textDark,
    textLight: textLight,
  },

  fonts: {
    black: {
      fontFamily: Montserrat.Black,
    },
    blackItalic: {
      fontFamily: Montserrat.BlackItalic,
    },
    bold: {
      fontFamily: Montserrat.Bold,
    },
    boldItalic: {
      fontFamily: Montserrat.BoldItalic,
    },
    extraBold: {
      fontFamily: Montserrat.ExtraBold,
    },
    extraBoldItalic: {
      fontFamily: Montserrat.ExtraBoldItalic,
    },
    extraLight: {
      fontFamily: Montserrat.ExtraLight,
    },
    extraLightItalic: {
      fontFamily: Montserrat.ExtraLightItalic,
    },
    italic: {
      fontFamily: Montserrat.Italic,
    },
    light: {
      fontFamily: Montserrat.Light,
    },
    lightItalic: {
      fontFamily: Montserrat.LightItalic,
    },
    medium: {
      fontFamily: Montserrat.Medium,
    },
    mediumItalic: {
      fontFamily: Montserrat.MediumItalic,
    },
    regular: {
      fontFamily: Montserrat.Regular,
    },
    semiBold: {
      fontFamily: Montserrat.SemiBold,
    },
    semiBoldItalic: {
      fontFamily: Montserrat.SemiBoldItalic,
    },
    thin: {
      fontFamily: Montserrat.Thin,
    },
    thinItalic: {
      fontFamily: Montserrat.ThinItalic,
    },
  },

  fontSizes: {
    extraSmall: 10,
    small: 12,
    medium: 15,
    large: 24,
    extraLarge: 32,
  },

  fontWeights: {
    thin: '100',
    extraLight: '200',
    light: '300',
    regular: '400',
    heavy: '500',
    bold: '700',
    black: '900',
  },
});
