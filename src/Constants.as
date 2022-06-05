const int[] MONTHS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

const string[] MONTH_NAMES = {
    "NO MONTH AT 0",
    "January", "February",
    "March", "April", "May", "June",
    "July", "August", "September",
    "October", "November", "December"
};

const uint A_MONTH_IN_MS = uint(31 * 24 * 60 * 60 * 1000);

// const string c_reset = "\\$z";
// const string c_green = "\\$3f0";
// const string c_brightBlue = "\\$1bf";
// const string c_debug = c_brightBlue;
// const string c_mid_grey = "\\$777";
// const string c_dark_grey = "\\$333";
// const string c_orange_600 = "\\$f61";
// const string c_green_700 = "\\$3a3";

// const string c_timeOrange = "\\$f81";
// const string c_timeBlue = "\\$3ce";


const dictionary@ NAMED_COLORS = {
    {'green', vec3(3,15,0) / 15.},
    {'blue', vec3(1,11,15) / 15.},
    {'orange400', vec3(15,8,1)/15.},
    {'orange600', vec3(13,6,1)/15.},
    {'green700', vec3(3,10,3)/15.},
    {'justRed', vec3(1, 0, 0)},
    {'justGreen', vec3(0, 1, 0)},
    {'justBlue', vec3(0, 0, 1)},
    {'white', vec3(1, 1, 1)},
    {'grey', vec3(7,7,7)/15.},
    {'darkGrey', vec3(3,3,3)/15.},
    {'black', vec3(0, 0, 0)},
    {'fuchsia', vec3(0xf, 1, 9) / 15.}
};

const array<string> COLOR_NAMES = NAMED_COLORS.GetKeys();
