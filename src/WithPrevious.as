// bool with previous
class BoolWP {
    private bool value;
    private bool prev;

    BoolWP(bool value) {
        this.value = value;
        this.prev = value;
    }

    void Set(bool v) {
        this.prev = this.value;
        this.value = v;
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
}
