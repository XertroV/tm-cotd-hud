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

    bool CouldProceed(const string &in callId, uint debounceMs) {
        return TimeLeft(callId, debounceMs) == 0;
    }

    uint TimeLeft(const string &in callId, uint debounceMs) {
        auto now = Time::Now;
        uint lc = now;
        if (lastCall.Get(callId, lc)) {
            return uint(Math::Max(0, int(lc + debounceMs) - now));
        } else {
            return 0;
        }
    }
}
