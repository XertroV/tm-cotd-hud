
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
    const string filepath_ThumbQueueDb = MkPath("thumbnail-queue-db.json");
    const string filepath_TimesQueueDb = MkPath("map-times-queue-db.json");
    const string filepath_RecordsQueueDb = MkPath("map-records-queue-db.json");
    const string filepath_CotdIndexDb = MkPath("cotd-index-db.json");
    const string filepath_PlayerNameDb = MkPath("player-name-db.json");
    const string filepath_PlayerNameQDb = MkPath("player-name-q-db.json");

    const string folder_Thumbnails = MkPath("thumbnails");
    const string folder_MapTimes = MkPath("map-times");

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
        CheckAndCreateFolder(dataFolder);
        CheckAndCreateFolder(folder_Thumbnails);
        CheckAndCreateFolder(folder_MapTimes);
        // if (!IO::FileExists(filepath_Follows)) {
        //     // auto f = IO::File(filepath_Follows, IO::FileMode::Write);
        //     // // f.Open(IO::FileMode::Write);  /* Append, Read, None */
        //     // f.Write('{"players": []}');
        //     // f.Close();
        // }
    }

    void CheckAndCreateFolder(const string &in folder) {
        if (!IO::FolderExists(folder)) {
            IO::CreateFolder(folder, true);
        }
    }

    /* thumbnails */

    bool ThumbnailCached(const string &in thumbnailFileName) {
        return IO::FileExists(ThumbnailPath(UrlToFileName(thumbnailFileName)));
    }

    void DownloadThumbnail(const string &in url) {
        string fname = UrlToFileName(url);
        if (ThumbnailCached(fname)) return;
        logcall("DownloadThumbnail", "Starting Download: " + fname);
        auto r = Net::HttpGet(url);
        r.Start();
        while (!r.Finished()) yield();
        if (r.ResponseCode() >= 300) {
            warn("DownloadThumbnail failed with error code " + r.ResponseCode());
        } else {
            r.SaveToFile(ThumbnailPath(fname));
            logcall("DownloadThumbnail", "Downloaded: " + fname);
        }
    }

    string ThumbnailPath(const string &in fname) {
        return folder_Thumbnails + "/" + fname;
    }

    dictionary@ _textureCache = dictionary();

    Resources::Texture@ _ReadFileTex(IO::File f) {
        return Resources::GetTexture(f.Read(f.Size()));
    }

    Resources::Texture@ GetThumbTex(const string &in tnFile) {
        Resources::Texture@ t;
        string fname = UrlToFileName(tnFile);
        if (_textureCache.Exists(fname)) {
            @t = cast<Resources::Texture@>(_textureCache[fname]);
        } else {
            // string p = mainFolderName + "/" + PM + "/thumbnails/" + fname;
            string p = ThumbnailPath(fname);
            logcall("GetThumbTex", "Loading texture from disk: " + p);
            IO::File file(p, IO::FileMode::Read);
            @t = Resources::GetTexture(file.Read(file.Size()));
            // this does not work:
            // auto t = Resources::GetTexture(p);
            @_textureCache[fname] = t;
        }
        if (t is null) {
            warn("[GetThumbTex] got null texture for " + fname);
        }
        return t;
    }

    /* map times */

    string MapTimesPath(const string &in uid, const string &in cotdSuffix) {
        return folder_MapTimes + "/" + uid + "--" + cotdSuffix + ".json";
    }

    bool MapTimesCached(const string &in uid, int cId) {
        string key = uid + "--" + cId;
        return MAP_COTD_TIMES_JBOX.Exists(key) || IO::FileExists(MapTimesPath(uid, "" + cId));
    }

    /* cotd qualifying times */

    dictionary@ MAP_COTD_TIMES_JBOX = dictionary();

    JsonBox@ SaveCotdMapTimes(const string &in mapUid, int cId, Json::Value v) {
        string key = mapUid + "--" + cId;
        JsonBox@ jb;
        if (MAP_COTD_TIMES_JBOX.Exists(key)) {
            @jb = cast<JsonBox@>(MAP_COTD_TIMES_JBOX[key]);
            jb.j = v;
        } else {
            @jb = JsonBox(v);
            @MAP_COTD_TIMES_JBOX[key] = jb;
        }
        Json::ToFile(MapTimesPath(mapUid, '' + cId), v);
        return jb;
    }

    JsonBox@ GetCotdMapTimes(const string &in mapUid, int cId) {
        string key = mapUid + "--" + cId;
        if (MAP_COTD_TIMES_JBOX.Exists(key)) {
            return cast<JsonBox@>(MAP_COTD_TIMES_JBOX[key]);
        }
        auto j = Json::FromFile(MapTimesPath(mapUid, '' + cId));
        auto jb = JsonBox(j);
        @MAP_COTD_TIMES_JBOX[key] = jb;
        return jb;
    }

    /* totd records */

    string MapRecordsPath(const string &in uid) {
        return MapTimesPath(uid, "records");
    }

    bool MapRecordsCached(const string &in uid) {
        return MAP_RECORDS_JBOX.Exists(uid) || IO::FileExists(MapRecordsPath(uid));
    }

    dictionary@ MAP_RECORDS_JBOX = dictionary();

    JsonBox@ SaveMapRecord(const string &in mapUid, Json::Value apiResp) {
        JsonBox@ jb;
        if (MAP_RECORDS_JBOX.Exists(mapUid)) {
            @jb = cast<JsonBox@>(MAP_RECORDS_JBOX[mapUid]);
            jb.j = apiResp;
        } else {
            @jb = JsonBox(apiResp);
            @MAP_RECORDS_JBOX[mapUid] = jb;
        }
        Json::ToFile(MapRecordsPath(mapUid), apiResp);
        return jb;
    }

    JsonBox@ GetMapRecord(const string &in mapUid) {
        if (MAP_RECORDS_JBOX.Exists(mapUid)) {
            return cast<JsonBox@>(MAP_RECORDS_JBOX[mapUid]);
        }
        auto j = Json::FromFile(MapRecordsPath(mapUid));
        auto jb = JsonBox(j);
        @MAP_RECORDS_JBOX[mapUid] = jb;
        return jb;
    }

    void LoopMain() {
        // while (true) {
        //     yield();
        // }
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
            }
            dictionary@ yd = cast<dictionary@>(d[sYear]);
            if (!yd.Exists(sMonth)) {
                @yd[sMonth] = dictionary();
            }
            dictionary@ md = cast<dictionary@>(yd[sMonth]);

            // process maps
            auto days = monthObj['days'];
            for (uint j = 0; j < days.Length; j++) {
                Json::Value map = days[j];
                monthDay = map['monthDay'];
                sDay = Text::Format("%02d", monthDay);
                // md[sDay] should never exist.    // !md.Exists(sDay))
                @md[sDay] = JsonBox(map);
            }
        }
        return d;
    }

    int GetChallengesMaxId() {
        return data.j['challenges']['maxId'];
    }

    Json::Value GetChallenge(int id) {
        return data.j['challenges']['items']['' + id];
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


class CotdIndexDb : JsonDb {
    private HistoryDb@ histDb;

    CotdIndexDb(const string &in path, const string &in dbId) {
        super(path, dbId);
        Init();
    }

    void Init() {
        if (IsJsonNull(data.j['maxId'])) {
            data.j['maxId'] = -1;
            data.j['ymdToCotdChallenges'] = Json::Object();
            Persist();
        }
    }

    void SetHistDb(HistoryDb@ _db) {
        @histDb = _db;
    }

    void DoScan() {
        int maxId = GetMaxId();
        int cMaxId = histDb.GetChallengesMaxId();
        for (int i = maxId + 1; i <= cMaxId; i++) {
            Json::Value c = histDb.GetChallenge(i);
            AddChallenge(i, c);
        }
        Persist();
    }

    private void SetMaxId(int maxId) {
        data.j['maxId'] = maxId;
    }

    void AddChallenge(int id, Json::Value c) {
        if (!IsJsonNull(c)) {
            int cId = c['id'];
            if (cId != id) {
                throw("[AddChallenge] Challenge ID Mismatch! " + id + " vs " + cId);
            }
            string name = c['name'];
            if (name.SubStr(0, 14) == "Cup of the Day") {
                string date = name.SubStr(15, 10); // 2022-05-30
                string[] ymd = date.Split('-');
                auto ymdObj = data.j['ymdToCotdChallenges'];
                auto year = Json::Value(ymdObj.Get(ymd[0], Json::Object()));
                auto month = Json::Value(year.Get(ymd[1], Json::Object()));
                auto day = Json::Value(month.Get(ymd[2], Json::Array()));
                day.Add(cId);
                month[ymd[2]] = day;
                year[ymd[1]] = month;
                data.j['ymdToCotdChallenges'][ymd[0]] = year;
            }
        }
        SetMaxId(id);
    }

    int GetMaxId() {
        return data.j['maxId'];
    }

    int[] GetChallengesForDate(const string &in year, const string &in month, const string &in day) {
        auto cs = data.j['ymdToCotdChallenges']
            .Get(year, Json::Object())
            .Get(month, Json::Object())
            .Get(day, Json::Array());
        int[] _cs = array<int>(cs.Length);
        for (uint i = 0; i < cs.Length; i++) {
            _cs[i] = cs[i];
        }
        return _cs;
    }
}


class CotdTimesReqData {
    string mapUid;
    int cId;
    uint rank;
    uint length;
    CotdTimesReqData(string mapUid, int cId, uint rank, uint length) {
        this.mapUid = mapUid;
        this.cId = cId;
        this.rank = rank;
        this.length = length;
    }
}


class MapDb : JsonDb {
    CotdApi@ api;
    private HistoryDb@ histDb;
    private MapQueueDb@ queueDb;
    private JsonQueueDb@ thumbQDb;
    private JsonQueueDb@ timesQDb;
    private JsonQueueDb@ recordsQDb;
    private CotdIndexDb@ cotdIndexDb;
    private JsonDictDb@ playerNameDb;
    private JsonQueueDb@ playerNameQDb;

    MapDb(const string &in path) {
        super(path, 'mapDb-with-sync-queue');
        @api = CotdApi();
        @queueDb = MapQueueDb(PersistentData::filepath_MapQueueDb);
        @thumbQDb = JsonQueueDb(PersistentData::filepath_ThumbQueueDb, 'thumbQueueDb-v1');
        @timesQDb = JsonQueueDb(PersistentData::filepath_TimesQueueDb, 'timesQueueDb-v1');
        @recordsQDb = JsonQueueDb(PersistentData::filepath_RecordsQueueDb, 'recordsQueueDb-v1');
        @cotdIndexDb = CotdIndexDb(PersistentData::filepath_CotdIndexDb, 'cotdIndexDb-v1');
        @playerNameDb = JsonDictDb(PersistentData::filepath_PlayerNameDb, 'playerNameDb-v1');
        @playerNameQDb = JsonQueueDb(PersistentData::filepath_PlayerNameQDb, 'playerNameQDb-v1');
        startnew(CoroutineFunc(SyncLoops));
    }

    void EnsureInit() {
        if (IsJsonNull(data.j['maps'])) {
            data.j['maps'] = Json::Object();
            Persist();
        }
        while (histDb is null) {
            @histDb = PersistentData::histDb;
        }
        cotdIndexDb.SetHistDb(histDb);
    }

    void SyncLoops() {
        EnsureInit();
        startnew(CoroutineFunc(_SyncLoopMapData));
        startnew(CoroutineFunc(_SyncLoopThumbnails));
        startnew(CoroutineFunc(_IndexLoopCotd));
        startnew(CoroutineFunc(_SyncLoopRecords));
        startnew(CoroutineFunc(_SyncLoopCotdMapTimes));
        startnew(CoroutineFunc(_SyncLoopPlayerNames));
    }

    void _SyncLoopMapData() {
        // todo
        /* - check if empty -> sleep
           - get up to X mapUids from the queue (X <= 100?)
           - call api.GetMapsInfo (or api.GetMap for 1?)
           - add maps to db
           - sleep
        */
        uint upToXMaps = 50;
        while (true) {
            string[] uids = array<string>();
            while (!queueDb.IsEmpty() && uids.Length < upToXMaps) {
                string uid = queueDb.GetQueueItemNow();
                uids.InsertAt(uids.Length, uid);
            }
            if (uids.Length > 0) {
                auto maps = api.GetMapsInfo(uids);
                for (uint i = 0; i < maps.Length; i++) {
                    auto map = maps[i];
                    auto mapj = Json::Object();
                    /* metadata */
                    mapj['Id'] = map.Id;
                    mapj['Uid'] = map.Uid;
                    mapj['Type'] = tostring(map.Type);
                    mapj['Name'] = tostring(map.Name);
                    mapj['Style'] = tostring(map.Style);
                    mapj['TimeStamp'] = '' + map.TimeStamp;
                    /* author stuff */
                    mapj['AuthorAccountId'] = map.AuthorAccountId;
                    mapj['AuthorWebServicesUserId'] = map.AuthorWebServicesUserId;
                    mapj['AuthorDisplayName'] = tostring(map.AuthorDisplayName);
                    mapj['AuthorIsFirstPartyDisplayName'] = map.AuthorIsFirstPartyDisplayName;
                    mapj['SubmitterWebServicesUserId'] = map.SubmitterWebServicesUserId;
                    mapj['SubmitterAccountId'] = map.SubmitterAccountId;
                    /* times */
                    mapj['AuthorScore'] = map.AuthorScore;
                    mapj['GoldScore'] = map.GoldScore;
                    mapj['SilverScore'] = map.SilverScore;
                    mapj['BronzeScore'] = map.BronzeScore;
                    /* files */
                    mapj['ThumbnailUrl'] = map.ThumbnailUrl;
                    mapj['FileUrl'] = map.FileUrl;
                    mapj['FileName'] = tostring(map.FileName);
                    /* save it */
                    data.j['maps'][map.Uid] = mapj;
                    QueueThumbnailGet(map.ThumbnailUrl);
                    logcall('SyncMap', 'Completed: ' + map.Uid);
                }
                Persist();
            } else {
                sleep(250);
            }
        }
    }

    void _SyncLoopThumbnails() {
        while (true) {
            if (!thumbQDb.IsEmpty()) {
                startnew(CoroutineFunc(_DownloadNextThumb));
                yield();
                yield();
            } else {
                sleep(250);
            }
        }
    }

    void _DownloadNextThumb() {
        string tnUrl = thumbQDb.GetQueueItemNow();
        if (!PersistentData::ThumbnailCached(tnUrl)) {
            PersistentData::DownloadThumbnail(tnUrl);
        }
    }

    void _IndexLoopCotd() {
        while (true) {
            int challengesMaxId = histDb.GetChallengesMaxId();
            if (cotdIndexDb.GetMaxId() < challengesMaxId) {
                cotdIndexDb.DoScan();
            }
            sleep(250);
        }
    }

    void _SyncLoopRecords() {
        logcall("_SyncLoopRecords", "Starting");
        while (true) {
            if (!recordsQDb.IsEmpty()) {
                auto toGet = recordsQDb.GetQueueItemNow();
                string mapUid = toGet['uid'];
                if (!PersistentData::MapRecordsCached(mapUid) || toGet.Get('force', false)) {
                    string seasonUid = toGet['seasonUid'];
                    logcall("_SyncLoopRecords", "Downloading " + seasonUid);
                    auto resp = api.GetMapRecords(seasonUid, mapUid);
                    logcall("_SyncLoopRecords", "\\$zResponse: " + Json::Write(resp));
                    if (!IsJsonNull(resp['tops'])) {
                        PersistentData::SaveMapRecord(mapUid, resp);
                    }
                } else {
                    string id = toGet['id'];
                    logcall("_SyncLoopRecords", "skipping " + id);
                }
            } else {
                sleep(250);
            }
            yield();
        }
    }

    void _SyncLoopCotdMapTimes() {
        logcall("_SyncLoopCotdMapTimes", "Starting");
        while (true) {
            if (!timesQDb.IsEmpty()) {
                _GetOneCotdMapTimes();
                yield();
            } else {
                sleep(250);
            }
        }
    }

    void _GetOneCotdMapTimes() {
        auto toGet = timesQDb.GetQueueItemNow();
        string mapUid = toGet['uid'];
        int cId = Text::ParseInt(toGet['challengeId']);
        if (PersistentData::MapTimesCached(mapUid, cId)) return;
        auto initData = Json::Object();
        uint chunkSize = 100;
        initData['chunkSize'] = chunkSize;
        initData['ranges'] = Json::Object();
        uint nPlayers = api.GetPlayerRank(cId, mapUid, '')['cardinal'];
        initData['nPlayers'] = nPlayers;
        auto jb = PersistentData::SaveCotdMapTimes(mapUid, cId, initData);
        for (uint rank = 1; rank < nPlayers; rank += chunkSize) {
            startnew(
                CoroutineFuncUserdata(_GetCotdMapTimesRange),
                CotdTimesReqData(mapUid, cId, rank, chunkSize)
            );
            // sleep a bit to be nice to the api
            sleep(100);
        }
    }

    void _GetCotdMapTimesRange(ref@ _args) {
        auto args = cast<CotdTimesReqData@>(_args);
        auto times = api.GetCotdTimes(args.cId, args.mapUid, args.length, args.rank - 1);
        string[] playerIds = array<string>(times.Length);
        for (uint i = 0; i < times.Length; i++) {
            times[i].Remove('uid');
            playerIds[i] = times[i]['player'];
        }
        auto jb = PersistentData::GetCotdMapTimes(args.mapUid, args.cId);
        jb.j['ranges']['' + args.rank] = times;
        PersistentData::SaveCotdMapTimes(args.mapUid, args.cId, jb.j);
        QueuePlayerNamesGet(playerIds);
    }

    void _SyncLoopPlayerNames() {
        logcall("_SyncLoopPlayerNames", "Starting");
        while (true) {
            if (!playerNameQDb.IsEmpty()) {
                auto _playerIds = playerNameQDb.GetNQueueItemsNow(100);
                string[] playerIds = JArrayToString(_playerIds);
                yield();
                logcall("_SyncLoopPlayerNames", "Fetching " + playerIds.Length + " player names.");
                auto names = api.GetPlayersDisplayNames(playerIds);
                playerNameDb.SetMany(playerIds, names);
            }
            sleep(250);
        }
    }

    /* sync util functions */

    bool HaveIndexedChallenge(int cId) {
        auto v = cotdIndexDb.data.j['indexed']['cId'];
        if (IsJsonNull(v)) return false;
        return v;
    }

    // todo

    /* queue a map for download. safe to call multiple times.
       will do nothing if we have already got the map.
    */
    void QueueMapGet(const string &in mapUid) {
        if (!MapIsCached(mapUid)) {
            queueDb.PutQueueEntry(Json::Value(mapUid));
        } else {
            QueueThumbnailGet(GetMap(mapUid)['ThumbnailUrl']);
        }
    }

    void QueueThumbnailGet(const string &in tnUrl) {
        if (!PersistentData::ThumbnailCached(tnUrl)) {
            thumbQDb.PutQueueEntry(tnUrl);
        }
    }

    void QueueMapChallengeTimesGet(const string &in mapUid, int challengeId) {
        if (!PersistentData::MapTimesCached(mapUid, challengeId)) {
            auto obj = Json::Object();
            obj['id'] = mapUid + "|" + challengeId;
            obj['uid'] = mapUid;
            obj['challengeId'] = '' + challengeId;
            timesQDb.PutQueueEntry(obj);
        }
    }

    void QueueMapRecordGet(const string &in seasonUid, const string &in mapUid, bool force = false) {
        if (!PersistentData::MapRecordsCached(mapUid)) {
            auto obj = Json::Object();
            obj['id'] = mapUid;
            obj['uid'] = mapUid;
            obj['seasonUid'] = seasonUid;
            obj['force'] = force;
            recordsQDb.PutQueueEntry(obj);
        }
    }

    void QueuePlayerNameGet(const string &in playerId) {
        QueuePlayerNamesGet({playerId});
    }

    void QueuePlayerNamesGet(const string[] &in playerIds) {
        string pid;
        int c = 0;
        for (uint i = 0; i < playerIds.Length; i++) {
            pid = playerIds[i];
            if (!playerNameDb.Exists(pid)) {
                playerNameQDb.PutQueueEntry(pid, false);
                c++;
            }
        }
        if (c > 0) playerNameQDb.Persist();
    }

    /* access functions */

    bool MapIsCached(const string &in mapUid) {
        auto map = data.j['maps'][mapUid];
        return !IsJsonNull(map) && !IsJsonNull(map['Id']);
    }

    Json::Value GetMap(const string &in uid) {
        return data.j['maps'][uid];
    }

    Json::Value MapUidToThumbnailUrl(const string &in uid) {
        auto map = GetMap(uid);
        if (IsJsonNull(map)) { return map; }
        return map['ThumbnailUrl'];
    }

    int[] GetChallengesForDate(const string &in year, const string &in month, const string &in day) {
        return cotdIndexDb.GetChallengesForDate(year, month, day);
    }
}
