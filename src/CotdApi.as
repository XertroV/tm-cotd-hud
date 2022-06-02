class CotdApi {
    string compUrl;
    string liveSvcUrl;
    string coreUrl;
    CTrackMania@ app; // = GetTmApp();
    CTrackManiaNetwork@ network; // = cast<CTrackManiaNetwork>(app.Network);
    CTrackManiaNetworkServerInfo@ server_info; // = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);

    CotdApi() {
        NadeoServices::AddAudience("NadeoClubServices");
        NadeoServices::AddAudience("NadeoLiveServices");
        // NadeoServices::AddAudience("NadeoServices");

        compUrl = NadeoServices::BaseURLCompetition();
        liveSvcUrl = NadeoServices::BaseURL();
        coreUrl = "https://prod.trackmania.core.nadeo.online";  // Not provided by NadeoServices plugin?

        @app = GetTmApp();
        @network = cast<CTrackManiaNetwork>(app.Network);
        @server_info = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);
    }

    void AssertGoodPath(string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            throw("API Paths should start with '/'!");
        }
    }

    /* COMPETITION API CALLS */

    Json::Value CallCompApiPath(string path) {
        AssertGoodPath(path);
        return FetchClubEndpoint(compUrl + path);
    }

    /** Example return value via `Json::Write`:
      * {"id":1374,"uid":"9b6f7662-edc8-4dfa-be00-5d9f3b0b0620","name":"Cup of the Day 2022-05-28 #3 - Challenge","scoreDirection":"ASC","startDate":1.65381e+09,"endDate":1.65382e+09,"status":"INIT","resultsVisibility":"PUBLIC","creator":"afe7e1c1-7086-48f7-bde9-a7e320647510","admins":["0060a0c1-2e62-41e7-9db7-c86236af3ac4","54e4dda4-522d-496f-8a8b-fe0d0b5a2a8f","2116b392-d808-4264-923f-2bfcfa60a570","6ce163d5-f240-4741-870b-f2adad843865","5e7b0c82-263b-41d5-8fa4-98d36ad4d57c","a76653e1-998a-4c53-8a91-0a396e15bfb5"],"nbServers":0,"autoScale":true,"nbMaps":1,"leaderboardId":6872,"deletedOn":null,"leaderboardType":"SUM","completeTimeout":5}
      */
    Json::Value GetCotdStatus() {
        return CallCompApiPath("/api/daily-cup/current");
    }

    /** example return value
      * [{"time":48679,"uid":"jAtn7LQt2MTG5xv4BeiQwZAX1K","player":"a4cd0259-4ad1-48d9-bf0a-3fee92008686","score":48679,"rank":64}]
      */
    Json::Value GetCutoffForDiv(int challengeid, string mapid, int div) {
        // the last position in the div
        int offset = div * 64 - 1;
        // return CallCompApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "?length=1&offset=" + offset);
        return this.GetCotdTimes(challengeid, mapid, 1, offset);
    }

    /** see GetCutoffForDiv for example return value
      */
    Json::Value GetCotdTimes(int challengeid, string mapid, uint length, uint offset) {
        if (length > 100) {
            throw("GetCotdTimes parameter length cannot be >100");
        }
        return CallCompApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "?length=" + length + "&offset=" + offset);
    }

    /** example ret val
      * {"uid":"jAtn7LQt2MTG5xv4BeiQwZAX1K","cardinal":376,"records":[{"player":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","score":52414,"rank":230}]}
      */
    Json::Value GetPlayerRank(int challengeid, string mapid, string userId) {
        return CallCompApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + userId);
    }

    /* see above */
    Json::Value GetPlayersRank(int challengeid, string mapid, const string[]&in userIds) {
        string players = string::Join(userIds, ",");
        return CallCompApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + players);
    }

    /* example ret val (list of objs)
      [{"id":1385,"uid":"179871ef-b462-4f29-a2d8-b2b935646371","name":"Cup of the Day 2022-05-30 #3 - Challenge","scoreDirection":"ASC","startDate":1653987660,"endDate":1653988560,"status":"INIT","resultsVisibility":"PUBLIC","creator":"afe7e1c1-7086-48f7-bde9-a7e320647510","admins":["0060a0c1-2e62-41e7-9db7-c86236af3ac4","54e4dda4-522d-496f-8a8b-fe0d0b5a2a8f","2116b392-d808-4264-923f-2bfcfa60a570","6ce163d5-f240-4741-870b-f2adad843865","5e7b0c82-263b-41d5-8fa4-98d36ad4d57c","a76653e1-998a-4c53-8a91-0a396e15bfb5"],"nbServers":0,"autoScale":true,"nbMaps":1,"leaderboardId":6920,"deletedOn":null,"leaderboardType":"SUM","completeTimeout":5}, ...]
    */
    Json::Value GetChallenges(uint length = 10, uint offset = 0) {
        return CallCompApiPath("/api/challenges?offset=" + offset + "&length=" + length);
    }

    /* LIVE SERVICES API CALLS */

    Json::Value CallLiveApiPath(string path) {
        AssertGoodPath(path);
        return FetchLiveEndpoint(liveSvcUrl + path);
    }

    /* example ret val:
            RetVal = {"monthList": MonthObj[], "itemCount": 23, "nextRequestTimestamp": 1654020000, "relativeNextRequest": 22548}
            MonthObj = {"year": 2022, "month": 5, "lastDay": 31, "days": DayObj[], "media": {...}}
            DayObj = {"campaignId": 3132, "mapUid": "fJlplQyZV3hcuD7T1gPPTXX7esd", "day": 4, "monthDay": 31, "seasonUid": "aad0f073-c9e0-45da-8a70-c06cf99b3023", "leaderboardGroup": null, "startTimestamp": 1596210000, "endTimestamp": 1596300000, "relativeStart": -57779100, "relativeEnd": -57692700}
       as of 2022-05-31 there are 23 items, so limit=100 will give you all data till 2029.
    */
    Json::Value GetTotdByMonth(uint length = 100, uint offset = 0) {
        return CallLiveApiPath("/api/token/campaign/month?length=" + length + "&offset=" + offset);
    }

    // https://live-services.trackmania.nadeo.live/api/token/map/
    /* example ret val:

    */
    Json::Value GetMap(const string &in mapUid) {
        return CallLiveApiPath("/api/token/map/" + mapUid);
    }

    // Json::Value GetMaps(const string[] &in mapUids) {
    //     return CallLiveApiPath("/api/token/map/" + string::Join(mapUids, ","));
    // }


    /* CORE SERVICES API CALLS */

    /* these have HTTP endpoints but we can't use NadeoServices b/c it doesn't support them because we can use the core API. */

    CGameDataFileManagerScript@ GetCoreApiThingForMaps() {
        return GetTmApp().MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr;
    }

    MwId GetUserMwId() {
        // return cast<CTrackManiaNetwork@>(GetTmApp().Network).PlayerInfo.Id;
        return GetTmApp().ManiaPlanetScriptAPI.MasterServer_MSUsers[0].Id;
    }

    MwFastBuffer<CNadeoServicesMap@> GetMapsInfo(const string[] &in uids) {
        auto coreApi = GetCoreApiThingForMaps();
        MwFastBuffer<wstring> mapIds = MwFastBuffer<wstring>();
        for (uint i = 0; i < uids.Length; i++) mapIds.Add(uids[i]);
        auto req2 = coreApi.Map_NadeoServices_GetListFromUid(GetUserMwId(), mapIds);
        while (req2.IsProcessing) yield();
        if (req2.HasFailed || req2.IsCanceled || !req2.HasSucceeded) {
            throw("[GetMapsInfo] req failed or canceled. errorType=" + req2.ErrorType + "; errorCode=" + req2.ErrorCode + "; errorDescription=" + req2.ErrorDescription);
        }
        print("[GetMapsInfo] Request succeeded!!!");
        return req2.MapList;
    }

    // string GetCoreAuthToken() {
    //     return GetTmApp().ManiaPlanetScriptAPI.Authentication_Token;
    // }


    // Json::Value CallCoreApiPath(const string &in authToken, const string &in path) {
    //     AssertGoodPath(path);
    //     return FetchCoreEndpoint(authToken, coreUrl + path);
    // }

    // // // todo
    // // /* example ret val */
    // Json::Value GetMapInfo(const string &in mapUid) {
    //     // https://prod.trackmania.core.nadeo.online/maps/?mapUidList=
    //     return CallCoreApiPath(GetCoreAuthToken(), "/maps?mapUidList=" + mapUid);
    // }

    // Json::Value GetMapsInfo(const string[] &in mapUids) {
    //     // https://prod.trackmania.core.nadeo.online/maps?mapUidList=
    //     return CallCoreApiPath(GetCoreAuthToken(), "/maps?mapUidList=" + string::Join(mapUids, ","));
    // }
}

Json::Value FetchClubEndpoint(const string &in route) {
    trace("[FetchClubEndpoint] Requesting: " + route);
    while (!NadeoServices::IsAuthenticated("NadeoClubServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoClubServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}


Json::Value FetchLiveEndpoint(const string &in route) {
    trace("[FetchLiveEndpoint] Requesting: " + route);
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}

Json::Value FetchCoreEndpoint(const string &in authToken, const string &in route) {
    trace("[FetchCoreEndpoint] Requesting: " + route);
    // while (!NadeoServices::IsAuthenticated("NadeoServices")) { yield(); }
    // auto req = NadeoServices::Get("NadeoServices", route);
    auto req = Net::HttpRequest();
    req.Url = route;
    req.Headers['Authorization'] = "nadeo_v1 t=" + authToken;
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}
