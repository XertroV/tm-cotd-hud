dictionary@ JSON_DB_MUTEXES = dictionary();

class JsonDb {
    string path;
    private Json::Value _data;
    int loadedTime = 0;
    bool locked = false;

    JsonDb(const string &in _path) {
        path = _path;
        if (!path.EndsWith('.json')) {
            path += '.json';
        }

        if (cast<JsonDb@>(JSON_DB_MUTEXES[path]) !is null) {
            throw("Duplicate JsonDb created for path: " + path);
        }
        @JSON_DB_MUTEXES[path] = this;

        /* create if it doesn't exist */
        if (!IO::FileExists(path)) {
            try {
                // create an empty file
                Json::ToFile(path, Json::Object());
            } catch {
                throw("Unable to write JsonDb to file! Exception: " + getExceptionInfo());
            }
        }

        /* no more init/prep to do */
        this.LoadFromDisk();
    }

    Json::Value get_data() {
        while (locked) { yield(); }
        return _data;
    }

    void LoadFromDisk() {
        locked = true;
        auto v = Json::FromFile(path);
        if (IsJsonNull(v)) {
            /* a default of sorts */
            _data = Json::Object();
            return;
        }

        if (!IsJsonNull(v['version'])) {
            int version = v['version'];
            if (version != 1) {
                throw("Bad version number " + version + " for JsonDb file: " + path);
            }
        }

        if (IsJsonNull(v['data'])) {
            _data = Json::Object();
        } else {
            _data = v['data'];
        }

        /* set loadedTime */
        if (!IsJsonNull(v['time'])) {
            loadedTime = v['time'];
        }
        locked = false;
    }

    void Persist() {
        locked = true;
        Json::Value db = Json::Object();
        db['version'] = 1;
        db['time'] = Time::Stamp;
        db['data'] = _data;
        Json::ToFile(path, db);
        locked = false;
    }
}
