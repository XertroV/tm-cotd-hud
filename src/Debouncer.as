class Debouncer {
    dictionary@ lastCall = dictionary();
    Debouncer() {}

    bool CanProceed(const string &in callId, uint debounceMs) {
        auto now = Time::get_Now();
        uint lc = now;
        if (lastCall.Get(callId, lc)) {
            bool ret = now - lc > debounceMs;
            if (ret) { lastCall.Set(callId, now); }
            return ret;
        } else {
            lastCall[callId] = now;
            return true;
        }
    }
}
