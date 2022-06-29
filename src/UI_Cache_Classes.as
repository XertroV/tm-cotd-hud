class CacheQualiTimes {
    private uint _nPlayers;
    private uint _cId = 0;
    private JsonBox@ rawCotdMapTimes;
    private float chunkSize;
    private array<string> _cachedRanks;
    private array<string> _cachedTimes;
    private array<string> _cachedDeltas;
    private array<string> _cachedPlayerIds;
    private uint drawNTopTimes = 10;

    CacheQualiTimes() {}

    uint get_Length() {
        return _cachedRanks.Length;
    }

    uint get_nPlayers() {
        return _nPlayers;
    }
    uint get_cId() {
        return _cId;
    }

    void SetCache(const string &in mapUid, uint cId) {
        if (_cId == cId) return;
        log_trace('SetCache for cId: ' + cId);
        _cId = cId;
        _ResetCacheArrays();
        @rawCotdMapTimes = PersistentData::GetCotdMapTimes(mapUid, cId);
        auto jb = rawCotdMapTimes;
        _nPlayers = jb.j['nPlayers'];
        chunkSize = jb.j['chunkSize'];
        auto topTimes = jb.j['ranges']['1'];
        int lastChunkIx = int(Math::Floor(float(nPlayers - 1) / chunkSize) * chunkSize) + 1;
        auto lastTimes = jb.j['ranges']['' + lastChunkIx];
        int topScore = topTimes[0]['score'];
        for (uint i = 0; i < drawNTopTimes; i++) {
            _CacheRow(topTimes[i], topScore);
        }
        _CacheEmptyRow();
        if (lastTimes.Length >= 2)
            _CacheRow(lastTimes[lastTimes.Length - 2], topScore);
        _CacheRow(lastTimes[lastTimes.Length - 1], topScore);
    }

    private void _CacheRow(Json::Value &in time, int topScore) {
        int rank = time['rank'];
        int score = time['score'];
        string pid = time['player'];
        string delta = c_timeOrange + "+" + Time::Format(score - topScore);
        _AddToCache('' + rank, Time::Format(score), delta, pid);
    }

    private void _CacheEmptyRow() {
        _AddToCache("...","","","");
    }

    private void _AddToCache(const string &in r, const string &in t, const string &in d, const string &in pid) {
        _cachedRanks.InsertLast(r);
        _cachedTimes.InsertLast(t);
        _cachedDeltas.InsertLast(d);
        _cachedPlayerIds.InsertLast(pid);
    }

    private void _ResetCacheArrays() {
        _cachedRanks = {};
        _cachedTimes = {};
        _cachedDeltas = {};
        _cachedPlayerIds = {};
    }

    array<string> GetRow(uint i) {
        return
            { _cachedRanks[i]
            , _cachedTimes[i]
            , _cachedDeltas[i]
            , _cachedPlayerIds[i]
            };
    }
}
