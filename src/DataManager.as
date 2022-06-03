
namespace DataManager {
    const uint Q_SIZE = 200;

    const uint[] TOP_5 = {1, 2, 3, 4, 5};

    GameInfo@ gi = GameInfo();
    TmIoApi@ tmIoApi = TmIoApi("cotd-hud (by @XertroV)");
    CotdApi@ api;

    Debouncer@ debounce = Debouncer();


    /* global COTD state variables we want to keep track of and update */

    string cotdLatest_MapId = "";
    Json::Value cotdLatest_Status = JSON_NULL;
    Json::Value cotdLatest_PlayerRank = JSON_NULL;

    MaybeInt cotd_OverrideChallengeId = MaybeInt();

    BoolWP@ isCotd = BoolWP(false);

    uint[] cotd_ActiveDivRows = {1, 2, 3, 4, 5};
    DivRow@[] divRows = array<DivRow@>(Q_SIZE);
    uint divs_lastUpdated = 0;

    DivRow@ playerDivRow = DivRow(0, 0, RowTy::Player);

    /* if we are showing a histogram, we'll need to track the 100 times above and below us */
    uint[] cotd_TimesForHistogram = array<uint>(200, 0);
    Histogram::HistData@ cotd_HistogramData;
    int2 cotd_HistogramMinMaxRank = int2(0, 0);

    /* queues for coros */

    uint[] q_divsToUpdate = array<uint>(Q_SIZE);
    uint q_divsToUpdate_Start = 0;
    uint q_divsToUpdate_End = 0;

    /* better chat integration */

    string bcFavorites = "";

    void Main() {
        // This can't be run on script load -- 'Unbound function called' exception
        @api = CotdApi();

        // print("challenge api for april 2");
        // print(Json::Write(api.GetPlayerRank(1176, "sTvb8KzSHxJYRJmSHqckAFwW8Hi", "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9")));

        // print("GetTotdByMonth with length 100 and offset 0");
        // print("Sz len: " + Json::Write(api.GetTotdByMonth(100)).Length);

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
        auto days = api.GetTotdByMonth(1)["monthList"][0]["days"];
        string mapUid;
        for (uint i = 0; i < days.Length; i++) {
            mapUid = days[i]['mapUid'];
            if (mapUid.Length > 0) cotdLatest_MapId = mapUid;
            else break;
        }
        // todo: save all of GetTotdMap data so that we can look at past COTDs, too

        // // todo:
        // sleep(500);
        // print("api.GetMapsInfo");
        // //
        // auto r = api.GetMapsInfo({cotdLatest_MapId, "EBfG4g4zDXp3OzsBjV7r91_4QO0"});
        // print(r.Length);
        // for (uint i = 0; i < r.Length; i++) {
        //     auto v = r[i];
        //     print(tostring(v.Name));
        // }
    }

    void Update(float dt) {
        // try {
            isCotd.Set(gi.IsCotd());

            if (isCotd.v) {
                cotdLatest_MapId = gi.MapId();
            }

            // When we enter a COTD server
            if (isCotd.ChangedToTrue()) {
                cotdLatest_MapId = gi.MapId();
                // todo did this fix the issue when joining a new COTD?
                startnew(_FullUpdateCotdStatsSeries);
                // startnew(SetCurrentCotdData);
                // startnew(UpdateDivs);
            }
        // } catch {
        //     warn("Exception in Update: " + getExceptionInfo());
        // }
    }


    void OnSettingsChanged() {
        RegenHistogramData();
        RenewActiveDivs();
    }


    void InitDivRows() {
        for (uint i = 0; i < divRows.Length; i++) {
            @divRows[i] = DivRow(i + 1);
        }
    }


    void LoopUpdateCotdStatus() {
        while (true) {
            // do these in series b/c we don't care how long it takes.
            startnew(_FullUpdateCotdStatsSeries);
            sleep(3600 * 1000 /* 1hr */);
        }
    }

    void _FullUpdateCotdStatsSeries() {
        ApiUpdateCotdStatus();
        // dependent on status
        CoroUpdatePlayerDiv();
        UpdateDivs();
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
        logcall('ApiUpdateCotdStatus', Json::Write(cotdLatest_Status));
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
        if (Setting_AdvCheckPriorCotd) { return true; }
        auto c = GetChallenge();
        if (IsJsonNull(c)) { return false; }
        int64 nowTs = Time::get_Stamp();
        int64 challengeStart = c["startDate"];
        return nowTs < challengeStart;
    }

    /* wrapped by GetChallengeId() */
    int _GetChallengeId() {
        auto c = GetChallenge();
        if (IsJsonNull(c)) { return 0; }
        int offset = isCotd.v || !_ViewPriorChallenge() ? 0 : (-1);
        return IsJsonNull(c) ? 0 : int(c["id"]) + offset;
    }

    int GetChallengeId() {
        if (cotd_OverrideChallengeId.isSome) {
            return cotd_OverrideChallengeId.val;
        }
        return _GetChallengeId();
    }

    /* Set COTD Players Rank */

    void ApiUpdateCotdPlayerRank() {
        while (GetChallengeId() == 0 || cotdLatest_MapId == "") {
            yield();
        }
        /* if we updated in last 1500ms wait for obj to be not null and return */
        if (!debounce.CanProceed('getCotdPlayerRank', 1500)) {
            while (IsJsonNull(cotdLatest_PlayerRank)) { yield(); }
            return;
        }

        cotdLatest_PlayerRank = api.GetPlayerRank(GetChallengeId(), cotdLatest_MapId, gi.PlayersId());
        trace("[ApiUpdateCotdPlayerRank] from api got: " + Json::Write(cotdLatest_PlayerRank));
    }

    uint GetCotdPlayerRank() {
        auto pr = cotdLatest_PlayerRank;
        return IsJsonNull(pr) ? 0 : pr['records'].Length > 0 ? pr['records'][0]['rank'] : 0;
    }

    uint GetCotdTotalPlayers() {
        auto pr = cotdLatest_PlayerRank;
        return IsJsonNull(pr) ? 0 : pr['cardinal'];
    }

    uint GetCotdTotalDivs() {
        return uint(Math::Ceil(GetCotdTotalPlayers() / 64.0));
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
        for (uint i = 0; i < TOP_5.Length; i++) {
            _AddDivToQueueIfNotActive(TOP_5[i]);
        }
        uint pDiv = playerDivRow.div;
        // add divs around player. make sure to avoid re-requesting top 5
        for (uint i = Math::Max(5, pDiv - 3); i < pDiv + 3; i++) {
            _AddDivToQueueIfNotActive(i);
        }
    }

    void _AddDivToQueueIfNotActive(uint i) {
        if (cotd_ActiveDivRows.Find(i) < 0) {
            PutDivToUpdateInQ(i);
            startnew(CoroUpdateDivFromQ);
        }
    }

    /* set active div rows based on player rank, settings, etc */
    void RenewActiveDivs() {
        trace("RenewActiveDivs");
        // while (divRows[0] is null) { yield(); }
        if (Setting_HudShowAllDivs) {
            cotd_ActiveDivRows = array<uint>(99);
            for (uint i = 0; i < cotd_ActiveDivRows.Length; i++) {
                cotd_ActiveDivRows[i] = i + 1;
            }
        } else {
            uint pDiv = playerDivRow.div;
            int min, max;
            min = Math::Max(1, pDiv - Setting_HudShowAboveDiv);
            max = Math::Min(GetCotdTotalDivs(), pDiv - 1 + Setting_HudShowBelowDiv);
            int size = Math::Max(0, max - min + 1);
            uint[][] groups = {{min, max}};
            if (Setting_HudShowTopDivCutoffs > 0) {
                if (Setting_HudShowTopDivCutoffs > min) {
                    // one contiguous group
                    auto upper = Math::Max(max, Setting_HudShowTopDivCutoffs);
                    groups = {{1, upper}};
                    size = upper;
                } else {
                    groups = {{1, Setting_HudShowTopDivCutoffs}, {min, max}};
                    size += Setting_HudShowTopDivCutoffs;
                }
            }
            cotd_ActiveDivRows = array<uint>(size);
            uint ix = 0;
            uint totalSize = 0;
            for (uint i = 0; i < groups.Length; i++) {
                auto g = groups[i];
                min = g[0];
                max = g[1];
                if (min > max) { continue; }
                totalSize += (max - min + 1);
                for (int j = min; j <= max; j++) {
                    cotd_ActiveDivRows[ix++] = j;
                }
            }
            if (ix != totalSize || int(totalSize) != size) {
                throw("RenewActiveDivs size error: " + ix + ", " + totalSize + ", " + size);
            }
        }
        uint _d; // the div
        for (uint i = 0; i < divRows.Length; i++) {
            if (divRows[i] !is null) { divRows[i].visible = false; }
        }
        for (uint i = 0; i < cotd_ActiveDivRows.Length; i++) {
            _d = cotd_ActiveDivRows[i];
            /* this is a bit of a cheat -- the div won't be drawn if it doesn't have a valid time */
            divRows[_d - 1].visible = true;
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
            if (res.Length > 0)
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
            playerDivRow.div = uint(Math::Ceil(pRank / 64.0));

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
        if (!debounce.CanProceed("histogramTimes", 5000)) { return; }
        if (Setting_HudShowHistogram && !IsJsonNull(cotdLatest_PlayerRank)) {
            int pRank = 101;
            if (cotdLatest_PlayerRank["records"].Length > 0) {
                // adjust player's rank down 50 so that we get (-150, +50) times
                pRank = Math::Max(51, cotdLatest_PlayerRank["records"][0]["rank"]) - 50;
            }
            if (pRank <= 100) {
                pRank = 101;
            }
            if (pRank > 100 && pRank > int(GetCotdTotalPlayers()) - 99) {
                pRank = GetCotdTotalPlayers() - 99;
            }

            cotd_HistogramMinMaxRank = int2(pRank - 100, pRank + 99);
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

        uint ixUpper = Math::Min(100, timesData.Length);
        // if (ixUpper > 100 + args.ix) { ixUpper = 100 + args.ix; }
        uint rTime;
        for (uint i = 0; i < ixUpper; i++) {
            rTime = timesData[i]["score"];
            /* filter out times that are more than 90s (since they're mostly noise WRT COTD) */
            if (rTime > 90000) { continue; }
            cotd_TimesForHistogram[args.ix + i] = rTime;
            // trace("_CoroUpdateManyTimesFromRank: " + tostring(cotd_TimesForHistogram[args.ix + i]));
        }
        RegenHistogramData();
    }

    void RegenHistogramData() {
        @cotd_HistogramData = Histogram::RawDataToHistData(cotd_TimesForHistogram, Setting_HudHistogramBuckets);
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

    uint defPrintSleepMs = 1000;

    void LoopDevPrintState() {
        // float multiplier = 1.1f;
        // while (true) {
        //     sleep(defPrintSleepMs * multiplier);
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



// this works:
// print("challenge api for may 23");
// print(Json::Write(api.GetPlayerRank(1356, "H2vizj2y7Jqc5dznImB4NaSbnx3", "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9")));

/* for explorer:
- would need to get past maps
- challenge ids -- logical?
- 1356, 55, 54

- 1353 -- #3 on 2022-05-22
- 1350 -- #3 on 2022-05-21
- 1347 -- #3 on 2022-05-20
*/

// 1201 should be first COTD on 49 days prior; 29 from 1st may, 28 from 30th apr => 2nd Apr
// print("challenge api for april 2");
// print(Json::Write(api.GetPlayerRank(1201, "sTvb8KzSHxJYRJmSHqckAFwW8Hi", "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9")));
// ABOVE DOES NOT WORK

// works:
// print("challenge api for april 2");
// print(Json::Write(api.GetPlayerRank(1176, "sTvb8KzSHxJYRJmSHqckAFwW8Hi", "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9")));

// works:
// print("GetTotdByMonth with length 100 and offset 0");
// print("Sz len: " + Json::Write(api.GetTotdByMonth(100)).Length);
