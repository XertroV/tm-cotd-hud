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
