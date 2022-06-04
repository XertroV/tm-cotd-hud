const int[] MONTHS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

const string[] MONTH_NAMES = {
    "NO MONTH AT 0",
    "January", "February",
    "March", "April", "May", "June",
    "July", "August", "September",
    "October", "November", "December"
};

const uint A_MONTH_IN_MS = uint(31 * 24 * 60 * 60 * 1000);




const dictionary@ NAMED_COLORS = {
    {'justRed', vec3(1, 0, 0)},
    {'justGreen', vec3(0, 1, 0)},
    {'justBlue', vec3(0, 0, 1)},
    {'white', vec3(1, 1, 1)},
    {'black', vec3(0, 0, 0)},
    {'fuchsia', vec3(0xf, 1, 9) / 16.}
};

const array<string> COLOR_NAMES = NAMED_COLORS.GetKeys();
