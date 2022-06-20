void debug(const string &in text) {
    print(c_debug + text);
}

void log_dev(const string &in text) {
#if DEV
    print(c_green + text);
#endif
}

void logcall(const string &in caller, const string &in text) {
    trace(c_mid_grey + "[" + c_debug + caller + c_mid_grey + "] " + text);
}

void dev_logcall(const string &in caller, const string &in text) {
#if DEV
    logcall(caller, text);
#endif
}

void todo(const string &in text) {
    print(c_orange_600 + "todo: " + c_green_700 + text);
}

void trace_benchmark(const string &in action, uint deltaMs) {
    trace(c_mid_grey + "[" + c_purple + action + c_mid_grey + "] took " + c_purple + deltaMs + " ms");
}

void trace_dev(const string &in msg) {
    if (IsDev())
        trace(msg);
}
