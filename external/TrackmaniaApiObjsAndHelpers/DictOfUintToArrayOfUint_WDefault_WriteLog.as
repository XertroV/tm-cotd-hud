class DictOfUintToArrayOfUint_WDefault_WriteLog {
  /* Properties // Mixin: Default Properties */
  private dictionary@ _d;

  /* Properties // Mixin: Dict Backing */
  private string _logPath;
  private bool _initialized = false;

  /* Methods // Mixin: Dict Backing */
  DictOfUintToArrayOfUint_WDefault_WriteLog(const string &in logDir, const string &in logFile) {
    @_d = dictionary();
    InitLog(logDir, logFile);
  }

  private const string K(uint key) const {
    return '' + key;
  }

  const uint[]@ Get(uint key) const {
    return cast<array<uint>>(_d[K(key)]);
  }

  const uint[]@ GetOr(uint key, const uint[] &in value) const {
    if (Exists(key)) {
      return Get(key);
    }
    return value;
  }

  const array<uint>[]@ GetMany(const uint[] &in keys) const {
    array<array<uint>> ret = {};
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      ret.InsertLast(Get(key));
    }
    return ret;
  }

  const uint[]@ GetOrDefault(uint key) {
    if (!Exists(key)) {
      Set(key, {});
    }
    return Get(key);
  }

  void Set(uint key, const uint[] &in value) {
    _d[K(key)] = value;
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

  _DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair@ GetItem(uint key) const {
    return _DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair(key, Get(key));
  }

  array<_DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair@>@ GetItems() const {
    array<_DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair@> ret = array<_DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair@>(GetSize());
    array<uint> keys = GetKeys();
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      @ret[i] = GetItem(key);
    }
    return ret;
  }

  const uint[]@ opIndex(uint key) {
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
    log_trace('DictOfUintToArrayOfUint_WDefault_WriteLog dir: ' + logDir + ' | logFile: ' + logFile);
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
        auto kv = _DictOfUintToArrayOfUint_WDefault_WriteLog::_KvPair::ReadFromBuffer(fb);
        _d[K(kv.key)] = kv.val;
      }
      log_trace('\\$a4fDictOfUintToArrayOfUint_WDefault_WriteLog\\$777 loaded \\$a4f' + GetSize() + '\\$777 entries from: \\$a4f' + _logPath + '\\$777 in \\$a4f' + (Time::Now - start) + ' ms\\$777.');
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

  private void WriteOnSet(uint key, const uint[] &in value) {
    _DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair@ p = _DictOfUintToArrayOfUint_WDefault_WriteLog::KvPair(key, value);
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

namespace _DictOfUintToArrayOfUint_WDefault_WriteLog {
  /* Namespace // Mixin: Dict Backing */
  class KvPair {
    /* Properties // Mixin: Default Properties */
    private uint _key;
    private array<uint> _val;

    /* Methods // Mixin: Default Constructor */
    KvPair(uint key, const uint[] &in val) {
      this._key = key;
      this._val = val;
    }

    /* Methods // Mixin: Getters */
    uint get_key() const {
      return this._key;
    }

    const uint[]@ get_val() const {
      return this._val;
    }

    /* Methods // Mixin: ToString */
    const string ToString() {
      return 'KvPair('
        + string::Join({'key=' + '' + key, 'val=' + TS_Array_uint(val)}, ', ')
        + ')';
    }

    private const string TS_Array_uint(const array<uint> &in arr) {
      string ret = '{';
      for (uint i = 0; i < arr.Length; i++) {
        if (i > 0) ret += ', ';
        ret += '' + arr[i];
      }
      return ret + '}';
    }

    /* Methods // Mixin: Op Eq */
    bool opEquals(const KvPair@ &in other) {
      if (other is null) {
        return false; // this obj can never be null.
      }
      bool _tmp_arrEq_val = _val.Length == other.val.Length;
      for (uint i = 0; i < _val.Length; i++) {
        if (!_tmp_arrEq_val) {
          break;
        }
        _tmp_arrEq_val = _tmp_arrEq_val && (_val[i] == other.val[i]);
      }
      return true
        && _key == other.key
        && _tmp_arrEq_val
        ;
    }

    /* Methods // Mixin: Row Serialization */
    const string ToRowString() {
      string ret = "";
      ret += '' + _key + ",";
      ret += TRS_WrapString(TRS_Array_uint(_val)) + ",";
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

    private const string TRS_Array_uint(const array<uint> &in arr) {
      string ret = '';
      for (uint i = 0; i < arr.Length; i++) {
        ret += '' + arr[i] + ',';
      }
      return ret;
    }

    /* Methods // Mixin: ToFromBuffer */
    void WriteToBuffer(Buffer@ &in buf) {
      buf.Write(_key);
      WTB_Array_Uint(buf, _val);
    }

    uint CountBufBytes() {
      uint bytes = 0;
      bytes += 4;
      bytes += CBB_Array_Uint(_val);
      return bytes;
    }

    void WTB_LP_String(Buffer@ &in buf, const string &in s) {
      buf.Write(uint(s.Length));
      buf.Write(s);
    }

    void WTB_Array_Uint(Buffer@ &in buf, const array<uint> &in arr) {
      buf.Write(uint(arr.Length));
      for (uint ix = 0; ix < arr.Length; ix++) {
        auto el = arr[ix];
        buf.Write(el);
      }
    }

    uint CBB_Array_Uint(const array<uint> &in arr) {
      uint bytes = 4;
      for (uint ix = 0; ix < arr.Length; ix++) {
        auto el = arr[ix];
        bytes += 4;
      }
      return bytes;
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
      /* Parse field: val of type: array<uint> */
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
      array<uint> val = FRS_Array_uint(chunk);
      return KvPair(key, val);
    }

    const array<uint>@ FRS_Array_uint(const string &in str) {
      array<uint> ret = array<uint>(0);
      string chunk = '', remainder = str;
      array<string> tmp = array<string>(2);
      uint chunkLen = 0;
      while (remainder.Length > 0) {
        try {
          tmp = remainder.Split(',', 2);
          chunk = tmp[0]; remainder = tmp[1];
        } catch {
          warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
          throw(getExceptionInfo());
        }
        ret.InsertLast(Text::ParseInt(chunk));
      }
      return ret;
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
      /* Parse field: val of type: array<uint> */
      array<uint> val = RFB_Array_Uint(buf);
      return KvPair(key, val);
    }

    const string RFB_LP_String(Buffer@ &in buf) {
      uint len = buf.ReadUInt32();
      return buf.ReadString(len);
    }

    const array<uint>@ RFB_Array_Uint(Buffer@ &in buf) {
      uint len = buf.ReadUInt32();
      array<uint> arr = array<uint>(len);
      for (uint i = 0; i < arr.Length; i++) {
        arr[i] = buf.ReadUInt32();
      }
      return arr;
    }
  }
}
