namespace DbSync {
    bool Exists(Json::Value v) {
        return v.GetType() == Json::Type::Object;
    }
    bool IsStarted(Json::Value v) {
        return Exists(v) && v['id'] == "Started";
    }
    bool IsInProg(Json::Value v) {
        return Exists(v) && v['id'] == "InProg";
    }
    bool IsWaiting(Json::Value v) {
        return Exists(v) && v['id'] == "Waiting";
    }
    bool IsUpkeep(Json::Value v) {
        return Exists(v) && v['id'] == "Upkeep";
    }
}


HistoryDb@ HIST_DB_GLOBAL_SINGLETON;


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
        super(path);
    }

    void SyncLoops() {
        @api = CotdApi();
        startnew(CoroutineFunc(_SyncLoopChallenges));
        // startnew(CoroutineFunc(_SyncLoopTotdMaps));
        // startnew(CoroutineFunc(_SyncLoopCotdData));
    }

    Json::Value get_syncData() {
        auto d = data;
        SetDefaultObj(d, 'sync');
        return d['sync'];
    }

    /* SYNC: CHALLENGES */

    void _SyncLoopChallenges() {
        while (true) {
            _SyncChallengesInit();
            _SyncChallengesProgress();
            _SyncChallengesWaiting();
            _SyncChallengesUpkeep();
            yield();
        }
    }

    /* start the sync if it's null/not pres */

    Json::Value get_challengesSyncData() {
        auto d = syncData;
        SetDefaultObj(d, 'challenges');
        return d['challenges'];
    }

    void _SyncChallengesInit() {
        auto d = challengesSyncData;
        if (IsJsonNull(d['id'])) {
            d['id'] = "Started";
        }
        if (DbSync::IsStarted(d)) {
            /* this is only true while we are doing the initial requests */

        }
    }

    void _SyncChallengesProgress() {}

    void _SyncChallengesWaiting() {}

    void _SyncChallengesUpkeep() {}
}


namespace PersistentData {
    const string dataFolder = IO::FromDataFolder("cotd-hud");
    const string filepath_Follows = IO::FromDataFolder("cotd-hud/follows.json");
    const string filepath_HistoricalCotd = IO::FromDataFolder("cotd-hud/historical-cotd.json");
    HistoryDb@ histDb;

    void Main() {
        CreateFilesFoldersIfNeeded();
        InitDbs();
        startnew(LoopMain);
    }

    void InitDbs() {
        @histDb = HistoryDb(filepath_HistoricalCotd);
    }

    void CreateFilesFoldersIfNeeded() {
        if (!IO::FolderExists(dataFolder)) {
            IO::CreateFolder(dataFolder);
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
