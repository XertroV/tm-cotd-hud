class CotdApi {
    string compUrl;
    CTrackMania@ app; // = GetTmApp();
    CTrackManiaNetwork@ network; // = cast<CTrackManiaNetwork>(app.Network);
    CTrackManiaNetworkServerInfo@ server_info; // = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);

    CotdApi() {
        NadeoServices::AddAudience("NadeoClubServices");
        compUrl = NadeoServices::BaseURLCompetition();

        @app = GetTmApp();
        @network = cast<CTrackManiaNetwork>(app.Network);
        @server_info = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);
    }

    Json::Value CallApiPath(string path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            warn("[CallApiPath] API Paths should start with '/'!");
            path = "/" + path;
        }
        trace("Requesting: " + compUrl + path);
        return FetchEndpoint(compUrl + path);
    }

    /** Example return value via `Json::Write`:
      * {"id":1374,"uid":"9b6f7662-edc8-4dfa-be00-5d9f3b0b0620","name":"Cup of the Day 2022-05-28 #3 - Challenge","scoreDirection":"ASC","startDate":1.65381e+09,"endDate":1.65382e+09,"status":"INIT","resultsVisibility":"PUBLIC","creator":"afe7e1c1-7086-48f7-bde9-a7e320647510","admins":["0060a0c1-2e62-41e7-9db7-c86236af3ac4","54e4dda4-522d-496f-8a8b-fe0d0b5a2a8f","2116b392-d808-4264-923f-2bfcfa60a570","6ce163d5-f240-4741-870b-f2adad843865","5e7b0c82-263b-41d5-8fa4-98d36ad4d57c","a76653e1-998a-4c53-8a91-0a396e15bfb5"],"nbServers":0,"autoScale":true,"nbMaps":1,"leaderboardId":6872,"deletedOn":null,"leaderboardType":"SUM","completeTimeout":5}
      */
    Json::Value GetCotdStatus() {
        return CallApiPath("/api/daily-cup/current");
    }

    /** example return value
      * [{"time":48679,"uid":"jAtn7LQt2MTG5xv4BeiQwZAX1K","player":"a4cd0259-4ad1-48d9-bf0a-3fee92008686","score":48679,"rank":64}]
      */
    Json::Value GetCutoffForDiv(int challengeid, string mapid, int div) {
        // the last position in the div
        int offset = div * 64 - 1;
        // return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "?length=1&offset=" + offset);
        return this.GetCotdTimes(challengeid, mapid, 1, offset);
    }

    /** see GetCutoffForDiv for example return value
      */
    Json::Value GetCotdTimes(int challengeid, string mapid, uint length, uint offset) {
        if (length > 100) {
            throw("GetCotdTimes parameter length cannot be >100");
        }
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "?length=" + length + "&offset=" + offset);
    }

    /** example ret val
      * {"uid":"jAtn7LQt2MTG5xv4BeiQwZAX1K","cardinal":376,"records":[{"player":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","score":52414,"rank":230}]}
      */
    Json::Value GetPlayerRank(int challengeid, string mapid, string userId) {
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + userId);
    }

    /* see above */
    Json::Value GetPlayersRank(int challengeid, string mapid, const string[]&in userIds) {
        string players = string::Join(userIds, ",");
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + players);
    }

    /* example ret val (list of objs)
      [{"id":1385,"uid":"179871ef-b462-4f29-a2d8-b2b935646371","name":"Cup of the Day 2022-05-30 #3 - Challenge","scoreDirection":"ASC","startDate":1653987660,"endDate":1653988560,"status":"INIT","resultsVisibility":"PUBLIC","creator":"afe7e1c1-7086-48f7-bde9-a7e320647510","admins":["0060a0c1-2e62-41e7-9db7-c86236af3ac4","54e4dda4-522d-496f-8a8b-fe0d0b5a2a8f","2116b392-d808-4264-923f-2bfcfa60a570","6ce163d5-f240-4741-870b-f2adad843865","5e7b0c82-263b-41d5-8fa4-98d36ad4d57c","a76653e1-998a-4c53-8a91-0a396e15bfb5"],"nbServers":0,"autoScale":true,"nbMaps":1,"leaderboardId":6920,"deletedOn":null,"leaderboardType":"SUM","completeTimeout":5}, ...]
    */
    Json::Value GetChallenges(uint offset, uint length) {
        return CallApiPath("/api/challenges?offset=" + offset + "&length=" + length);
    }
}

Json::Value FetchEndpoint(const string &in route) {
    auto req = NadeoServices::Get("NadeoClubServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}
