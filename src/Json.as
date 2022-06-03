const Json::Value JSON_NULL = Json::Parse("null");

bool IsJsonNull(Json::Value j) {
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

void AssertJsonArrayNonEmpty(Json::Value v) {
    if (v.GetType() != Json::Type::Array)
        throw("not a json array");
    if (v.Length == 0)
        throw("json array length is 0");
}

int JsonMinInt(Json::Value v) {
    AssertJsonArrayNonEmpty(v);
    int min = v[0];
    int x;
    for (uint i = 1; i < v.Length; i++) {
        x = v[i];
        min = Math::Min(min, x);
    }
    return min;
}

float JsonMinFloat(Json::Value v) {
    AssertJsonArrayNonEmpty(v);
    float min = v[0];
    float x;
    for (uint i = 1; i < v.Length; i++) {
        x = v[i];
        min = Math::Min(min, x);
    }
    return min;
}

int[] JArrayToInt(Json::Value v) {
    AssertJsonArrayNonEmpty(v);
    int[] xs = array<int>(v.Length);
    for (uint i = 0; i < v.Length; i++) {
        xs[i] = v[i];
    }
    return xs;
}

float[] JArrayToFloat(Json::Value v) {
    AssertJsonArrayNonEmpty(v);
    float[] xs = array<float>(v.Length);
    for (uint i = 0; i < v.Length; i++) {
        xs[i] = v[i];
    }
    return xs;
}

string[] JArrayToString(Json::Value v) {
    AssertJsonArrayNonEmpty(v);
    string[] xs = array<string>();
    for (uint i = 0; i < v.Length; i++) {
        xs.InsertLast(v[i]);
    }
    return xs;
}
