funcdef void BoolWPCallback(bool newValue);

// bool with previous
class BoolWP {
    private bool value;
    private bool prev;
    private dictionary@ cbs = dictionary();

    BoolWP(bool value) {
        this.value = value;
        this.prev = value;
    }

    void Set(bool v) {
        this.prev = this.value;
        this.value = v;
        RunCallbacks(v);
    }

    bool Get() {
        return this.value;
    }

    bool GetPrev() {
        return this.prev;
    }

    bool HasChanged() {
        return this.value != this.prev;
    }

    bool ChangedToTrue() {
        return this.value && !this.prev;
    }

    bool ChangedToFalse() {
        return !this.value && this.prev;
    }

    bool Either() {
        return this.value || this.prev;
    }

    const string RegisterCallback(const string &in id, BoolWPCallback@ f) {
        if (cbs.Exists(id)) {
            throw("Callback with id " + id + " already registered!");
        }
        @cbs[id] = f;
        return id;
    }

    private void RunCallbacks(bool v) {
        auto ks = cbs.GetKeys();
        for (uint i = 0; i < ks.Length; i++) {
            auto f = cast<BoolWPCallback@>(cbs[ks[i]]);
            f(v);
        }
    }

    bool get_v() {
        return this.Get();
    }

    void set_v(bool v) {
        this.Set(v);
    }
}
