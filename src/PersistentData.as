
namespace PersistentData {
    const string mainFolderName = "cotd-hud";
    /* a path modifier for when we are doing dev etc to avoid clobbering DBs */
#if DEV
    const string PM = "dev";
#elif UNIT_TEST
    const string PM = "unit_test";
#else
    const string PM = "main";
    // const int blah = throw("No runtime environment specified (RELEASE / DEV / UNIT_TEST)");
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
    const string filepath_HistogramGenQDb = MkPath("histogram-gen-q-db.json");

    const string folder_Thumbnails = MkPath("thumbnails");
    const string folder_MapTimes = MkPath("map-times");
    const string folder_HistogramData = MkPath("histograms");
    const string folder_LiveTimesCache = MkPath("live-times-cache");

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
        CheckAndCreateFolder(folder_HistogramData);
        CheckAndCreateFolder(folder_LiveTimesCache);
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

    Resources::Texture@ _ReadFileTex(const string &in filePath) {
        logcall("_ReadFileTex", "Loading texture from disk: " + filePath);
        IO::File f(filePath, IO::FileMode::Read);
        auto ret = UI::LoadTexture(f.Read(f.Size()));
        f.Close();
        return ret;
    }

    Resources::Texture@ GetThumbTex(const string &in tnFile) {
        Resources::Texture@ t;
        string fname = UrlToFileName(tnFile);
        if (_textureCache.Exists(fname)) {
            @t = cast<Resources::Texture@>(_textureCache[fname]);
        } else {
            @t = _ReadFileTex(ThumbnailPath(fname));
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

    /* expensive */
    Json::Value[] GetCotdMapTimesAllJ(const string &in mapUid, int cId) {
        auto jb = GetCotdMapTimes(mapUid, cId);
        int nPlayers = jb.j['nPlayers'];
        int chunkSize = jb.j['chunkSize'];
        Json::Value[] rows = array<Json::Value>(nPlayers);
        string[] keys = jb.j['ranges'].GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto times = jb.j['ranges'][keys[i]];
            for (uint j = 0; j < times.Length; j++) {
                int rank = times[j]['rank'];
                rows[rank - 1] = times[j];
            }
        }
        return rows;
    }

    uint[] GetCotdMapTimesAll(const string &in mapUid, int cId) {
        auto jb = GetCotdMapTimes(mapUid, cId);
        int nPlayers = jb.j['nPlayers'];
        int chunkSize = jb.j['chunkSize'];
        uint[] scores = array<uint>(nPlayers);
        string[] keys = jb.j['ranges'].GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto times = jb.j['ranges'][keys[i]];
            for (uint j = 0; j < times.Length; j++) {
                int rank = times[j]['rank'];
                scores[rank - 1] = times[j]['score'];
            }
        }
        return scores;
    }

    /* totd records */

    string MapRecordsPath(const string &in uid) {
        return MapTimesPath(uid, "records");
    }

    bool MapRecordsCached(const string &in uid) {
        return MAP_RECORDS_JBOX.Exists(uid) || IO::FileExists(MapRecordsPath(uid));
    }

    bool MapRecordsShouldRegen(const string &in uid) {
        if (!MapRecordsCached(uid)) return true;
        return GetMapRecord(uid).j.Get('shouldRegen', true);
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

/* NOTE: There was a pattern improvement: MapDb > HistoryDb wrt architecture via JsonQueueDb.
    HistoryDb will be refactored over time.
 */

// not sure why this doesn't work:
// external shared class DictOfTrackOfTheDayEntry_WriteLog;

class HistoryDb : JsonDb {
    CotdApi@ api;
    DictOfTrackOfTheDayEntry_WriteLog@ totdDb;
    DictOfChallenge_WriteLog@ challengesDb;

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
        @totdDb = DictOfTrackOfTheDayEntry_WriteLog(path.Replace("/historical-cotd.json", ""), "historical-totd.txt");
        @challengesDb = DictOfChallenge_WriteLog(path.Replace("/historical-cotd.json", ""), "historical-challenges.txt");
        startnew(CoroutineFunc(SyncLoops));
    }

    /* Getters for the DB */

    const array<string>@ GetMostRecentTotdDate() {
        auto keys = totdDb.GetKeys();
        keys.SortDesc();
        for (uint i = 0; i < keys.Length; i++) {
            auto totd = totdDb.Get(keys[i]);
            if (totd.mapUid.Length > 0)
                return keys[i].Split("-");
        }
        return {};
    }

    dictionary@ GetCotdYearMonthDayMapTree() {
        auto d = dictionary();
        auto keys = totdDb.GetKeys();
        keys.SortDesc();
        for (uint i = 0; i < keys.Length; i++) {
            string k = keys[i];
            auto totd = totdDb.Get(k);
            if (totd.mapUid.Length == 0) continue;
            auto ymd = k.Split("-");
            if (ymd.Length != 3) {
                warn("ymd.split had a length of " + ymd.Length);
                continue;
            }
            if (!d.Exists(ymd[0])) {
                @d[ymd[0]] = dictionary();
            }
            dictionary@ md = cast<dictionary@>(d[ymd[0]]);
            if (!md.Exists(ymd[1])) {
                @md[ymd[1]] = dictionary();
            }
            dictionary@ dd = cast<dictionary@>(md[ymd[1]]);
            @dd[ymd[2]] = totdDb.Get(k);
        }
        return d;
    }

    int GetChallengesMaxId() {
        return data.j['challenges'].Get('maxId', 0);
    }

    dictionary@ cachedChallenges = dictionary();

    Challenge@ GetChallenge(int id) {
        string _cid = '' + id;
        if (challengesDb.Exists(_cid)) {
            return challengesDb.Get(_cid);
        }
        return null;
        // auto c = data.j['challenges']['items'][_cid];
        // return Challenge(c);
    }

    void ResetChallengesCache() {
        @cachedChallenges = dictionary();
    }

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
        bool goAgain = false;
        while (true) {
            goAgain = _SyncChallengesProgress();
            _SyncChallengesWaiting();
            _SyncChallengesUpkeep();
            if (goAgain) {
                yield();
            } else {
                sleep(5 * 1000);
            }
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

    int ChallengesSdMaxId() {
        return ChallengesSyncData()['state'].Get('maxId', 0);
    }

    void SetChallengesSyncData(Json::Value &in sd) {
        data.j['sync']['challenges'] = sd;
        Persist();
    }

    bool _SyncChallengesProgress() {
        auto sd = ChallengesSyncData();
        auto okayToSkipSleep = false;
        if (!data.j.HasKey('challenges') || IsJsonNull(data.j['challenges'])) {
            data.j['challenges'] = Json::Object();
        }
        if (DbSync::IsInProg(sd)) {
            if (Time::Stamp - Text::ParseInt(sd['state']['updatedAt']) > 3600) {
                /* if we updated a long time ago, update our offset based
                   on new most recent challenge.
                */
                auto latestChallenge = Challenge(api.GetChallenges(1, 0)[0]);
                int maxId = latestChallenge.id;
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
            Challenges@ newCs;
            if (offset < 0) {
                @newCs = Challenges({});
            } else {
                int length = sd['state'].Get('length', 100);
                @newCs = Challenges(api.GetChallenges(length, offset));
            }
            if (newCs.Length > 0) {  // we'll get `[]` response when offset is too high.
                // todo
                auto chs = data.j['challenges'];
                chs['maxId'] = newCs[0].id;  // first entry always has highest id
                for (uint i = 0; i < newCs.Length; i++) {
                    auto c = newCs[i];
                    int _id = c.id;
                    string id = "" + _id;
                    if (!challengesDb.Exists(id)) {
                        challengesDb.Set(id, c);
                    } else {
                        trace("[SyncChallenges] Skipping challenge " + id + " since it's already in the DB.");
                    }
                }
                chs['items'] = Json::Value();
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
            okayToSkipSleep = offset > 0;
            SetChallengesSyncData(sd);
        }
        return okayToSkipSleep;
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
            if (td > 15*60) {
                trace("[ChallengeSyncUpkeep] Checking for updated challenges. (td=" + td + ")");
                auto latestCs = api.GetChallenges(1);
                if (latestCs.GetType() != Json::Type::Array) {
                    // something went wrong, sleep and try again.
                    sleep(3 * 1000);
                    SetChallengesSyncData(sd);
                    return;
                }
                auto latestC = latestCs[0];
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
                uint nextReqTs = _SyncTotdMapsUpdateFromApi(false);
                sd = DbSync::Gen(DbSync::UPKEEP);
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
                    toSleepSecs = 1;
                } else {
                    toSleepSecs = Math::Max(1, onlyAfter - Time::Stamp);
                }
            }
            trace("[SyncLoopTotdMaps] Sleeping for " + toSleepSecs + " seconds. SD: " + Json::Write(sd));
            sleep(toSleepSecs * 1000);
        }
    }

    uint _SyncTotdMapsUpdateFromApi(bool persist = true) {
        /* we can do all this in one api call for the
            next ~6 yrs 5 months (as of May 2022).
            todo before 2029: check if we need to make a second call and merge results.
            */
        auto totdData = TotdResp(api.GetTotdByMonth(100));
        auto ml = totdData.monthList;
        for (uint i = 0; i < ml.Length; i++) {
            auto m = ml[i];
            auto days = m.days;
            for (uint d = 0; d < days.Length; d++) {
                auto day = days[d];
                string key = GetYMD(m.year, m.month, day.monthDay);
                if (!totdDb.Exists(key) || totdDb.Get(key).mapUid.Length == 0) {
                    totdDb.Set(key, day);
                }
                // day['start'] = '' + int(day['startTimestamp']);
                // day['end'] = '' + int(day['endTimestamp']);
                // day.Remove('leaderboardGroup');
                // day.Remove('startTimestamp');
                // day.Remove('endTimestamp');
                // day.Remove('relativeStart');
                // day.Remove('relativeEnd');
                // days[d] = day;
            }
            // m['days'] = days;
            // ml[i] = m;
        }
        // totdData['monthList'] = ml;
        data.j['totd'] = Json::Value();
        if (persist) Persist();
        return totdData.nextRequestTimestamp;
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
    }
}


const Json::Value emptyObj = Json::Object();
const Json::Value emptyArr = Json::Array();

class CotdIndexDb : JsonDb {
    private HistoryDb@ histDb;
    private DictOfCompetition_WriteLog@ compsDb;

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

    void ResetAndReIndex() {
        histDb.ResetChallengesCache();  // hopefully this fixes issue with not detecting challenges right for new COTDs
        data.j['maxId'] = -1;
        data.j['compMaxId'] = -1;
        data.j['ymdToCotdChallenges'] = Json::Object();
        data.j['ymdToCotdComps'] = Json::Object();
        logcall("CotdIndexDb.ResetAndReIndex", "Reset. Scanning now.");
        Persist();
        startnew(CoroutineFunc(DoScan));
        startnew(CoroutineFunc(DoScanComps));
    }

    void SetHistDb(HistoryDb@ _db) {
        @histDb = _db;
    }

    void SetCompsDb(DictOfCompetition_WriteLog@ _db) {
        @compsDb = _db;
    }

    void DoScan() {
        int lastBreak = Time::Now;
        int maxId = GetMaxId();
        int cMaxId = histDb.GetChallengesMaxId();
        if (maxId < cMaxId) {
            for (int i = maxId + 1; i <= cMaxId; i++) {
                if (Time::Now - lastBreak > 15) {
                    yield();
                    lastBreak = Time::Now;
                }
                auto c = histDb.GetChallenge(i);
                AddChallenge(i, c);
            }
            Persist();
        }
    }

    private void SetMaxId(int maxId) {
        data.j['maxId'] = Math::Max(maxId, int(data.j['maxId']));
    }

    void AddChallenge(int id, Challenge@ &in c) {
        if (c !is null) {
            int cId = c.id;
            if (cId != id) {
                throw("[AddChallenge] Challenge ID Mismatch! " + id + " vs " + cId);
            }
            string name = c.name;
            if (name.SubStr(0, 14) == "Cup of the Day") {
                string date = name.SubStr(15, 10); // 2022-05-30
                string[] ymd = FromYMD(date);
                auto ymdObj = data.j['ymdToCotdChallenges'];
                auto year = ymdObj[ymd[0]];
                if (year.GetType() != Json::Type::Object) year = Json::Object();
                auto month = year[ymd[1]];
                if (month.GetType() != Json::Type::Object) month = Json::Object();
                auto day = month[ymd[2]];
                if (day.GetType() != Json::Type::Array) day = Json::Array();

                if (!JArrayContainsInt(day, cId)) {
                    day.Add(cId);
                    month[ymd[2]] = day;
                    year[ymd[1]] = month;
                    data.j['ymdToCotdChallenges'][ymd[0]] = year;
                }
            } else {
                trace("[AddChallenge] skipping challenge with name: " + name);
            }
        }
        SetMaxId(id);
    }

    int GetMaxId() {
        return data.j['maxId'];
    }

    int[] GetChallengesForDate(const string &in year, const string &in month, const string &in day) {
        Json::Value cs;
        int[] _cs;
        try {
            cs = data.j['ymdToCotdChallenges'][year][month][day];
            _cs = array<int>(cs.Length);
        } catch {
            cs = Json::Array();
            _cs = array<int>(0);
        }
        for (uint i = 0; i < cs.Length; i++) {
            _cs[i] = cs[i];
        }
        return _cs;
    }

    private uint lastCompScanNItems = 0;

    void DoScanComps() {
        compsDb.AwaitInitialized();
        int lastBreak = Time::Now;
        auto compsKVs = compsDb.GetItems();
        lastCompScanNItems = compsKVs.Length;
        int nScanned = 0;
        for (uint i = 0; i < compsKVs.Length; i++) {
            if (Time::Now - lastBreak > 15) {
                yield();
                lastBreak = Time::Now;
            }
            auto comp = compsKVs[i].val;
            AddComp(comp);
            SetCompNScanned(++nScanned);
        }
        Persist();
    }

    void DoScanCompsIfNew() {
        compsDb.AwaitInitialized();
        if (lastCompScanNItems < compsDb.GetSize()) {
            DoScanComps();
        }
    }

    void SetCompNScanned(int nScanned) {
        data.j['compNScanned'] = Math::Max(nScanned, int(data.j.Get('compNScanned', 0)));
    }

    int GetCompNScanned() {
        return data.j['compNScanned'];
    }

    void AddComp(Competition@ &in comp) {
        if (comp !is null) {
            if (comp.name.SubStr(0, 14) == "Cup of the Day") {
                string[] ymd = FromYMD(ExtractYMD(comp.name));
                auto ymdObj = data.j['ymdToCotdComps'];
                if (ymdObj.GetType() != Json::Type::Object) ymdObj = Json::Object();

                auto year = ymdObj[ymd[0]];
                if (year.GetType() != Json::Type::Object) year = Json::Object();
                auto month = year[ymd[1]];
                if (month.GetType() != Json::Type::Object) month = Json::Object();
                auto day = month[ymd[2]];
                if (day.GetType() != Json::Type::Array) day = Json::Array();
                if (!JArrayContainsInt(day, comp.id)) {
                    day.Add(comp.id);
                    month[ymd[2]] = day;
                    year[ymd[1]] = month;
                    ymdObj[ymd[0]] = year;
                    data.j['ymdToCotdComps'] = ymdObj;
                }
            } else {
                // trace_dev("[AddComp] skipping competition with name: " + comp.name);
            }
        }
    }

    int[] GetCompsForDate(const string &in y, const string &in m, const string &in d) {
        try {
            auto compIds = data.j['ymdToCotdComps'][y][m][d];
            auto ret = JArrayToInt(compIds);
            ret.SortAsc();
            return ret;
        } catch {
            return {};
        }
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
    GameInfo@ gi = GameInfo();
    CotdApi@ api;
    /* outside of MapDb: only do read stuff with these */
    // todo, put behind getters.
    HistoryDb@ histDb;
    MapQueueDb@ queueDb;
    JsonQueueDb@ thumbQDb;
    JsonQueueDb@ timesQDb;
    JsonQueueDb@ recordsQDb;
    CotdIndexDb@ cotdIndexDb;
    JsonDictDb@ playerNameDb;
    JsonQueueDb@ playerNameQDb;
    DictOfTmMap_WriteLog@ mapDb;
    DictOfCompetition_WriteLog@ compsDb;
    DictOfCompRound_WriteLog@ roundsDb;
    DictOfCompRoundMatch_WriteLog@ matchesDb;
    JsonQueueDb@ compsQDb;
    JsonQueueDb@ roundsQDb;
    JsonQueueDb@ matchesQDb;

    // private JsonQueueDb@ histGenQDb;

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
        @mapDb = DictOfTmMap_WriteLog(PersistentData::dataFolder, "mapDb-maps.txt");
        @compsDb = DictOfCompetition_WriteLog(PersistentData::dataFolder, "compsDb.txt");
        @roundsDb = DictOfCompRound_WriteLog(PersistentData::dataFolder, "compRoundsDb.txt");
        @matchesDb = DictOfCompRoundMatch_WriteLog(PersistentData::dataFolder, "compRoundMatchesDb.txt");
        @compsQDb = JsonQueueDb(PersistentData::dataFolder + "/compsQDb.json", "comps-queueDb-v1");
        @roundsQDb = JsonQueueDb(PersistentData::dataFolder + "/compRoundsQDb.json", "compRounds-queueDb-v1");
        @matchesQDb = JsonQueueDb(PersistentData::dataFolder + "/compRoundMatchesQDb.json", "compRoundMatches-queueDb-v1");
        startnew(CoroutineFunc(SyncLoops));
    }

    void EnsureInit() {
        if (IsJsonNull(data.j['maps'])) {
            data.j['maps'] = Json::Object();
            Persist();
        }
        while (histDb is null) {
            @histDb = PersistentData::histDb;
            yield();
        }
        cotdIndexDb.SetHistDb(histDb);
        cotdIndexDb.SetCompsDb(compsDb);
    }

    void SyncLoops() {
        EnsureInit();
        startnew(CoroutineFunc(_SyncLoopMapData));
        startnew(CoroutineFunc(_SyncLoopThumbnails));
        startnew(CoroutineFunc(_IndexLoopCotd));
        startnew(CoroutineFunc(_SyncLoopRecords));
        startnew(CoroutineFunc(_SyncLoopCotdMapTimes));
        startnew(CoroutineFunc(_SyncLoopPlayerNames));
        startnew(CoroutineFunc(_LoopCheckPlayerNamesInGame));
        startnew(CoroutineFunc(_SyncLoopComps));
        startnew(CoroutineFunc(_SyncLoopCompRounds));
        startnew(CoroutineFunc(_SyncLoopCompRoundMatches));
    }

    private uint _mapsInProgress = 0;
    uint get_mapsInProgress() { return _mapsInProgress; }
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
            if (queueDb.IsEmpty()) {
                _mapsInProgress = 0;
                sleep(50);
                continue;
            }
            string[] uids = ArrayOfJToString(queueDb.GetNQueueItemsNow(upToXMaps));
            _mapsInProgress = uids.Length;
            if (uids.Length > 0) {
                auto maps = api.GetMapsInfo(uids);
                for (uint i = 0; i < maps.Length; i++) {
                    auto mapGameObj = maps[i];
                    auto map = TmMap(mapGameObj);
                    mapDb.Set(map.Uid, map);
                    QueueThumbnailGet(map.ThumbnailUrl);
                    logcall('SyncMap', 'Completed: ' + map.Uid);
                }
                queueDb.Persist();
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
            } else {
                sleep(50);
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
            cotdIndexDb.DoScanCompsIfNew();
            sleep(100);
        }
    }

    void _SyncLoopRecords() {
        logcall("_SyncLoopRecords", "Starting");
        while (true) {
            if (!recordsQDb.IsEmpty()) {
                startnew(CoroutineFunc(_SyncNextRecord));
            } else {
                sleep(50);
            }
            yield();
        }
    }

    void _SyncNextRecord() {
        if (recordsQDb.IsEmpty()) return;
        auto toGet = recordsQDb.GetQueueItemNow();
        string mapUid = toGet['uid'];
        bool shouldGet = PersistentData::MapRecordsShouldRegen(mapUid)
                            || toGet.Get('force', false);
        if (shouldGet) {
            string seasonUid = toGet['seasonUid'];
            logcall("_SyncLoopRecords", "Downloading " + seasonUid + "/" + mapUid);
            auto resp = api.GetMapRecords(seasonUid, mapUid);
            logcall("_SyncLoopRecords", "Got Response");
            if (!IsJsonNull(resp['tops'])) {
                int endTs = Text::ParseInt(toGet['end']);
                resp['shouldRegen'] = endTs > Time::Stamp;
                PersistentData::SaveMapRecord(mapUid, resp);
            }
        } else {
            string id = toGet['id'];
            logcall("_SyncLoopRecords", "skipping " + id);
        }
    }

    void _SyncLoopCotdMapTimes() {
        logcall("_SyncLoopCotdMapTimes", "Starting");
        uint nReqs;
        uint sleepFor;
        while (true) {
            if (!timesQDb.IsEmpty()) {
                nReqs = _GetOneCotdMapTimes();
                sleepFor = 1000 * Math::Max(1, nReqs) + nReqs * 100;
                logcall("_SyncLoopCotdMapTimes", "sleeping for ms: " + sleepFor);
                sleep(sleepFor);  // sleep at least sleepFor ms because the requests are async and take about a second round time in Aus
                yield();
            } else {
                sleep(250);
            }
        }
    }

    uint _GetOneCotdMapTimes() {
        uint nReqs = 0;
        auto toGet = timesQDb.GetQueueItemNow();
        string mapUid = toGet['uid'];
        int cId = Text::ParseInt(toGet['challengeId']);
        bool force = toGet['force'];
        if (!force && PersistentData::MapTimesCached(mapUid, cId)) return 0;
        auto initData = Json::Object();
        uint chunkSize = 100;
        initData['chunkSize'] = chunkSize;
        initData['ranges'] = Json::Object();
        auto resp = api.GetPlayerRank(cId, mapUid, '');
        uint nPlayers;
        if (IsJsonNull(resp)) {
            warn("Got null response for _GetOneCotdMapTimes; toGet=" + Json::Write(toGet));
            // todo: nplayers estimate?
            // nPlayers = getNPlayersFallback(cId, mapUid);
            nPlayers = 0;
            initData['error'] = 'null response for map|cId: ' + string(toGet['id']);
        } else {
            nPlayers = resp['cardinal'];
        }
        initData['nPlayers'] = nPlayers;
        auto jb = PersistentData::SaveCotdMapTimes(mapUid, cId, initData);
        for (uint rank = 1; rank <= nPlayers; rank += chunkSize) {
            startnew(
                CoroutineFuncUserdata(_GetCotdMapTimesRange),
                CotdTimesReqData(mapUid, cId, rank, chunkSize)
            );
            nReqs++;
            // sleep a bit to be nice to the api
            sleep(100);
        }
        return nReqs;
    }

    /* 2021-09-08 returns null for api.GetPlayerRank and api.GetCotdTimes
       This was written to try and get around the first null response.
       */
    // private uint getNPlayersFallback(int cId, const string &in mapUid) {
    //     auto times = api.GetCotdTimes(cId, mapUid, 1, 0);
    //     if (times.Length == 0) { return 0; }
    //     // todo: update if COTDs go over 10k
    //     int guess, upper = 10000, lower = 1;
    //     while (true) {
    //         guess = lower + (upper - lower) / 2;
    //         if (guess == lower) {
    //             warn("guess == lower -- should not happen??");
    //             guess = lower + 1;
    //         }
    //         times = api.GetCotdTimes(cId, mapUid, 1, guess - 1);
    //         if (times.Length == 0) {
    //             // so guess is last empty or there are fewer
    //             if (guess == lower + 1) {
    //                 // then there are `lower` many players
    //                 return uint(lower);
    //             }
    //             upper = guess - 1;
    //         } else {
    //             // there are at least `guess` many players
    //             lower = guess;
    //         }
    //         if (lower == upper) {
    //             if (upper == 10000) { /* don't do this more than once */
    //                 upper *= 2;
    //             } else {
    //                 throw("binary search failed -- lower == upper. should never happen");
    //             }
    //         }
    //     }
    //     throw("should return before here");
    //     return 0;
    // }

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
                string[] playerIds = ArrayOfJToString(_playerIds);
                yield();
                logcall("_SyncLoopPlayerNames", "Fetching " + playerIds.Length + " player names. " + playerIds[0] +  string::Join(playerIds, ","));
                auto names = api.GetPlayersDisplayNames(playerIds);
                playerNameDb.SetMany(playerIds, names);
                logcall("_SyncLoopPlayerNames", "Completed " + names.Length + " player names.");
                if (names.Length == 1) {
                    logcall("_SyncLoopPlayerNames", "(" + playerIds[0] + " -> " + names[0] + ")");
                }
            }
            sleep(250);
        }
    }

    void _LoopCheckPlayerNamesInGame() {
        logcall("_LoopCheckPlayerNamesInGame", "Starting...");
        while (true) {
            auto playerInfos = gi.getPlayerInfos();
            for (uint i = 0; i < playerInfos.Length; i++) {
                auto pi = gi.NetPIToTrackmaniaPI(playerInfos[i]);
                if (!playerNameDb.Exists(pi.WebServicesUserId)) {
                    trace("Caching player id -> name: (" + pi.WebServicesUserId + ", " + pi.Name + ")");
                    playerNameDb.Set(pi.WebServicesUserId, pi.Name);
                    yield();  // lazy instead of making a list of keys and vals
                }
            }
            sleep(30 * 1000);
        }
    }

    /* pattern:
        we are done historical if we have id=1 (nb: first COTD is id=40).
        if we're not done historical then just restart
        - it's only like ~30 requests
        - and once we're done, we're done forever
        now that we're done historical, sync new stuff (which will be repeated every hour)
        - we do this from offset=0 till we hit records we already have.
    */
    void _SyncLoopComps() {
        compsDb.AwaitInitialized();
        _GetCompsHistorical();
        logcall("_SyncLoopComps", "Starting");
        // vars for loop
        uint offset = 0;
        uint length = 10;
        // outer 1hr long loop
        while (true) {
            // reset request params
            offset = 0;
            length = 10;
            bool gotOverlapping = false;
            // inner loop to keep getting rows while there's new stuff
            while (!gotOverlapping) {
                auto comps = Competitions(api.GetCompetitions(length, offset));
                for (uint i = 0; i < comps.Length; i++) {
                    auto comp = comps[i];
                    if (compsDb.Exists('' + comp.id)) {
                        gotOverlapping = true;
                    } else {
                        compsDb.Set('' + comp.id, comp);
                        gotOverlapping = false; // set gotOverlapping back to false if it was true b/c if a new comp gets published then the first comp will be overlapping but the last won't.
                    }
                }
                offset += length;
                length = Math::Min(100, length * 2);
            }
            logcall("_SyncLoopComps", "pausing for 1hr rest; next params would have been: l=" + length + ",o=" + offset + " (earliest exit (no new info) would show l=20,o=10)");
            sleep(3600 * 1000);
        }
    }

    void _GetCompsHistorical() {
        logcall("_GetCompsHistorical", "Starting");
        // nb: could estimate offset here using number of records in DB, but will be an overestimate over time since we'll cache some comps that get deleted.
        uint offset = 0;
        uint length = 100;
        int maxId = -1;
        while (true) {
            if (compsDb.Exists('1')) return; // we're done the historical scan at this point
            auto comps = Competitions(api.GetCompetitions(length, offset));
            if (offset == 0) maxId = comps[0].id;
            if (int(offset) > maxId) throw('should exit before this');
            for (uint j = 0; j < comps.Length; j++) {
                auto comp = comps[j];
                compsDb.Set('' + comp.id, comp);
            }
            logcall("_GetCompsHistorical", "completed loop, got n_comps=" + comps.Length + ", at offset=" + offset);
            offset += length;
            yield();
            sleep(500);
        }
        logcall("_GetCompsHistorical", "Done");
    }

    void _SyncLoopCompRounds() {
        logcall("_SyncLoopCompRounds", "Starting");
        while (true) {
            if (!roundsQDb.IsEmpty()) {
                startnew(CoroutineFunc(_SyncNextCompRound));
            } else {
                sleep(50);
            }
            yield();
        }
    }

    void _SyncNextCompRound() {}

    void _SyncLoopCompRoundMatches() {
        logcall("_SyncLoopCompRoundMatches", "Starting");
        while (true) {
            if (!matchesQDb.IsEmpty()) {
                startnew(CoroutineFunc(_SyncNextCompRoundMatch));
            } else {
                sleep(50);
            }
            yield();
        }
    }

    void _SyncNextCompRoundMatch() {}

    /* sync util functions */

    bool HaveIndexedChallenge(int cId) {
        auto v = cotdIndexDb.data.j['indexed']['cId'];
        if (IsJsonNull(v)) return false;
        return v;
    }

    /* queue a map for download. safe to call multiple times.
       will do nothing if we have already got the map.
    */
    void QueueMapGet(const string &in mapUid, bool persist = true) {
        if (!MapIsCached(mapUid)) {
            queueDb.PutQueueEntry(Json::Value(mapUid), persist);
        } else {
            QueueThumbnailGet(GetMap(mapUid).ThumbnailUrl, persist);
        }
    }

    void QueueThumbnailGet(const string &in tnUrl, bool persist = true) {
        if (!PersistentData::ThumbnailCached(tnUrl)) {
            thumbQDb.PutQueueEntry(tnUrl, persist);
        }
    }

    void QueueMapChallengeTimesGet(const string &in mapUid, int challengeId, bool force = false) {
        Challenge@ challenge = histDb.GetChallenge(challengeId);
        if (challenge is null) {
            warn("Attempted to queue challenge that does not exist! cId=" + challengeId);
            return;
        }
        int cEnd = challenge.endDate;
        int dontDownloadBefore = cEnd;
        if (dontDownloadBefore > Time::Stamp) {
            warn("Skipping QueueMapChallengeTimesGet for future COTD: " + mapUid + "/" + challengeId);
            return;
        }
        if (force || !PersistentData::MapTimesCached(mapUid, challengeId)) {
            auto obj = Json::Object();
            obj['id'] = mapUid + "|" + challengeId;
            obj['uid'] = mapUid;
            obj['challengeId'] = '' + challengeId;
            obj['force'] = force;
            timesQDb.PutQueueEntry(obj);
            logcall("QueueMapChallengeTimesGet", "queued " + challengeId);
        } else {
            trace("QueueMapChallengeTimesGet skipping cached challenge " + challengeId);
        }
    }

    void QueueMapRecordGet(const string &in seasonUid, const string &in mapUid, const string &in endTs, bool force = false) {
        if (PersistentData::MapRecordsShouldRegen(mapUid) || force) {
            auto obj = Json::Object();
            obj['id'] = mapUid;
            obj['uid'] = mapUid;
            obj['seasonUid'] = seasonUid;
            obj['end'] = endTs;
            obj['force'] = force;
            recordsQDb.PutQueueEntry(obj);
            logcall("QueueMapRecordGet", "Queued get req for TOTD records: " + mapUid);
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
            if (!playerNameDb.Exists(pid) && pid.Length > 0) {
                playerNameQDb.PutQueueEntry(pid, false);
                c++;
            }
        }
        if (c > 0) playerNameQDb.Persist();
    }

    /* access functions */

    bool MapIsCached(const string &in mapUid) {
        return mapDb.Exists(mapUid);
        // auto map = data.j['maps'][mapUid];
        // return !IsJsonNull(map) && !IsJsonNull(map['Id']);
    }

    TmMap@ GetMap(const string &in uid) {
        return mapDb.Get(uid);
    }

    string MapUidToThumbnailUrl(const string &in uid) {
        auto map = GetMap(uid);
        return map.ThumbnailUrl;
    }

    int[] GetChallengesForDate(const string &in year, const string &in month, const string &in day) {
        return cotdIndexDb.GetChallengesForDate(year, month, day);
    }

    int[] GetCompsForDate(const string &in y, const string &in m, const string &in d) {
        print("GetCompsForDate: " + string::Join({y,m,d}, "-"));
        return cotdIndexDb.GetCompsForDate(y, m, d);
    }
}
