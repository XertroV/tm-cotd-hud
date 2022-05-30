const string c_green = "\\$3f0";

Color@ CGreen = Color(vec3(0.082, 0.961, 0.208));  // #15F535

enum ColorTy {
    RGB,
    LAB,
    XYZ,
    HSL,
}

string ColorTyStr(ColorTy ty) {
    switch (ty) {
        case ColorTy::RGB: return "RGB";
        case ColorTy::LAB: return "LAB";
        case ColorTy::XYZ: return "XYZ";
        case ColorTy::HSL: return "HSL";
    }
    return "UNK";
}

string Vec3ToStr(vec3 v) {
    return "vec3(" + v.x + ", " + v.y + ", " + v.z + ")";
}

vec3 rgbToXYZ(vec3 v) {
    float r = v.x <= 0.04045 ? (v.x / 12.92) : Math::Pow((v.x + 0.055) / 1.055, 2.4);
    float g = v.y <= 0.04045 ? (v.y / 12.92) : Math::Pow((v.y + 0.055) / 1.055, 2.4);
    float b = v.z <= 0.04045 ? (v.z / 12.92) : Math::Pow((v.z + 0.055) / 1.055, 2.4);
    return vec3(r * 0.4124 + g * 0.3576 + b * 0.1805,
                r * 0.2126 + g * 0.7152 + b * 0.0722,
                r * 0.0193 + g * 0.1192 + b * 0.9505) * 100;
}

vec3 xyzToRGB(vec3 xyz) {
    float x = xyz.x / 100;
    float y = xyz.y / 100;
    float z = xyz.z / 100;
    float r = x * 3.2406 + y * -1.5372 + z * -0.4986;
    float g = x * -0.9689 + y * 1.8758 + z * 0.0415;
    float b = x * 0.0557 + y * -0.204 + z * 1.057;
    r = r > 0.00313 ? (1.055 * Math::Pow(r, 0.4167) - 0.055) : (12.92 * r);
    g = g > 0.00313 ? (1.055 * Math::Pow(g, 0.4167) - 0.055) : (12.92 * g);
    b = b > 0.00313 ? (1.055 * Math::Pow(b, 0.4167) - 0.055) : (12.92 * b);
    return vec3(r, g, b);
}

vec3 xyzToLAB(vec3 xyz) {
    float x = xyz.x / 95.047;
    float y = xyz.y / 100;
    float z = xyz.z / 108.883;
    x = x > 0.008856 ? Math::Pow(x, 0.3333) : (7.787 * x + 0.13793);
    y = y > 0.008856 ? Math::Pow(y, 0.3333) : (7.787 * y + 0.13793);
    z = z > 0.008856 ? Math::Pow(z, 0.3333) : (7.787 * z + 0.13793);
    return vec3(116 * y - 16,
                500 * (x - y),
                200 * (y - z));
}

vec3 labToXYZ(vec3 lab) {
    float y = (lab.x + 16.) / 116.;
    float x = lab.y / 500. + y;
    float z = y - lab.z / 200.;
    x = Math::Pow(x, 3) > 0.008856 ? Math::Pow(x, 3) : ((x - 0.13793) / 7.787);
    y = Math::Pow(y, 3) > 0.008856 ? Math::Pow(y, 3) : ((y - 0.13793) / 7.787);
    z = Math::Pow(z, 3) > 0.008856 ? Math::Pow(z, 3) : ((z - 0.13793) / 7.787);
    return vec3(95.047 * x, 100.0 * y, 108.883 * z);
}

vec3 rgbToHSL(vec3 rgb) {
    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    float max = Math::Max(r, Math::Max(g, b));
    float min = Math::Min(r, Math::Min(g, b));
    float h, s, l;
    l = (max + min) / 2.;
    if (max == min) {
        h = s = 0;
    } else {
        float d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        h = max == r
            ? (g-b) / d + (g < b ? 6 : 0)
            : max == g
                ? (b - r) / d + 2
                /* it must be that: max == b */
                : (r - g) / d + 4;
        h /= 6;
    }
    return vec3(
        Math::Clamp(h * 360., 0., 360.),
        Math::Clamp(s * 100., 0., 100.),
        Math::Clamp(l * 100., 0., 100.));
}

float h2RGB(float p, float q, float t) {
    if (t < 0) { t += 1; }
    if (t > 1) { t -= 1; }
    if (t < 0.16667) { return p + (q-p) * 6. * t; }
    if (t < 0.5) { return q; }
    if (t < 0.66667) { return p + (q-p) * 6. * (2./3. - t); }
    return p;
}

vec3 hslToRGB(vec3 hsl) {
    float h = hsl.x / 360.;
    float s = hsl.y / 100.;
    float l = hsl.z / 100.;
    float r, g, b, p, q;
    if (s == 0) {
        r = g = b = l;
    } else {
        q = l < 0.5 ? (l + l*s) : (l + s - l*s);
        p = 2.*l - q;
        r = h2RGB(p, q, h + 1./3.);
        g = h2RGB(p, q, h);
        b = h2RGB(p, q, h - 1./3.);
    }
    return vec3(r, g, b);
}



string ToSingleHex(float v) {
    if (v < 0) { v = 0; }
    if (v > 15.9999) { v = 15.9999; }
    int u = Math::Floor(v);
    if (u < 10) { return "" + u; }
    switch (u) {
        case 10: return "a";
        case 11: return "b";
        case 12: return "c";
        case 13: return "d";
        case 14: return "e";
        case 15: return "f";
    }
    // should never happen
    return "F";
}


class Color {
    ColorTy ty;
    vec3 v;

    Color(vec3 _v, ColorTy _ty = ColorTy::RGB) {
        v = _v; ty = _ty;
    }

    string ToString() {
        return "Color(" + Vec3ToStr(v) + ", " + ColorTyStr(ty) + ")";
    }

    string get_ManiaColor() {
        return "$" + this.HexTri;
    }

    string get_HexTri() {
        auto v = this.rgb * 15.9999;
        return ""
            + ToSingleHex(v.x)
            + ToSingleHex(v.y)
            + ToSingleHex(v.z);
    }

    void AsLAB() {
        if (ty == ColorTy::LAB) { return; }
        if (ty == ColorTy::XYZ) { v = xyzToLAB(v); }
        if (ty == ColorTy::RGB) { v = xyzToLAB(rgbToXYZ(v)); }
        if (ty == ColorTy::HSL) { v = xyzToLAB(rgbToXYZ(hslToRGB(v))); }
        ty = ColorTy::LAB;
    }

    void AsRGB() {
        if (ty == ColorTy::RGB) { return; }
        if (ty == ColorTy::XYZ) { v = xyzToRGB(v); }
        if (ty == ColorTy::LAB) { v = xyzToRGB(labToXYZ(v)); }
        if (ty == ColorTy::HSL) { v = hslToRGB(v); }
        ty = ColorTy::RGB;
    }

    void AsHSL() {
        if (ty == ColorTy::HSL) { return; }
        if (ty == ColorTy::RGB) { v = rgbToHSL(v); }
        if (ty == ColorTy::XYZ) { v = rgbToHSL(xyzToRGB(v)); }
        if (ty == ColorTy::LAB) { v = rgbToHSL(xyzToRGB(labToXYZ(v))); }
        ty = ColorTy::HSL;
    }

    vec3 get_rgb() {
        if (ty == ColorTy::RGB) { return vec3(v); }
        if (ty == ColorTy::XYZ) { return xyzToRGB(v); }
        if (ty == ColorTy::LAB) { return xyzToRGB(labToXYZ(v)); }
        if (ty == ColorTy::HSL) { return hslToRGB(v); }
        throw("Unknown color type: " + ty);
        return vec3();
    }

    vec3 get_lab() {
        if (ty == ColorTy::LAB) { return vec3(v); }
        if (ty == ColorTy::XYZ) { return xyzToLAB(v); }
        if (ty == ColorTy::RGB) { return xyzToLAB(rgbToXYZ(v)); }
        if (ty == ColorTy::HSL) { return xyzToLAB(rgbToXYZ(hslToRGB(v))); }
        throw("Unknown color type: " + ty);
        return vec3();
    }
}

vec4 Lerp(vec4 a, vec4 b, float t) {
    return (a * (1 - t)) + (b * t);
}

Color@[] gradientColors(Color@ _from, uint length, Color@ _to) {
    auto ret = array<Color@>(length);
    auto ty = _from.ty;
    if (ty != _to.ty) {
        throw("Cannot generate gradient between colors of different types! " + _from.ToString() + ", " + _to.ToString());
    }
    for (uint i = 0; i < length; i++) {
        float t = float(i) / float(length - 1);
        @ret[i] = Color(Math::Lerp(_from.v, _to.v, t), ty);
    }
    return ret;
}

string TextGradient(const string &in text, Color@ _from, Color@ _to) {
    auto colors = gradientColors(_from, text.Length, _to);
    if (colors.Length != text.Length) {
        throw("wrong length of gradient list");
    }
    string ret = "";
    for (uint i = 0; i < text.Length; i++) {
        ret += colors[i].ManiaColor + text.SubStr(i, 1);
    }
    // ret += "$z";
    return ret;
}



#if UNIT_TEST || DEV

void TestColors() {
    TestOneColor(vec3(1, 1, 1));
    TestOneColor(vec3(.3, .5, .1));
    TestOneColor(vec3(.99, .1, .6));
    TestHexTri();
}

void TestOneColor(vec3 rgb) {
    vec3 xyz = rgbToXYZ(rgb);
    vec3 lab = xyzToLAB(xyz);
    vec3 xyz2 = labToXYZ(lab);
    vec3 rgb2 = xyzToRGB(xyz2);
    vec3 diff = rgb2 - rgb;
    print("rgb: " + Vec3ToStr(rgb));
    print("xyz: " + Vec3ToStr(xyz));
    print("lab: " + Vec3ToStr(lab));
    print("xyz2: " + Vec3ToStr(xyz2));
    print("rgb2: " + Vec3ToStr(rgb2));
    print("diff: " + Vec3ToStr(diff));
    print("C(rgb).ManiaColor: \\" + Color(rgb).ManiaColor + " <<<< test ");

    vec3 hsl = rgbToHSL(rgb);
    vec3 rgb3 = hslToRGB(hsl);
    diff = rgb3 - rgb;
    print("rgb: " + Vec3ToStr(rgb));
    print("hsl: " + Vec3ToStr(hsl));
    print("rgb3: " + Vec3ToStr(rgb3));
    print("diff: " + Vec3ToStr(diff));
}

void TestHexTri() {
    auto c = Color(vec3(1, .51, 0));
    auto ht = c.HexTri;
    assert(ht == "f80", 'ht /= "f80"; ht=' + ht + ' from ' + c.ToString());
}

void assert(bool condition, string msg) {
    if (!condition) {
        throw("Assertion failed: " + msg);
    }
}

#endif
