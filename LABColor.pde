// Class representing a color in Lab-space
// Class is an immutable class, so creating a new color
// requires creating a new instance of the class.
class LABColor {
  // Access for the L,a,b components
  // L ranges 0..100
  // a and b's range depends on the colorspace being used.
  // for sRGB, they are usually between -100 and 100
  // a = b = 0 is for gray
  final float L;
  final float a;
  final float b;
  
  // Processing-friendly rgb color value.  This value is always
  // defined, even for out-of-gamut colors.  When a LABColor is
  // created based on a color, rgb will be set to exactly the
  // color passed in
  final color rgb;
  
  // Is this LABColor representable in the sRGB colorspace?
  // Out-of-gamut colors are clamped to 0..1 for each component
  // for an sRGB approximation.
  final boolean inGamut;
  
  // Create an LABColor based on initial L, a, and b values.  Note that in order
  // for this conversion to work correctly, this function will change the colorMode
  // to be RGB with a range of 0..255 (default settings)
  LABColor(float initL, float inita, float initb) {
    L = initL;
    a = inita;
    b = initb;
    float[] rgbs = sRGBfromCIEXYZ(CIEXYZfromCIELAB(new float[]{L,a,b}));
    colorMode(RGB, 255, 255, 255);
    rgb = color(rgbs[0]*255, rgbs[1]*255, rgbs[2]*255);
    if (rgbs[0] < 0 || rgbs[0] > 1
     || rgbs[1] < 0 || rgbs[1] > 1
     || rgbs[2] < 0 || rgbs[2] > 1) {
       inGamut = false;
     } else {
       inGamut = true;
     }
  }
  
  // Create an LABColor given a Processing color 
  LABColor(color initColor) {
    rgb = initColor;
    float r_ = ((rgb >> 16) & 0xFF)/255.0;
    float g_ = ((rgb >> 8) & 0xFF)/255.0;
    float b_ = ((rgb) & 0xFF)/255.0;
    float[] labs = CIELABfromCIEXYZ(CIEXYZfromsRGB(new float[]{r_,g_,b_}));
    L = labs[0];
    a = labs[1];
    b = labs[2];
    inGamut = true;
  }
  
  //Linearly interpolate between two LABColors
  LABColor lerp(LABColor other, float alpha) {
    if (alpha < 0) return this;
    if (alpha > 1) return other;
    return new LABColor(other.L * alpha + L * (1-alpha),
      other.a * alpha + a * (1-alpha),
      other.b * alpha + b * (1-alpha));
  }

  // The functions and constants below here are needed for the
  // CIELAB and sRGB conversions.  You will most likely never
  // want to work with any of these functions directly

  final float D65_X = 0.9505;
  final float D65_Y = 1.0000;
  final float D65_Z = 1.0890;

  // gamma function for CIEXYZ <- sRGB
  float CIEXYZfromsRGBf(float v) {
    final float a_ = 0.055;
    if (v <= 0.04045) {
      return v/ 12.92;
    } else {
      return pow((v + a_)/(1.0 + a_), 2.4);
    }
  }

  // inverse gamma function for sRGB <- CIEXYZ
  float sRGBfromCIEXYZf(float v) {
    final float a_ = 0.055;
    if (v <= 0.0031308) {
      return 12.92 * v;
    } else {
      return (1.0+a_) * pow(v, 1.0/2.4) - a_;
    }
  }

  // Mapping function for CIELAB <- CIEXYZ
  float CIELABfromCIEXYZf(float v) {
    final float a1 = 0.008856451679035631; /* (6/29)^3 */
    final float a2 = 7.787037037037035; /* 1/3 (29/6)^2 */

    if (v > a1) {
      return pow(v, 1.0/3.0);
    } else {
      return a2 * v + 4.0/29.0;
    }
  }

  // Mapping function for CIEXYZ <- CIELAB
  float CIEXYZfromCIELABf(float v) {
    final float a1 = 0.12841854934601665; /* 3*(6/29)^2 */
    if (v > 6.0/29.0) {
      return pow(v, 3.0);
    } else {
      return a1 * (v - 4.0/29.0);
    }
  }

  // Given RGB triplet in range 0..1, return XYZ triplet
  float[] CIEXYZfromsRGB(float[] ipt) {
    float r = ipt[0];
    float g = ipt[1];
    float b = ipt[2];
    r = CIEXYZfromsRGBf(r);
    g = CIEXYZfromsRGBf(g);
    b = CIEXYZfromsRGBf(b);

    return new float[]{0.4124*r + 0.3576*g + 0.1805*b, 
      0.2126*r + 0.7152*g + 0.0722*b, 
      0.0193*r + 0.1192*g + 0.9505*b};
  }

  // Given XYZ triplet, return sRGB triplet (in-gamut values
  // will be in the range 0..1.
  float[] sRGBfromCIEXYZ(float[] ipt) {
    float x = ipt[0];
    float y = ipt[1];
    float z = ipt[2];
    return new float[]{sRGBfromCIEXYZf(3.2406*x + -1.5372*y + -0.4986*z), 
      sRGBfromCIEXYZf(-0.9689*x + 1.8758*y + 0.0415*z), 
      sRGBfromCIEXYZf(0.0557*x + -0.2040*y + 1.0570*z)};
  }
  
  // Given a CIEXYZ triplet, return a Lab triplet
  // based on the D65 whitepoint (to work well with sRGB)
  float[] CIELABfromCIEXYZ(float[] ipt) {
    float x = ipt[0];
    float y = ipt[1];
    float z = ipt[2];

    final float X_n = D65_X;
    final float Y_n = D65_Y;
    final float Z_n = D65_Z;
    x = CIELABfromCIEXYZf(x / X_n);
    y = CIELABfromCIEXYZf(y / Y_n);
    z = CIELABfromCIEXYZf(z / Z_n);
    return new float[]{116.0 * y - 16.0, 
      500.0 * (x - y), 
      200.0 * (y - z)};
  }

  // Given Lab triplet, return XYZ triplet (based
  // on the D65 whitepoint to match well with sRGB)
  float[] CIEXYZfromCIELAB(float[] ipt) {
    float L_ = ipt[0];
    float a_ = ipt[1];
    float b_ = ipt[2];

    final float X_n = D65_X;
    final float Y_n = D65_Y;
    final float Z_n = D65_Z;
    return new float[]{X_n * CIEXYZfromCIELABf(1.0/116.0 * (L_ + 16.0) + a_/500.0), 
      Y_n * CIEXYZfromCIELABf(1.0/116.0 * (L_ + 16.0)), 
      Z_n * CIEXYZfromCIELABf(1.0/116.0 * (L_ + 16.0) - b_/200.0)};
  }
}
