
void assert(bool condition, const string &in msg) {
    if (!condition) {
        throw("Assertion failed: " + msg);
    }
}

bool IsDev() {
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

const string[] ToYMDArr(uint year, uint month, uint day) {
    return
        { Text::Format("%04d", int(year))
        , Text::Format("%02d", int(month))
        , Text::Format("%02d", int(day))
        };
}

const array<string>@ FromYMD(const string &in date) {
    string[] ymd = date.Split('-');
    assert(ymd.Length == 3, "ymd has 3 elements");
    assert(ymd[0].Length == 4, "ymd[0] is of length 4");
    return ymd;
}

const string ExtractYMD(const string &in cotdName) {
    assert(cotdName.SubStr(0, 14) == "Cup of the Day", "is not a Cup of the Day event name.");
    return cotdName.SubStr(15, 10);
}
