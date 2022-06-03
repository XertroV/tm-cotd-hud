string[] ExtendStringArrs(string[] &in a, const string[] &in b) {
    for (uint i = 0; i < b.Length; i++) {
        a.InsertLast(b[i]);
    }
    return a;
}
