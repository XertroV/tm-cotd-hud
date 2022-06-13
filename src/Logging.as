void debug(const string &in text) {
    print(c_debug + text);
}

void log_dev(const string &in text) {
    print(c_green + text);
}

void logcall(const string &in caller, const string &in text) {
    trace(c_mid_grey + "[" + c_debug + caller + c_mid_grey + "] " + text);
}

void todo(const string &in text) {
    print(c_orange_600 + "todo: " + c_green_700 + text);
}

void trace_benchmark(const string &in action, uint deltaMs) {
#if DEV || UNIT_TEST
    trace(c_mid_grey + "[" + c_purple + action + c_mid_grey + "] took " + c_purple + deltaMs + " ms");
#endif
}
