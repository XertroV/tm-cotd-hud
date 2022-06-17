
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
