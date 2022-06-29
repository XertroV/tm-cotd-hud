namespace TmIo {
    // bool initialized = false;
    // TmIoApi@ api = TmIoApi("@XertroV COTD Test2");

    // string cotdMapId = "";

    // void Main() {
    //     // initialize COTD data
    //     auto thisPlugin = Meta::ExecutingPlugin();
    // }

    // void Wait() {
    //     while (!initialized) {
    //         yield();
    //     }
    // }
}


class TmIoApi {
    string userAgent;
#if DEV || UNIT_TEST
    string BASEURL = "http://localhost:44444";
#else
    string BASEURL = "https://trackmania.io/api";
#endif

    Json::Value res_getTotdMap = Json::Parse("null");

    TmIoApi(const string &in userAgent) {
        this.userAgent = userAgent;
        throw("this works but is deprecated");
    }

    // string CachedOr(const string &in key, const string _default) {
    //     log_trace("[TmIoApi] cache get: " + key);
    //     string _r = "";
    //     return this.cache.Get(key, _r) ? _r : _default;
    // }

    Net::HttpRequest@ Req() {
        auto req = Net::HttpRequest();
        req.Headers["User-Agent"] = this.userAgent;
        return req;
    }

    Net::HttpRequest@ GetR(const string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            warn("[GetR] API Paths should start with '/'!");
            throw("[GetR] API Paths should start with '/'!");
        }
        log_trace("[TmIoApi.GetR] " + path);
        auto req = Req();
        req.Method = Net::HttpMethod::Get;
        req.Url = this.BASEURL + path;
        return req;
    }

    Json::Value RunR(Net::HttpRequest@ req) {
        log_trace("[TmIoApi] Requesting: " + req.Url);
        req.Start();
        while (!req.Finished()) { yield(); }
        return Json::Parse(req.String());
    }

    Json::Value _GetTotdMap() {
        if (IsJsonNull(res_getTotdMap)) {
            res_getTotdMap = RunR(GetR("/totd/0"));
        }
        return res_getTotdMap;
    }

    string GetTotdMapId() {
        try {
            auto totd = this._GetTotdMap();
            auto ix = totd["days"].Length - 1;
            string ret = totd["days"][ix]["map"]["mapUid"];
            // this.cache.Set("GetTotdMapId", ret);
            return ret;
        } catch {
            warn("[GetTotdMapId] Exception: " + getExceptionInfo() + "\n");
            return "";
        }
    }
}
