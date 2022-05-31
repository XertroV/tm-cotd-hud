dictionary@ JSON_DB_MUTEXES = dictionary();

class JsonBox {
    int _asdf;
    Json::Value j;

    JsonBox(Json::Value _j) {
        this.j = _j;
    }
}

class JsonDb {
    string path;
    JsonBox@ _data;
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
                @_data = JsonBox(Json::Object());
                Json::ToFile(path, _data.j);
            } catch {
                throw("Unable to write JsonDb to file! Exception: " + getExceptionInfo());
            }
        }

        /* no more init/prep to do */
        this.LoadFromDisk();
    }

    /* broken b/c of how json stuff is handled? */
    JsonBox@ get_data() {
        while (locked) { yield(); }
        return _data;
    }

    void LoadFromDisk() {
        locked = true;
        auto v = Json::FromFile(path);
        if (IsJsonNull(v)) {
            /* a default of sorts */
            @_data = JsonBox(Json::Object());
            return;
        }

        if (!IsJsonNull(v['version'])) {
            int version = v['version'];
            if (version != 1) {
                throw("Bad version number " + version + " for JsonDb file: " + path);
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
        locked = false;
    }

    void Persist() {
        locked = true;
        Json::Value db = Json::Object();
        db['version'] = 1;
        db['time'] = "" + Time::Stamp;  /* as string to avoid losing precision */
        db['data'] = _data.j;
        Json::ToFile(path, db);
        locked = false;
    }
}
