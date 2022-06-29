enum LogLevel {
    Error = 0,
    Warn = 1,
    Info = 2,
    Debug = 3,
    Trace = 4
}

[Setting category="General" name="Log Level" description="How verbose should the logs be? (Note: currently Error and Warning msgs will always be shown, regardless of this setting)"]
LogLevel Setting_LogLevel = LogLevel::Warn;

void debug(const string &in text) {
    if (Setting_LogLevel >= LogLevel::Debug)
        print(c_debug + text);
}

void log_dev(const string &in text) {
#if DEV
    print(c_green + text);
#endif
}

void logcall(const string &in caller, const string &in text) {
    log_trace(c_mid_grey + "[" + c_debug + caller + c_mid_grey + "] " + text);
}

void dev_logcall(const string &in caller, const string &in text) {
#if DEV
    logcall(caller, text);
#endif
}

void todo(const string &in text) {
    if (Setting_LogLevel >= LogLevel::Info)
        print(c_orange_600 + "todo: " + c_green_700 + text);
}

void trace_benchmark(const string &in action, uint deltaMs) {
    log_trace(c_mid_grey + "[" + c_purple + action + c_mid_grey + "] took " + c_purple + deltaMs + " ms");
}

void trace_dev(const string &in msg) {
    if (IsDev())
        log_trace(msg);
}

void log_trace(const string &in msg) {
    if (Setting_LogLevel >= LogLevel::Trace) {
        trace(msg);
    }
}
