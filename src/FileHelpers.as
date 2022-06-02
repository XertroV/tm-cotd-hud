string UrlToFileName(const string &in url) {
    auto frags = url.Split("/");
    return frags[frags.Length - 1];
}
