class DictOfUintToMatchResults_WriteLog {
  /* Properties // Mixin: Default Properties */
  private dictionary@ _d;

  /* Properties // Mixin: Dict Backing */
  private string _logPath;
  private bool _initialized = false;

  /* Methods // Mixin: Dict Backing */
  DictOfUintToMatchResults_WriteLog(const string &in logDir, const string &in logFile) {
    @_d = dictionary();
    InitLog(logDir, logFile);
  }

  private const string K(uint key) const {
    return '' + key;
  }

  MatchResults@ Get(uint key) const {
    return cast<MatchResults@>(_d[K(key)]);
  }

  MatchResults@ GetOr(uint key, MatchResults@ value) const {
    if (Exists(key)) {
      return Get(key);
    }
    return value;
  }

  const MatchResults@[]@ GetMany(const uint[] &in keys) const {
    array<MatchResults@> ret = {};
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      ret.InsertLast(Get(key));
    }
    return ret;
  }


  void Set(uint key, MatchResults@ value) {
    @_d[K(key)] = value;
    WriteOnSet(key, value);
  }

  bool Exists(uint key) {
    return _d.Exists(K(key));
  }

  uint CountExists(const uint[] &in keys) {
    uint ret = 0;
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      if (Exists(key)) ret++;
    }
    return ret;
  }

  const uint[]@ GetKeys() const {
    array<uint> ret = {};
    auto _keys = _d.GetKeys();
    for (uint i = 0; i < _keys.Length; i++) {
      auto _k = _keys[i];
      ret.InsertLast(Text::ParseInt(_k));
    }
    return ret;
  }

  _DictOfUintToMatchResults_WriteLog::KvPair@ GetItem(uint key) const {
    return _DictOfUintToMatchResults_WriteLog::KvPair(key, Get(key));
  }

  array<_DictOfUintToMatchResults_WriteLog::KvPair@>@ GetItems() const {
    array<_DictOfUintToMatchResults_WriteLog::KvPair@> ret = array<_DictOfUintToMatchResults_WriteLog::KvPair@>(GetSize());
    array<uint> keys = GetKeys();
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      @ret[i] = GetItem(key);
    }
    return ret;
  }

  MatchResults@ opIndex(uint key) {
    return Get(key);
  }

  uint GetSize() const {
    return _d.GetSize();
  }

  bool Delete(uint key) {
    return _d.Delete(K(key));
  }

  void DeleteAll() {
    WriteLogOnResetAll();
    _d.DeleteAll();
  }

  /* Dict Optional: Write Log = True */
  private void InitLog(const string &in logDir, const string &in logFile) {
    _logPath = logDir + '/' + logFile;
    log_trace('DictOfUintToMatchResults_WriteLog dir: ' + logDir + ' | logFile: ' + logFile);
    if (logDir.Length == 0) {
      throw('Invalid path: ' + _logPath);
    }
    if (!IO::FolderExists(logDir)) {
      IO::CreateFolder(logDir, true);
    }
    LoadWriteLogFromDisk();
  }

  private void LoadWriteLogFromDisk() {
    if (IO::FileExists(_logPath)) {
      uint start = Time::Now;
      IO::File f(_logPath, IO::FileMode::Read);
      Buffer@ fb = Buffer(f.Read(f.Size()));
      f.Close();
      while (!fb.AtEnd()) {
        auto kv = _DictOfUintToMatchResults_WriteLog::_KvPair::ReadFromBuffer(fb);
        @_d[K(kv.key)] = kv.val;
      }
      log_trace('\\$a4fDictOfUintToMatchResults_WriteLog\\$777 loaded \\$a4f' + GetSize() + '\\$777 entries from: \\$a4f' + _logPath + '\\$777 in \\$a4f' + (Time::Now - start) + ' ms\\$777.');
      f.Close();
    } else {
      IO::File f(_logPath, IO::FileMode::Write);
      f.Close();
    }
    _initialized = true;
  }

  bool get_Initialized() {
    return _initialized;
  }

  void AwaitInitialized() {
    while (!_initialized) {
      yield();
    }
  }

  private void WriteOnSet(uint key, MatchResults@ value) {
    _DictOfUintToMatchResults_WriteLog::KvPair@ p = _DictOfUintToMatchResults_WriteLog::KvPair(key, value);
    Buffer@ buf = Buffer();
    p.WriteToBuffer(buf);
    buf.Seek(0, 0);
    IO::File f(_logPath, IO::FileMode::Append);
    f.Write(buf._buf);
    f.Close();
  }

  private void WriteLogOnResetAll() {
    IO::File f(_logPath, IO::FileMode::Write);
    f.Write('');
    f.Close();
  }
}

namespace _DictOfUintToMatchResults_WriteLog {
  /* Namespace // Mixin: Dict Backing */
  class KvPair {
    /* Properties // Mixin: Default Properties */
    private uint _key;
    private MatchResults@ _val;

    /* Methods // Mixin: Default Constructor */
    KvPair(uint key, MatchResults@ val) {
      this._key = key;
      @this._val = val;
    }

    /* Methods // Mixin: Getters */
    uint get_key() const {
      return this._key;
    }

    MatchResults@ get_val() const {
      return this._val;
    }

    /* Methods // Mixin: ToString */
    const string ToString() {
      return 'KvPair('
        + string::Join({'key=' + '' + key, 'val=' + val.ToString()}, ', ')
        + ')';
    }

    /* Methods // Mixin: Op Eq */
    bool opEquals(const KvPair@ &in other) {
      if (other is null) {
        return false; // this obj can never be null.
      }
      return true
        && _key == other.key
        && _val == other.val
        ;
    }

    /* Methods // Mixin: Row Serialization */
    const string ToRowString() {
      string ret = "";
      ret += '' + _key + ",";
      ret += TRS_WrapString(_val.ToRowString()) + ",";
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
      buf.Write(_key);
      _val.WriteToBuffer(buf);
    }

    uint CountBufBytes() {
      uint bytes = 0;
      bytes += 4;
      bytes += _val.CountBufBytes();
      return bytes;
    }

    void WTB_LP_String(Buffer@ &in buf, const string &in s) {
      buf.Write(uint(s.Length));
      buf.Write(s);
    }
  }

  namespace _KvPair {
    /* Namespace // Mixin: Row Serialization */
    KvPair@ FromRowString(const string &in str) {
      string chunk = '', remainder = str;
      array<string> tmp = array<string>(2);
      uint chunkLen = 0;
      /* Parse field: key of type: uint */
      try {
        tmp = remainder.Split(',', 2);
        chunk = tmp[0]; remainder = tmp[1];
      } catch {
        warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
        throw(getExceptionInfo());
      }
      uint key = Text::ParseInt(chunk);
      /* Parse field: val of type: MatchResults@ */
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
      MatchResults@ val = _MatchResults::FromRowString(chunk);
      return KvPair(key, val);
    }

    void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
      if (sample != expected) {
        throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
      }
    }

    /* Namespace // Mixin: ToFromBuffer */
    KvPair@ ReadFromBuffer(Buffer@ &in buf) {
      /* Parse field: key of type: uint */
      uint key = buf.ReadUInt32();
      /* Parse field: val of type: MatchResults@ */
      MatchResults@ val = _MatchResults::ReadFromBuffer(buf);
      return KvPair(key, val);
    }

    const string RFB_LP_String(Buffer@ &in buf) {
      uint len = buf.ReadUInt32();
      return buf.ReadString(len);
    }
  }

  /* Namespace // Mixin: DirOf */
  class DirOf {
    /* Properties // Mixin: Default Properties */
    private dictionary@ _objs;

    /* Properties // Mixin: DirOfDictOfUintToMatchResults_WriteLog */
    private string _dir;
    private bool _initialized = false;

    /* Methods // Mixin: DirOfDictOfUintToMatchResults_WriteLog */
    DirOf(const string &in dir) {
      @_objs = dictionary();
      _dir = dir;
      if (!IO::FolderExists(_dir)) {
        IO::CreateFolder(_dir, true);
      }
      RunInit();
    }

    bool get_Initialized() {
      return _initialized;
    }

    void AwaitInitialized() {
      while (!_initialized) {
        yield();
      }
    }

    private void RunInit() {
      auto keys = IO::IndexFolder(_dir, false);
      for (uint i = 0; i < keys.Length; i++) {
        auto key = keys[i];
        if (key.EndsWith('.bin')) {
          Get(UnK(key.SubStr(0, key.Length - 4)));
        }
      }
      _initialized = true;
    }

    private dictionary@ get_objs() {
      return _objs;
    }

    const string K(uint key) {
      return '' + key;
    }

    uint UnK(const string &in keyStr) {
      return Text::ParseInt(keyStr);
    }

    const string GetFileName(uint key) {
      return K(key) + '.bin';
    }

    const string GetFilePath(uint key) {
      return _dir + '/' + GetFileName(key);
    }

    DictOfUintToMatchResults_WriteLog@ ReadFileToObj(const string &in path) {
      throw('do not call ReadFileToObj for dict');
      return null;
    }

    bool Exists(uint key) {
      return objs.Exists(K(key)) || IO::FileExists(GetFilePath(key));
    }

    DictOfUintToMatchResults_WriteLog@ Get(uint key) {
      if (objs.Exists(K(key))) {
        return cast<DictOfUintToMatchResults_WriteLog@>(objs[K(key)]);
      }
      DictOfUintToMatchResults_WriteLog@ obj;
      @obj = DictOfUintToMatchResults_WriteLog(_dir, GetFileName(key));
      @objs[K(key)] = obj;
      return obj;
    }

    void Set(uint key, DictOfUintToMatchResults_WriteLog@ val) {
      throw('Do not call .Set on DirOfDict');
    }
  }

}
