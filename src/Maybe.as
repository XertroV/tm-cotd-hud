class MaybeInt {
    private int v = 0;
    private bool _isNothing = false;

    MaybeInt() {
        _isNothing = true;
    }

    MaybeInt(int value) {
        v = value;
    }

    void AsNothing() {
        _isNothing = true;
    }

    void AsJust(int value) {
        v = value;
        _isNothing = false;
    }

    int get_val() {
        if (_isNothing) {
            throw("Attempted to access .val of MaybeInt that contains no value!");
        }
        return v;
    }

    bool get_isJust() {
        return !_isNothing;
    }

    bool get_isSome() {
        return !_isNothing;
    }

    bool get_isNone() {
        return _isNothing;
    }

    bool get_isNothing() {
        return _isNothing;
    }
}
