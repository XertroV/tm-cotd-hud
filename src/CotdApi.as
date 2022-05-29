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

    Json::Value GetCotdStatus() {
        return CallApiPath("/api/daily-cup/current");
    }

    Json::Value GetCutoffForDiv(int challengeid, string mapid, int div) {
        // the last position in the div
        int offset = div * 64 - 1;
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "?length=1&offset=" + offset);
    }

    Json::Value GetCotdTimes(int challengeid, string mapid, uint length, uint offset) {
        if (length > 100) {
            throw("GetCotdTimes parameter length cannot be >100");
        }
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "?length=" + length + "&offset=" + offset);
    }

    Json::Value GetPlayerRank(int challengeid, string mapid, string userId) {
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + userId);
    }

    Json::Value GetPlayersRank(int challengeid, string mapid, const string[]&in userIds) {
        string players = string::Join(userIds, ",");
        return CallApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + players);
    }
}
