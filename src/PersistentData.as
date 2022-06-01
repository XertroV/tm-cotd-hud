
namespace PersistentData {
    const string mainFolderName = "cotd-hud";
    /* a path modifier for when we are doing dev etc to avoid clobbering DBs */
#if RELEASE
    const string PM = "main";
#elif DEV
    const string PM = "dev";
#elif UNIT_TEST
    const string PM = "unit_test";
#else
    const int blah = throw("No runtime environment specified (RELEASE / DEV / UNIT_TEST)");
#endif

    /* set our data folder to include the path mod (PM) set above */
    const string dataFolder = IO::FromDataFolder(mainFolderName + "/" + PM);
    string MkPath(string fname) { return dataFolder + "/" + fname; };

    const string filepath_Follows = MkPath("follows.json");
    const string filepath_HistoricalCotd = MkPath("historical-cotd.json");
    const string filepath_MapDb = MkPath("map-db.json");
    const string filepath_MapQueueDb = MkPath("map-queue-db.json");

    HistoryDb@ histDb;
    MapDb@ mapDb;

    void Main() {
        CreateFilesFoldersIfNeeded();
        InitDbs();
        startnew(LoopMain);
    }

    void InitDbs() {
        @histDb = HistoryDb(filepath_HistoricalCotd);
        @mapDb = MapDb(filepath_MapDb);
    }

    void CreateFilesFoldersIfNeeded() {
        if (!IO::FolderExists(dataFolder)) {
            IO::CreateFolder(dataFolder, true);
        }
        // if (!IO::FileExists(filepath_Follows)) {
        //     // auto f = IO::File(filepath_Follows, IO::FileMode::Write);
        //     // // f.Open(IO::FileMode::Write);  /* Append, Read, None */
        //     // f.Write('{"players": []}');
        //     // f.Close();
        // }
    }

    void LoopMain() {
        while (true) {
            yield();
        }
    }
}


namespace DbSync {
    const string IN_PROG = "InProg";
    const string STARTED = "Started";
    const string WAITING = "Waiting";
    const string UPKEEP = "Upkeep";

    bool Exists(Json::Value &in v) {
        return v.GetType() == Json::Type::Object;
    }

    bool IsStarted(Json::Value &in v) {
        return Exists(v) && v['id'] == STARTED;
    }
    bool IsInProg(Json::Value &in v) {
        return Exists(v) && v['id'] == IN_PROG;
    }
    bool IsWaiting(Json::Value &in v) {
        return Exists(v) && v['id'] == WAITING;
    }
    bool IsUpkeep(Json::Value &in v) {
        return Exists(v) && v['id'] == UPKEEP;
    }

    Json::Value Gen(const string &in id) {
        auto j = Json::Object();
        j['id'] = id;
        auto state = Json::Object();
        state['updatedAt'] = "" + Time::Stamp;
        j['state'] = state;
        return j;
    }
}

/* Pattern improvement: MapDb > HistoryDb wrt architecture via JsonQueueDb */

class HistoryDb : JsonDb {
    CotdApi@ api;

    /*
    # a class to help manage the state etc of the history DB

    Note: we will need to turn API IDs (where 0 = most recent) into
    canonical ids (where 0 = first). That way they won't change as we
    sync more items in future.

    ## Sync items:

    - cotd/api/challenges
      - cotd date, challengeId
    - ls/api/token/campaign/month
      - mapUids for all challenges
    - cotd/api/challenge/<id>/records/maps/<map>/players
      - actual COTD data

    ## Sync state:

    - [null / not present]: not started
    - {id: 'Started'}: initialization begun
    - {id: 'InProg', state: {...}}: in progress with persistent state
    - {id: 'Waiting', state: {...}}: initial sync is still ongoing but is held up by the sync of another data set
    - {id: 'Upkeep', state: {...}}: upkeep-mode with persistent state

    */

    HistoryDb(const string &in path) {
        super(path, 'historyDb-totdsAndChallenges');
        @api = CotdApi();
        startnew(CoroutineFunc(SyncLoops));
    }

    /* Getters for the DB */

    // dictionary@ DictWith__Keys() {
    //     auto d = dictionary();
    //     d['__keys'] = array<int>();
    //     return d;
    // }

    dictionary@ GetCotdYearMonthDayMapTree() {
        auto d = dictionary();
        if (IsJsonNull(data.j['totd']) || IsJsonNull(data.j['totd']['monthList'])) return d;

        auto totdML = data.j['totd']['monthList'];
        int year, month, monthDay;
        string sYear, sMonth, sDay;
        array<int>@ keys;
        for (uint i = 0; i < totdML.Length; i++) {
            auto monthObj = totdML[i];
            // prep
            year = monthObj['year'];
            sYear = "" + year;
            month = monthObj['month'];
            sMonth = Text::Format("%02d", month);

            // defaults
            if (!d.Exists(sYear)) {
                @d[sYear] = dictionary();
                // @keys = cast<int[]@>(d['__keys']);
                // keys.InsertAt(keys.Length, year);
            }
            dictionary@ yd = cast<dictionary@>(d[sYear]);
            if (!yd.Exists(sMonth)) {
                @yd[sMonth] = dictionary();
                // @keys = cast<int[]@>(yd['__keys']);
                // keys.InsertAt(keys.Length, month);
            }
            dictionary@ md = cast<dictionary@>(yd[sMonth]);

            // process maps
            auto days = monthObj['days'];
            for (uint j = 0; j < days.Length; j++) {
                Json::Value map = days[j];
                monthDay = map['monthDay'];
                sDay = Text::Format("%02d", monthDay);
                // sDay = "" + monthDay;
                // md[sDay] should never exist.    // !md.Exists(sDay))
                @md[sDay] = JsonBox(map);
                // @keys = cast<int[]@>(md['__keys']);
                // keys.InsertAt(keys.Length, monthDay);
            }
        }

        return d;
    }

    // string[]@ ListTotdYears() {
    //     auto yrs = {};
    //     auto totdML = data.j['totd']['monthList'];
    //     int year, month;
    //     for (uint i = 0; i < totdML.Length; i++) {
    //         year = totdML[i]['year'];
    //         if (yrs.Find(year) < 0) {
    //             yrs.InsertAt(yrs.Length, year);
    //         }
    //     }
    // }

    /* SYNC LOGIC */

    void SyncLoops() {
        startnew(CoroutineFunc(_SyncLoopChallenges));
        sleep(1000);
        startnew(CoroutineFunc(_SyncLoopTotdMaps));
        // startnew(CoroutineFunc(_SyncLoopCotdData));
    }

    /* Sync: Challenges */

    void _SyncLoopChallenges() {
        logcall("_SyncLoopChallenges", "Starting");
        _SyncChallengesInit();
        logcall("_SyncLoopChallenges", "Init done. Looping...");
        while (true) {
            _SyncChallengesProgress();
            _SyncChallengesWaiting();
            _SyncChallengesUpkeep();
            sleep(5 * 1000);
        }
    }

    /* start the sync if it's null/not pres */

    void _SyncChallengesInit() {
        if (IsJsonNull(data.j['sync'])) {
            data.j['sync'] = Json::Object();
        }
        if (IsJsonNull(data.j['sync']['challenges'])) {
            data.j['sync']['challenges'] = Json::Object();
            Persist();
        }
        if (IsJsonNull(data.j['sync']['challenges']['id'])) {
            data.j['sync']['challenges']['id'] = DbSync::STARTED;
            Persist();
        }
        // sync data
        auto sd = data.j['sync']['challenges'];
        if (DbSync::IsStarted(sd)) {
            /* this is only true while we are doing the initial requests */
            auto latestChallenge = api.GetChallenges(1, 0)[0];
            auto newSD = Json::Object();
            newSD['id'] = DbSync::IN_PROG;
            auto state = Json::Object();
            /* we'll go from the (predicted) end of the API's list
               back towards most recent. this way it's easy to keep in sync
               in future. Note: we'll also overlap the offset by a bit so that
               we don't miss any if they're published while we're syncing.
               (Batch size = 100)
            */
            state['maxId'] = latestChallenge['id'];
            state['offset'] = latestChallenge['id'] - 95;
            state['updatedAt'] = "" + Time::Stamp;
            newSD['state'] = state;
            SetChallengesSyncData(newSD);
        }
    }

    Json::Value ChallengesSyncData() {
        return data.j['sync']['challenges'];
    }

    int ChallengesSdUpdatedAt() {
        return Text::ParseInt(ChallengesSyncData()['state']['updatedAt']);
    }

    void SetChallengesSyncData(Json::Value &in sd) {
        data.j['sync']['challenges'] = sd;
        Persist();
    }

    void _SyncChallengesProgress() {
        auto sd = ChallengesSyncData();
        if (DbSync::IsInProg(sd)) {
            if (Time::Stamp - Text::ParseInt(sd['state']['updatedAt']) > 3600) {
                /* if we updated a long time ago, update our offset based
                   on new most recent challenge.
                */
                auto latestChallenge = api.GetChallenges(1, 0)[0];
                int maxId = latestChallenge['id'];
                int oldMaxId = sd['state']['maxId'];
                int maxIdDiff = maxId - oldMaxId;
                print("Updating ChallengesSync state (stale).");
                print("> Old sync data: " + Json::Write(sd));
                sd['state']['maxId'] = maxId;
                sd['state']['offset'] = sd['state']['offset'] + maxIdDiff;
                print("> New sync data: " + Json::Write(sd));
            }
            /* based on the offset, get 100 rows and populate the sync'd DB.
            */
            int offset = sd['state']['offset'];
            Json::Value newCs;
            if (offset < 0) {
                newCs = Json::Array();
            } else {
                int length = sd['state'].Get('length', 100);
                newCs = api.GetChallenges(length, offset);
            }
            if (newCs.Length > 0) {  // we'll get `[]` response when offset is too high.
                auto chs = Json::Value(data.j.Get('challenges', Json::Object()));
                chs['maxId'] = newCs[0]['id'];  // first entry always has highest id
                auto items = Json::Value(chs.Get('items', Json::Object()));
                for (uint i = 0; i < newCs.Length; i++) {
                    auto c = newCs[i];
                    int _id = c['id'];
                    string id = "" + _id;
                    if (IsJsonNull(items[id])) {
                        items[id] = c;
                    } else {
                        trace("[SyncChallenges] Skipping challenge " + id + " since it's already in the DB.");
                    }
                }
                chs['items'] = items;
                data.j['challenges'] = chs;
            }
            if (offset == 0) {
                // this was the last run we had to do
                offset = -1;
            }
            if (offset > 0) {
                // reduce the offset to a minimum of 0
                offset = Math::Max(0, offset - 95);
            }
            if (offset >= 0) {
                sd['state']['offset'] = offset;
                sd['state']['updatedAt'] = "" + Time::Stamp;
            } else {
                sd = GenChallengesUpkeepSyncData();
            }
            // check exit condition? offset < 0?
            SetChallengesSyncData(sd);
        }
    }

    void _SyncChallengesWaiting() {
        if (DbSync::IsWaiting(ChallengesSyncData())) {
            throw("Ahh! ChallengesSync should never be WAITING.");
        }
    }

    Json::Value GenChallengesInProgSyncData(int maxId) {
        auto j = DbSync::Gen(DbSync::IN_PROG);
        int oldMaxId = data.j['challenges']['maxId'];
        int offset = Math::Max(0, maxId - oldMaxId - 95);
        j['state']['maxId'] = maxId;
        j['state']['offset'] = offset;
        return j;
    }

    Json::Value GenChallengesUpkeepSyncData() {
        auto j = DbSync::Gen(DbSync::UPKEEP);
        j['state']['maxId'] = data.j['challenges']['maxId'];
        return j;
    }

    void _SyncChallengesUpkeep() {
        /* todo */
        auto sd = ChallengesSyncData();
        if (DbSync::IsUpkeep(sd)) {
            int td = Time::Stamp - ChallengesSdUpdatedAt();
            if (td > 3600) {
                trace("[ChallengeSyncUpkeep] Checking for updated challenges. (td=" + td + ")");
                auto latestC = api.GetChallenges(1)[0];
                int newMaxId = latestC['id'];
                int oldMaxId = sd['state']['maxId'];
                trace("[ChallengeSyncUpkeep] challenge latest IDs >> old: " + oldMaxId + ", new: " + newMaxId);
                if (newMaxId > oldMaxId) {
                    /* in prog */
                    trace("[ChallengeSyncUpkeep] triggering in-progress sync");
                    sd = GenChallengesInProgSyncData(newMaxId);
                    sd['state']['length'] = (newMaxId - oldMaxId + 1) * 2;
                } else {
                    sd['state']['updatedAt'] = "" + Time::Stamp;
                }
                SetChallengesSyncData(sd);
            }
        }
    }

    /* Sync TOTD */

    void _SyncLoopTotdMaps() {
        while (IsJsonNull(data.j['sync'])) { yield(); }
        auto sd = TotdMapsSyncData();
        if (!DbSync::Exists(sd) || DbSync::IsStarted(sd)) {
            sd = DbSync::Gen(DbSync::IN_PROG);
            SetTotdMapsSyncData(sd);
        }
        int toSleepSecs;
        while (true) {
            toSleepSecs = 60;
            sd = TotdMapsSyncData();
            trace("[TotdMapsSync] Loop Start. SD: " + Json::Write(sd));
            if (DbSync::IsInProg(sd)) {
                _SyncTotdMapsUpdateFromApi(false);
                sd = DbSync::Gen(DbSync::UPKEEP);
                int nextReqTs = data.j['totd']['nextRequestTimestamp'];
                sd['state']['updateAfter'] = "" + nextReqTs;
                trace("[TotdMapsSync] Done InProg. SD: " + Json::Write(sd));
                SetTotdMapsSyncData(sd);
            }
            if (DbSync::IsWaiting(sd)) {
                throw("Ahh! TotdMapsSync should never be WAITING.");
            }
            if (DbSync::IsUpkeep(sd)) {
                int onlyAfter = Text::ParseInt(sd['state']['updateAfter']);
                if (Time::Stamp > onlyAfter) {
                    sd = DbSync::Gen(DbSync::IN_PROG);
                    SetTotdMapsSyncData(sd);
                } else {
                    toSleepSecs = Math::Max(1, onlyAfter - Time::Stamp);
                }
            }
            trace("[SyncLoopTotdMaps] Sleeping for " + toSleepSecs + " seconds. SD: " + Json::Write(sd));
            sleep(toSleepSecs * 1000);
        }
    }

    void _SyncTotdMapsUpdateFromApi(bool persist = true) {
        /* we can do all this in one api call for the
            next ~6 yrs 5 months (as of May 2022).
            todo before 2029: check if we need to make a second call and merge results.
            */
        auto totdData = api.GetTotdByMonth(100);
        data.j['totd'] = totdData;
        if (persist) Persist();
    }

    Json::Value TotdMapsSyncData() {
        return data.j['sync']['totd'];
    }

    void SetTotdMapsSyncData(Json::Value sd, bool persist = true) {
        data.j['sync']['totd'] = sd;
        if (persist) Persist();
    }
}


class MapQueueDb : JsonQueueDb {
    MapQueueDb(const string &in path) {
        super(path, 'mapQueueDb-v1');
        startnew(CoroutineFunc(SyncLoops));
    }

    void SyncLoops() {
        // CheckInitQueueData();
        // startnew(CoroutineFunc(_SyncLoopMapData));
    }
}


class MapDb : JsonDb {
    CotdApi@ api;
    private MapQueueDb@ queueDb;

    MapDb(const string &in path) {
        super(path, 'mapDb-with-sync-queue');
        @api = CotdApi();
        @queueDb = MapQueueDb(PersistentData::filepath_MapQueueDb);
        startnew(CoroutineFunc(SyncLoops));
    }

    void SyncLoops() {
        startnew(CoroutineFunc(_SyncLoopMapData));
    }

    void _SyncLoopMapData() {
        // todo
    }

    /* sync util functions */

    // todo

    /* queue a map for download. safe to call multiple times.
       will do nothing if we have already got the map.
    */
    void QueueMapGet(const string &in mapUid) {
        if (!MapIsCached(mapUid)) {
            queueDb.PutQueueEntry(Json::Value(mapUid));
        }
    }

    /* access functions */

    bool MapIsCached(const string &in mapUid) {
        auto map = data.j['maps'][mapUid];
        return !IsJsonNull(map) && !IsJsonNull(map['mapId']);
    }
}
