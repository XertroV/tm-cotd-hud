shared class SyncData {
  /* Properties // Mixin: Default Properties */
  private uint _lastUpdated;
  private string _status;
  
  /* Properties // Mixin: Persistent */
  private string _path;
  private bool _doPersist = false;
  bool quiet = false;
  
  /* Methods // Mixin: Default Constructor */
  SyncData(uint lastUpdated, const string &in status) {
    this._lastUpdated = lastUpdated;
    this._status = status;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  SyncData(const Json::Value &in j) {
    try {
      this._lastUpdated = j["lastUpdated"];
      this._status = j["status"];
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["lastUpdated"] = _lastUpdated;
    j["status"] = _status;
    return j;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  uint get_lastUpdated() const {
    return this._lastUpdated;
  }
  
  const string get_status() const {
    return this._status;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'SyncData('
      + string::Join({'lastUpdated=' + '' + lastUpdated, 'status=' + status}, ', ')
      + ')';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const SyncData@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _lastUpdated == other.lastUpdated
      && _status == other.status
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += '' + _lastUpdated + ",";
    ret += TRS_WrapString(_status) + ",";
    return ret;
  }
  
  private const string TRS_WrapString(const string &in s) {
    string _s = s.Replace('\n', '\\n').Replace('\r', '\\r');
    string ret = '(' + _s.Length + ':' + _s + ')';
    if (ret.Length != (3 + _s.Length + ('' + _s.Length).Length)) {
      throw('bad string length encoding. expected: ' + (3 + _s.Length + ('' + _s.Length).Length) + '; but got ' + ret.Length);
    }
    return ret;
  }
  
  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    buf.Write(_lastUpdated);
    WTB_LP_String(buf, _status);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4;
    bytes += 4 + _status.Length;
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  /* Methods // Mixin: Empty Constructor With Defaults */
  SyncData() {
    _lastUpdated = 0;
    _status = '';
  }
  
  /* Methods // Mixin: Persistent */
  SyncData(StorageLocation@ storageLoc) {
    uint start = Time::Now;
    InitPersist(storageLoc);
    ReloadFromDisk();
  }
  
  void InitPersist(StorageLocation@ storageLoc) {
    if (_doPersist) throw('Persistence already initialized.');
    storageLoc.EnsureDirExists();
    _path = storageLoc.Path;
    _doPersist = true;
  }
  
  void Persist(bool _quiet = false) {
    auto start = Time::Now;
    Buffer@ buf = Buffer();
    WriteToBuffer(buf);
    buf.Seek(0);
    IO::File f(_path, IO::FileMode::Write);
    f.Write(buf._buf);
    f.Close();
    if (!(quiet || _quiet)) {
      trace('\\$a4fSyncData\\$777 saved \\$a4f' + 1 + '\\$777 entries from: \\$a4f' + _path + '\\$777 in \\$a4f' + (Time::Now - start) + ' ms\\$777.');
    }
  }
  
  void ReloadFromDisk() {
    IO::File f(_path, IO::FileMode::Read);
    Buffer@ buf = Buffer(f.Read(f.Size()));
    f.Close();
    /* Parse field: _lastUpdated of type: uint */
    _lastUpdated = buf.ReadUInt32();
    /* Parse field: _status of type: string */
    _status = RFB_LP_String(buf);
  }
  
  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
  
  void set_lastUpdated(uint lastUpdated) {
    _lastUpdated = lastUpdated;
    if (_doPersist) Persist();
  }
  
  void set_status(const string &in status) {
    _status = status;
    if (_doPersist) Persist();
  }
}

namespace _SyncData {
  /* Namespace // Mixin: Row Serialization */
  shared SyncData@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: lastUpdated of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint lastUpdated = Text::ParseInt(chunk);
    /* Parse field: status of type: string */
    try {
      FRS_Assert_String_Eq(remainder.SubStr(0, 1), '(');
      tmp = remainder.SubStr(1).Split(':', 2);
      chunkLen = Text::ParseInt(tmp[0]);
      chunk = tmp[1].SubStr(0, chunkLen);
      remainder = tmp[1].SubStr(chunkLen + 2);
      FRS_Assert_String_Eq(tmp[1].SubStr(chunkLen, 2), '),');
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    string status = chunk;
    return SyncData(lastUpdated, status);
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared SyncData@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: lastUpdated of type: uint */
    uint lastUpdated = buf.ReadUInt32();
    /* Parse field: status of type: string */
    string status = RFB_LP_String(buf);
    return SyncData(lastUpdated, status);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
  
  /* Namespace // Mixin: Persistent */
}