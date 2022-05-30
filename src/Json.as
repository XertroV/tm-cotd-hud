const Json::Value JSON_NULL = Json::Parse("null");

bool IsJsonNull(Json::Value j) {
    return j.GetType() == Json::Type::Null;
}
