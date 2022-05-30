
namespace DataManager {
    const Json::Value JSON_NULL = Json::Parse("null");
    const uint Q_SIZE = 100;

    GameInfo@ gi;
    TmIoApi@ tmIoApi = TmIoApi("cotd-hud (by @XertroV)");
    CotdApi@ api;


    /* global COTD state variables we want to keep track of and update */

    string cotdLatest_MapId = "";
    Json::Value cotdLatest_Status = JSON_NULL;
    Json::Value cotdLatest_PlayerRank = JSON_NULL;

    BoolWP@ isCotd = BoolWP(false);

    uint[] cotd_ActiveDivRows = {1, 2, 3, 4, 5};
    DivRow@[] divRows = array<DivRow@>(Q_SIZE);
    uint divs_lastUpdated = 0;

    DivRow@ playerDivRow = DivRow(0, 0, RowTy::Player);

    /* if we are showing a histogram, we'll need to track the 100 times above and below us */
    uint[] cotd_TimesForHistogram = array<uint>(200, 0);

    /* queues for coros */

    uint[] q_divsToUpdate = array<uint>(Q_SIZE);
    uint q_divsToUpdate_Start = 0;
    uint q_divsToUpdate_End = 0;

    /* better chat integration */

    string bcFavorites = "";

    /* DEV variables */
#if DEV
    uint sleepMs = 1000;
#endif

    void Main() {
        @gi = GameInfo();
        // This can't be run on script load -- 'Unbound function called' exception
        @api = CotdApi();

        InitDivRows();

        startnew(Initialize);
        startnew(LoopUpdateBetterChatFavs);
        startnew(LoopUpdateCotdStatus);
        startnew(LoopUpdateDivsInCotd);

#if DEV
        startnew(LoopDevPrintState);
#endif

        // while (true) {
        //     yield();
        // }

        sleep(2000);
        UpdateDivs();

        while (true) {
            // print("" + Time::get_Now());
            sleep(15);
        }
    }

    void Initialize() {
        // only request this at app startup -- will be updated when we join a COTD server
        cotdLatest_MapId = tmIoApi.GetTotdMapId();
        // todo: save all of GetTotdMap data so that we can look at past COTDs, too
    }

    void Update(float dt) {
        try {
            isCotd.Set(gi.IsCotd());

            if (isCotd.v) {
                cotdLatest_MapId = gi.MapId();
            }

            // When we enter a COTD server
            if (isCotd.ChangedToTrue()) {
                cotdLatest_MapId = gi.MapId();
                startnew(SetCurrentCotdData);
                startnew(UpdateDivs);
            }
        } catch {
            warn("Exception in Update: " + getExceptionInfo());
        }
    }


    void InitDivRows() {
        for (uint i = 0; i < 100; i++) {
            @divRows[i] = DivRow(i + 1);
        }
    }


    void LoopUpdateCotdStatus() {
        while (true) {
            // do these in series b/c we don't care how long it takes.
            ApiUpdateCotdStatus();
            // dependent on status
            CoroUpdatePlayerDiv();
#if DEV
            // todo: just for debug
            UpdateDivs();
#endif
            sleep(3600 * 1000 /* 1hr */);
        }
    }

    void LoopUpdateBetterChatFavs() {
        while (true) {
            auto @_favs = GetOtherPluginSettingVar("BetterChat", "Setting_Favorites");

            if (_favs !is null) {
                auto favs = _favs.ReadString();
                trace(tostring(favs));
                trace(tostring(favs.Length));
                bcFavorites = "test";
                bcFavorites = favs;
            }
            trace("[LoopUpdateBetterChatFavs] Favs set to: " + tostring(bcFavorites));

            sleep(60 * 1000);
        }
    }

    void LoopUpdateDivsInCotd() {
        uint loopSleepMs = 100;
        uint loopUpdatePeriodMs = 5 * 1000;

        while (true) {
            auto now = Time::get_Now();

            bool shouldUpdate = false
                || divs_lastUpdated == 0  // if we never have
                || (now - divs_lastUpdated) > loopUpdatePeriodMs  // or if we've waited long enough
                ;

            shouldUpdate = shouldUpdate
                && isCotd.v  // must be COTD
                && gi.IsCotdQuali()
                ;

            /* Update divs */
            if (shouldUpdate) {
                divs_lastUpdated = now;
                startnew(ApiUpdateCotdPlayerRank);
                UpdateDivs();
            }

            sleep(loopSleepMs);
        }
    }

    void UpdateDivs() {
        divs_lastUpdated = Time::get_Now();
        startnew(ApiUpdateCotdDivRows);
        startnew(CoroUpdatePlayerDiv);
    }

    /** update cotdLatest data */

    void SetCurrentCotdData() {
        // We don't expect COTD Status info to change (it is set on load and updated every hour)
        startnew(ApiUpdateCotdStatus);
        // so we do ApiUpdateCotdPlayerRank in parallel
        startnew(ApiUpdateCotdPlayerRank);
    }

    /* Set COTD Status */

    void ApiUpdateCotdStatus() {
        cotdLatest_Status = api.GetCotdStatus();
    }

    Json::Value GetChallenge() {
        return IsJsonNull(cotdLatest_Status) ? cotdLatest_Status : cotdLatest_Status["challenge"];
    }

    string GetChallengeName() {
        auto c = GetChallenge();
        if (IsJsonNull(c)) {
            return "";
        }
        return c["name"];
    }

    string GetChallengeDateAndNumber() {
        auto cn = GetChallengeName();
        return cn == "" ? "0000-00-00 #0" : cn.SubStr(15, 13);
    }

    string GetChallengeTitle() {
        string ret = "COTD ";
        if (_ViewPriorChallenge()) {
            ret += "prior to ";
        }
        ret += GetChallengeDateAndNumber();
        return ret;
    }

    bool _ViewPriorChallenge() {
        auto c = GetChallenge();
        if (IsJsonNull(c)) { return false; }
        int64 nowTs = Time::get_Stamp();
        int64 challengeStart = c["startDate"];
        return nowTs < challengeStart;
    }

    int GetChallengeId() {
        auto c = GetChallenge();
        if (IsJsonNull(c)) { return 0; }
        int offset = isCotd.v || !_ViewPriorChallenge() ? 0 : (-1);
        return IsJsonNull(c) ? 0 : c["id"] + offset;
    }

    /* Set COTD Players Rank */

    void ApiUpdateCotdPlayerRank() {
        while (GetChallengeId() == 0 || cotdLatest_MapId == "") {
            yield();
        }
        cotdLatest_PlayerRank = api.GetPlayerRank(GetChallengeId(), cotdLatest_MapId, gi.PlayersId());
        trace("[ApiUpdateCotdPlayerRank] from api got: " + Json::Write(cotdLatest_PlayerRank));
    }

    uint GetCotdTotalPlayers() {
        auto pr = cotdLatest_PlayerRank;
        return IsJsonNull(pr) ? 0 : pr['cardinal'];
    }

    uint GetCotdTotalDivs() {
        return Math::Ceil(GetCotdTotalPlayers() / 64.0);
    }

    uint GetCotdLastDivPop() {
        return GetCotdTotalPlayers() % 64;
    }

    /* Update divisions from API */
    void ApiUpdateCotdDivRows() {
        RenewActiveDivs();
        for (uint i = 0; i < cotd_ActiveDivRows.Length; i++) {
            PutDivToUpdateInQ(cotd_ActiveDivRows[i]);
            startnew(CoroUpdateDivFromQ);
        }
    }

    /* set active div rows based on player rank, settings, etc */
    void RenewActiveDivs() {
        // todo: active div rows based on player rank, settings, etc
        cotd_ActiveDivRows = array<uint>(99);
        uint _d;
        for (uint i = 0; i < cotd_ActiveDivRows.Length; i++) {
            _d = i + 1;  // the div
            // if (_d > 2) { break; }
            // IsDivVisible()
            if (true) {
                cotd_ActiveDivRows[i] = _d;
                /* this is a bit of a cheat -- the div won't be drawn if it doesn't have a valid time */
                divRows[i].visible = true;
            }
        }
    }

    bool IsDivVisible(uint div) {
        // todo
        return true;
    }

    void CoroUpdateDivFromQ() {
        auto _div = GetDivToUpdateFromQ();
        if (_div == 0 || _div >= divRows.Length) {
            return;
        }

        auto logpre = "CoroUpdateDivFromQ(" + _div + ") | ";
#if DEV
        // trace(logpre + "Got div.");
#endif

        auto _row = divRows[_div - 1];
        _row.lastUpdateStart = Time::get_Now();
        auto start = Time::get_Now();

        if ((_div - 1) * 64 >= GetCotdTotalPlayers()) {
            // there are no players in this div
            _row.timeMs = MAX_DIV_TIME;
            _row.visible = false;
        } else {
            trace(logpre + "got div w/ " + GetCotdTotalPlayers() + " total players");
            // we can get a time for this div
            Json::Value res;
            if (_div * 64 > GetCotdTotalPlayers()) {
                // div is not full, get time of last player
                res = api.GetCotdTimes(GetChallengeId(), cotdLatest_MapId, 1, GetCotdTotalPlayers() - 1);
            } else {
                res = api.GetCutoffForDiv(GetChallengeId(), cotdLatest_MapId, _div);
            }
            // trace(logpre + " res: " + Json::Write(res));
            /* note: res[0]["score"] and res[0]["time"] appear to be identical */
            _row.timeMs = (res.Length == 0) ? MAX_DIV_TIME : res[0]["score"];
            _row.lastJson = res[0];
        }

        _row.lastUpdateDone = Time::get_Now();
        if (_row.timeMs < MAX_DIV_TIME)
            trace(logpre + _row.ToString());
    }

    void CoroUpdatePlayerDiv() {
        playerDivRow.lastUpdateStart = Time::get_Now();

        ApiUpdateCotdPlayerRank();

        // fire off coro for updating histogram if we want that
        startnew(CoroUpdateAllTimesAroundPlayer);

        if (!IsJsonNull(cotdLatest_PlayerRank) && cotdLatest_PlayerRank["records"].Length > 0) {
            uint pRank = cotdLatest_PlayerRank["records"][0]["rank"];
            playerDivRow.div = Math::Ceil(pRank / 64.0);

            uint pScore = cotdLatest_PlayerRank["records"][0]["score"];
            playerDivRow.timeMs = pScore;
            playerDivRow.lastJson = cotdLatest_PlayerRank["records"][0];
        } else {
            playerDivRow.timeMs = MAX_DIV_TIME;
            playerDivRow.div = 99;
        }

        playerDivRow.lastUpdateDone = Time::get_Now();
    }

    class UpdateTimesForHist {
        uint ix;
        int rank;
        UpdateTimesForHist(uint ix, int rank) {
            this.ix = ix;
            this.rank = rank < 1 ? 1 : rank;
        }
    }

    void CoroUpdateAllTimesAroundPlayer() {
        if (Setting_HudShowHistogram && !IsJsonNull(cotdLatest_PlayerRank)) {
            int pRank = 101;
            if (cotdLatest_PlayerRank["records"].Length > 0) {
                pRank = cotdLatest_PlayerRank["records"][0]["rank"];
            }
            if (pRank <= 100) {
                pRank = 101;
            }
            if (pRank > 100 && pRank > GetCotdTotalPlayers() - 100) {
                pRank = GetCotdTotalPlayers() - 100;
            }

            startnew(_CoroUpdateManyTimesFromRank, UpdateTimesForHist(0, pRank - 100));
            startnew(_CoroUpdateManyTimesFromRank, UpdateTimesForHist(100, pRank));
        }
    }

    void _CoroUpdateManyTimesFromRank(ref@ _args) {
        auto args = cast<UpdateTimesForHist@>(_args);
        auto timesData = api.GetCotdTimes(GetChallengeId(), cotdLatest_MapId, 100, args.rank - 1);
        if (IsJsonNull(timesData)) {
            trace("[_CoroUpdateManyTimesFromRank]: timesData was null!");
            return;
        }

        uint ixUpper = timesData.Length;
        // if (ixUpper > 100 + args.ix) { ixUpper = 100 + args.ix; }
        for (uint i = 0; i < Math::Min(100, ixUpper); i++) {
            cotd_TimesForHistogram[args.ix + i] = timesData[i]["score"];
            // trace("_CoroUpdateManyTimesFromRank: " + tostring(cotd_TimesForHistogram[args.ix + i]));
        }
    }

    uint GetDivToUpdateFromQ() {
        while (q_divsToUpdate_Start == q_divsToUpdate_End) { yield(); }
        auto ret = q_divsToUpdate[q_divsToUpdate_Start];
        q_divsToUpdate_Start = (q_divsToUpdate_Start + 1) % Q_SIZE;
        return ret;
    }

    void PutDivToUpdateInQ(uint _div) {
        // don't insert into the Q if the start index is 1 ahead of the end index
        while ((q_divsToUpdate_End + 1) % Q_SIZE == q_divsToUpdate_Start) {
            warn("Q entry blocked!!!");
            yield();
        }
        q_divsToUpdate[q_divsToUpdate_End] = _div;
        // trace("PutDivToUpdateInQ: " + _div + " (at ix=" + q_divsToUpdate_End + ")");
        q_divsToUpdate_End = (q_divsToUpdate_End + 1) % Q_SIZE;
    }

#if DEV
    /* DEV helpers */

    void LoopDevPrintState() {
        // float multiplier = 1.1f;
        // while (true) {
        //     sleep(sleepMs * multiplier);
        //     multiplier *= multiplier;
        //     // throw(")");
        //     print("GetChallenge(): " + Json::Write(GetChallenge()));
        //     print("GetChallengeName(): " + GetChallengeName());
        //     print("GetChallengeDateAndNumber(): " + tostring(GetChallengeDateAndNumber()));
        //     print("GetChallengeId(): " + tostring(GetChallengeId()));
        //     print("GetCotdTotalPlayers(): " + tostring(GetCotdTotalPlayers()));
        //     // print("divRows.Length: " + divRows.Length);
        //     print("cotdLatest_PlayerRank: " + Json::Write(cotdLatest_PlayerRank));
        //     print("cotdLatest_MapId: " + Json::Write(cotdLatest_MapId));
        // }
    }
#endif
}
