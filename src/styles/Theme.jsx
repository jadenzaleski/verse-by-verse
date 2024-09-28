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

export const getCustomTheme = (themeName, isBold, accentColor) => ({
  colors: {
    primary: themeName === 'dark' ? primaryDark : primaryLight,
    secondary: themeName === 'dark' ? secondaryDark : secondaryLight,
    accent: accentColor,
    text: themeName === 'dark' ? textLight : textDark,
    textDark: textDark,
    textLight: textLight,
    red: '#ef4444',
    green: '#198754',
    blue: '#0d6efd',
    yellow: '#ffc107',
  },

  fonts: {
    black: {
      fontFamily: Montserrat.Black,
    },
    blackItalic: {
      fontFamily: Montserrat.BlackItalic,
    },
    extraBold: {
      fontFamily: isBold ? Montserrat.Black : Montserrat.ExtraBold,
    },
    extraBoldItalic: {
      fontFamily: isBold ? Montserrat.BlackItalic : Montserrat.ExtraBoldItalic,
    },
    bold: {
      fontFamily: isBold ? Montserrat.ExtraBold : Montserrat.Bold,
    },
    boldItalic: {
      fontFamily: isBold ? Montserrat.ExtraBoldItalic : Montserrat.BoldItalic,
    },
    semiBold: {
      fontFamily: isBold ? Montserrat.Bold : Montserrat.SemiBold,
    },
    semiBoldItalic: {
      fontFamily: isBold ? Montserrat.BoldItalic : Montserrat.SemiBoldItalic,
    },
    medium: {
      fontFamily: isBold ? Montserrat.SemiBold : Montserrat.Medium,
    },
    mediumItalic: {
      fontFamily: isBold ? Montserrat.SemiBoldItalic : Montserrat.MediumItalic,
    },
    regular: {
      fontFamily: isBold ? Montserrat.Medium : Montserrat.Regular,
    },
    italic: {
      fontFamily: isBold ? Montserrat.MediumItalic : Montserrat.Italic,
    },
    light: {
      fontFamily: isBold ? Montserrat.Regular : Montserrat.Light,
    },
    lightItalic: {
      fontFamily: isBold ? Montserrat.Italic : Montserrat.LightItalic,
    },
    extraLight: {
      fontFamily: isBold ? Montserrat.Light : Montserrat.ExtraLight,
    },
    extraLightItalic: {
      fontFamily: isBold ? Montserrat.LightItalic : Montserrat.ExtraLightItalic,
    },
    thin: {
      fontFamily: isBold ? Montserrat.Regular : Montserrat.Thin,
    },
    thinItalic: {
      fontFamily: isBold ? Montserrat.ExtraLightItalic : Montserrat.ThinItalic,
    },
  },

  fontSizes: {
    extraSmall: 10,
    small: 13,
    medium: 15,
    subtitle: 18,
    large: 24,
    extraLarge: 32,
  },

  shadows: {
    small: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 2,
      },
      shadowOpacity: 0.25,
      shadowRadius: 3.84,
      elevation: 5,
    },
    medium: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 6,
      },
      shadowOpacity: 0.39,
      shadowRadius: 8.3,
      elevation: 13,
    },
    large: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: 10,
      },
      shadowOpacity: 0.51,
      shadowRadius: 13.16,
      elevation: 20,
    },
  },
});
