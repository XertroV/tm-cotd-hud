bool IsJsonNull(Json::Value j) {
    return j.GetType() == Json::Type::Null;
}
