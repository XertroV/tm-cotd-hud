dictionary@ JSON_DB_MUTEXES = dictionary();

class JsonBox {
    Json::Value j;
    private bool expired = false;

    JsonBox(Json::Value &in jsonVal) {
        this.j = jsonVal;
    }

    // JsonBox() {
    //     this.j = Json::Value();
    // }

    // Json::Value get_j() {
    //     if (expired) { throw("Expired reference!"); }
    //     return this.j;
    // }

    // void set_j(Json::Value newVal) {
    //     this.j = newVal;
    // }

    JsonBox@ Expire() {
        throw("not implemented");
        this.expired = true;
        auto ret = JsonBox(this.j);
        this.j = Json::Value();
        return ret;
    }
}

class JsonDb {
    private string path;
    private string dbId;
    private JsonBox@ _data;
    private int loadedTime = 0;
    private bool locked = false;

    JsonDb(const string &in _path, const string &in _dbId) {
        path = _path;
        if (!path.EndsWith('.json')) {
            path += '.json';
        }
        dbId = _dbId;

        if (cast<JsonDb@>(JSON_DB_MUTEXES[path]) !is null) {
            throw("Duplicate JsonDb created for path: " + path);
        }
        @JSON_DB_MUTEXES[path] = this;

        /* create if it doesn't exist */
        if (!IO::FileExists(path)) {
            try {
                // create an empty file
                @_data = JsonBox(Json::Object());
                Json::ToFile(path, _data.j);
            } catch {
                throw("Unable to write JsonDb to file! Exception: " + getExceptionInfo());
            }
        }

        /* no more init/prep to do */
        this.LoadFromDisk();
    }

    void AwaitUnlock() {
        while (locked) { yield(); }
    }

    /* MUST CALL Unlock() later on!!! */
    void GetLock() {
        AwaitUnlock();
        locked = true;
    }

    void Unlock() {
        if (!locked) {
            throw("Attempt to unlock an already unlocked lock.");
        }
        locked = false;
    }

    /* broken b/c of how json stuff is handled? */
    JsonBox@ get_data() {
        // AwaitUnlock(); /* disable this b/c it can trigger in UI code */
        return _data;
    }

    void LoadFromDisk() {
        GetLock();
        uint start = Time::Now;
        // FromFile is the majority of the time spent in LoadFromDisk
        auto v = Json::FromFile(path);
        // trace_benchmark('JsonDb.LoadFromDisk (Just Json::FromFile) ' + path, Time::Now - start);
        if (IsJsonNull(v)) {
            /* a default of sorts */
            @_data = JsonBox(Json::Object());
            logcall('JsonDb Initialization', path);
            Unlock();
            Persist();
            return;
        }
        if (!IsJsonNull(v['version'])) {
            int version = v['version'];
            if (version != 1) {
                throw("Bad version number " + version + " for JsonDb file: " + path);
            }
        }

        if (!IsJsonNull(v['dbId'])) {
            string _dbId = v['dbId'];
            if (_dbId != this.dbId) {
                throw("Attempt to load db with dbId=" + _dbId + " but was expecting dbId=" + this.dbId);
            }
        }

        if (IsJsonNull(v['data'])) {
            @_data = JsonBox(Json::Object());
        } else {
            @_data = JsonBox(v['data']);
        }

        /* set loadedTime */
        if (!IsJsonNull(v['time'])) {
            try {
                loadedTime = Text::ParseInt(v['time']);
            } catch {}
        }
        uint end = Time::Now;
        trace_benchmark('JsonDb.LoadFromDisk ' + path, end - start);
        Unlock();
    }

    void Persist() {
        GetLock();
        uint start = Time::Now;
        Json::Value db = Json::Object();
        db['version'] = 1;
        db['time'] = "" + Time::Stamp;  /* as string to avoid losing precision */
        db['data'] = _data.j;
        db['dbId'] = dbId;
        // string sz = Json::Write(db);
        // yield();
        // IO::File file(path, IO::FileMode::Write);
        // file.Write(sz);
        Json::ToFile(path, db);
        uint end = Time::Now;
        Unlock();
        if (!IO::FileExists(path)) {
            throw("Attempted to persist JsonDb and the file does not exist!!!!");
        }
        trace_benchmark('JsonDb.Persist ' + path, end - start);
    }
}


class JsonQueueDb : JsonDb {
    JsonQueueDb(const string &in path, const string &in dbId) {
        super(path, dbId);
        StartSyncLoops();
        // asdf
    }

    void StartSyncLoops() {
        CheckInitQueueData();
        ValidateUpgradeQueue();
        startnew(CoroutineFunc(_SyncLoopQueueData));
    }

    void CheckInitQueueData() {
        if (IsJsonNull(data.j) || IsJsonNull(data.j['meta']) || IsJsonNull(data.j['queue'])) {
            if (IsJsonNull(data.j)) data.j = Json::Object();
            if (IsJsonNull(data.j['meta'])) {
                auto meta = Json::Object();
                meta['version'] = 1;
                meta['queueStart'] = "0"; /* these are strings because Json::Write turns integers into x.xxxE+5 sci notation format above ~1m. */
                meta['queueEnd'] = "0"; /* exclusive -- so this is the key of the first 'null' entry. */
                meta['isEmpty'] = true;
                meta['length'] = 0;
                meta['lastUpdated'] = "" + Time::Stamp;
                data.j['meta'] = meta;
            }
            if (IsJsonNull(data.j['queue'])) data.j['queue'] = Json::Object();
            Persist();
        }
    }

    int get_Length() {
        return data.j['meta']['length'];
    }

    int get_CompletedHowMany() {
        return Text::ParseInt(data.j['meta']['queueStart']);
    }

    void ValidateUpgradeQueue() {
        int version = data.j['meta']['version'];
        if (version != 1) {
            throw("Cannot deal with versions other than 1.");
        }
        /* todo: upgrade logic in future if needed */
    }

    void _SyncLoopQueueData() {}

    /* note: up to user to manage these values appropriately.
       The value must be either:
         1. a unique string; or
         2. an object with j['id'] property that's a unique string.
    */
    void PutQueueEntry(Json::Value j, bool persist = true) {
        auto ty = j.GetType();
        if (ty != Json::Type::String && ty != Json::Type::Object) {
            throw("Json value is not a string nor an object.");
        } else if (ty == Json::Type::Object && j['id'].GetType() != Json::Type::String) {
            throw("Json value is an object but the 'id' property is non-existent or not a string.");
        }

        int end = GetQueueEnd();
        data.j['queue']['' + end] = j; /* add queue item */
        auto meta = data.j['meta']; /* update metadata */
        int len = meta['length'];
        meta['queueEnd'] = '' + (end + 1);
        meta['length'] = len + 1;
        meta['isEmpty'] = false;
        meta['lastUpdated'] = "" + Time::Stamp;
        data.j['meta'] = meta;
        if (persist) Persist();
    }

    int GetQueueEnd() {
        return Text::ParseInt(data.j['meta']['queueEnd']);
    }

    int GetQueueStart() {
        return Text::ParseInt(data.j['meta']['queueStart']);
    }

    /* can return null */
    Json::Value GetQueueItemNow(bool persist = true) {
        // return null if no queue items available
        if (IsEmpty()) { return Json::Value(); }
        // init
        int start = GetQueueStart();
        int end = GetQueueEnd();
        auto meta = data.j['meta'];
        int length = meta['length'];
        // consistency checks
        if (start >= end || length <= 0) {
            throw("JsonQueueDb *Emergency* // start >= end (and queue is non-empty) OR length <= 0");
        }
        if (end - start != length) {
            throw("JsonQueueDb *Emergency* // start - end != length");
        }
        /* take an item from the queue */
        auto item = data.j['queue']['' + start];
        /* check item */
        if (IsJsonNull(item)) {
            throw("JsonQueueDb.GetQueueItemNow *Emergency* // should have a valid json item but got Json::Null instead.");
        }
        /* update meta */
        meta['queueStart'] = '' + (1 + start);
        meta['length'] = length - 1;
        meta['isEmpty'] = length - 1 == 0;
        meta['lastUpdated'] = "" + Time::Stamp;
        /* update db */
        data.j['meta'] = meta;
        data.j['queue'].Remove('' + start);
        // save and return
        if (persist) Persist();
        return item;
    }

    Json::Value GetNQueueItemsNow(uint n) {
        Json::Value items = Json::Array();
        for (uint i = 0; i < n; i++) {
            if(IsEmpty()) break;
            items.Add(GetQueueItemNow(false));
        }
        Persist();
        return items;
    }

    /* will yield until a value is available and throw if timeout is reached */
    Json::Value GetQueueItemAsync(int timeoutMs = -1) {
        uint start = Time::Now;
        uint limit = timeoutMs < 0 ? A_MONTH_IN_MS : start + uint(timeoutMs);
        while (IsEmpty()) {
            if (start + limit < Time::Now) {
                throw("Timeout reached!");
            }
            sleep(66);
        } /* sleep a little instead of yielding to be a bit nicer. a yield is 10-30 ms if it's per-frame. */
        auto ret = GetQueueItemNow();
        if (IsJsonNull(ret)) {
            throw("Ahh! Should never happen: GetQueueItemAsync returning null!!!");
        }
        return ret;
    }

    bool IsEmpty() {
        return data.j['meta']['isEmpty'];
    }
}
