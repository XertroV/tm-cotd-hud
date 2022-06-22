const Json::Value JSON_NULL = Json::Parse("null");

bool IsJsonNull(const Json::Value &in j) {
    /* Sometimes a json value will have a .GetType() of 0 which
     * isn't a valid Json::Type.
     * Json::Type ranges [1, 6] with Null being 6.
     * Thus we can check for 0 and 6 simultaneously by mod-ing
     * the type with 6 and checking if the result is 0.
     */
    return (j.GetType() % Json::Type::Null) == 0;
}

/* DOES NOT WORK */
// Json::Value SetDefaultObj(Json::Value &in obj, const string &in key) {
//     if (IsJsonNull(obj[key])) {
//         obj[key] = Json::Object();
//     }
//     return obj[key];
// }

void AssertJsonArray(Json::Value &in v) {
    if (v.GetType() != Json::Type::Array)
        throw("not a json array");
}

void AssertJsonArrayNonEmpty(Json::Value &in v) {
    AssertJsonArray(v);
    if (v.Length == 0)
        throw("json array length is 0");
}

int JsonMinInt(Json::Value &in v) {
    AssertJsonArrayNonEmpty(v);
    int min = v[0];
    int x;
    for (uint i = 1; i < v.Length; i++) {
        x = v[i];
        min = Math::Min(min, x);
    }
    return min;
}

float JsonMinFloat(Json::Value &in v) {
    AssertJsonArrayNonEmpty(v);
    float min = v[0];
    float x;
    for (uint i = 1; i < v.Length; i++) {
        x = v[i];
        min = Math::Min(min, x);
    }
    return min;
}

int[] JArrayToInt(Json::Value &in v) {
    AssertJsonArrayNonEmpty(v);
    int[] xs = array<int>(v.Length);
    for (uint i = 0; i < v.Length; i++) {
        xs[i] = v[i];
    }
    return xs;
}

array<Json::Value>@ ArrayOfUintToJs(const uint[] &in xs) {
    array<Json::Value> ret = array<Json::Value>(xs.Length);
    for (uint i = 0; i < xs.Length; i++) {
        ret[i] = Json::Value(xs[i]);
    }
    return ret;
}

float[] JArrayToFloat(Json::Value &in v) {
    AssertJsonArrayNonEmpty(v);
    float[] xs = array<float>(v.Length);
    for (uint i = 0; i < v.Length; i++) {
        xs[i] = v[i];
    }
    return xs;
}

string[] JArrayToString(Json::Value &in v) {
    AssertJsonArrayNonEmpty(v);
    string[] xs = array<string>();
    for (uint i = 0; i < v.Length; i++) {
        xs.InsertLast(v[i]);
    }
    return xs;
}

string[] ArrayOfJToString(array<Json::Value> &in v) {
    string[] xs = array<string>();
    for (uint i = 0; i < v.Length; i++) {
        xs.InsertLast(v[i]);
    }
    return xs;
}

bool JArrayContainsInt(Json::Value &in j, int v) {
    AssertJsonArray(j);
    for (uint i = 0; i < j.Length; i++) {
        if (int(j[i]) == v) return true;
    }
    return false;
}
