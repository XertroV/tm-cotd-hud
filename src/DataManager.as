namespace DataManager {
    GameInfo@ gi = GameInfo();
    TmIoApi@ tmIoApi = TmIoApi("cotd-hud (by @XertroV)");
    CotdApi@ api = CotdApi();

    /* global COTD state variables we want to keep track of and update */

    string cotdLatest_MapId = "";
    Json::Value cotdLatest_Status;
    Json::Value cotdLatest_PlayerRank;

    BoolWP@ isCotd = BoolWP(false);

    /* better chat integration */

    string bcFavorites = "";

    void Main() {
        startnew(Initialize);
        startnew(LoopUpdateBetterChatFavs);

        while (true) {
            yield();
        }
    }

    void Initialize() {
        // only request this at app startup -- will be updated when we join a COTD server
        cotdLatest_MapId = tmIoApi.GetTotdMapId();
    }

    void Update(float dt) {
        isCotd.Set(gi.IsCotd());

        // When we enter a COTD server
        if (isCotd.ChangedToTrue()) {
            cotdLatest_MapId = gi.MapId();
            startnew(SetCurrentCotdData);
        }
    }

    void LoopUpdateBetterChatFavs() {
        while (true) {
            auto _favs = GetOtherPluginSettingVar("BetterChat", "Setting_Favorites");
            if (_favs !is null) { bcFavorites = _favs.ReadString(); }
            trace("[LoopUpdateBetterChatFavs] Favs set to: " + tostring(bcFavorites));

            sleep(60 * 1000);
        }
    }

    /** update cotdLatest data */
    void SetCurrentCotdData() {
        cotdLatest_Status = null;
        startnew(ApiUpdateCotdStatus);
        startnew(ApiUpdateCotdPlayerRank);
    }

    /* Set COTD Status */

    void ApiUpdateCotdStatus() {
        cotdLatest_Status = api.GetCotdStatus();
    }

    Json::Value GetChallenge() {
        return cotdLatest_Status is null ? null : cotdLatest_Status["challenge"];
    }

    string GetChallengeName() {
        auto c = GetChallenge();
        return c is null ? null : c["name"];
    }

    int GetChallengeId() {
        auto c = GetChallenge();
        return c is null ? 0 : c["id"];
    }

    /* Set COTD Players Rank */

    void ApiUpdateCotdPlayerRank() {
        while (GetChallengeId() == 0 || cotdLatest_MapId == "") {
                yield();
        }
        cotdLatest_PlayerRank = api.GetPlayerRank(GetChallengeId(), cotdLatest_MapId, gi.PlayersId());
    }

    int GetCotdTotalPlayers() {
        auto pr = cotdLatest_PlayerRank;
        return pr is null ? 0 : pr['cardinal'];
    }


}
