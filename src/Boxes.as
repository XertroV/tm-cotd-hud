/* these are useful for passing as `ref@`s */
class StrBox {
    string s;
    StrBox(const string &in _s) {
        s = _s;
    }
}

class StrPairBox {
    string fst, snd;
    StrPairBox(const string &in _f, const string &in _s) {
        fst = _f; snd = _s;
    }
}
