
void assert(bool condition, string msg) {
    if (!condition) {
        throw("Assertion failed: " + msg);
    }
}

bool IfDev() {
#if DEV || UNIT_TEST
    return true;
#else
    return false;
#endif
}

const string GetYMD(uint year, uint month, uint day) {
    return Text::Format("%04d", int(year))
        + Text::Format("-%02d", int(month))
        + Text::Format("-%02d", int(day));
}
