shared class DictOfString {
  /* Properties // Mixin: Default Properties */
  private dictionary@ _d;
  
  /* Properties // Mixin: Dict Backing */
  
  /* Methods // Mixin: Dict Backing */
  DictOfString() {
    @_d = dictionary();
  }
  
  private const string K(const string &in key) const {
    return key;
  }
  
  const string Get(const string &in key) const {
    return string(_d[K(key)]);
  }
  
  const string[]@ GetMany(const string[] &in keys) const {
    array<string> ret = {};
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      ret.InsertLast(Get(key));
    }
    return ret;
  }
  
  
  void Set(const string &in key, const string &in value) {
    _d[K(key)] = value;
  }
  
  bool Exists(const string &in key) {
    return _d.Exists(K(key));
  }
  
  uint CountExists(const string[] &in keys) {
    uint ret = 0;
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      if (Exists(key)) ret++;
    }
    return ret;
  }
  
  array<string>@ GetKeys() const {
    return _d.GetKeys();
  }
  
  _DictOfString::KvPair@ GetItem(const string &in key) const {
    return _DictOfString::KvPair(key, Get(key));
  }
  
  array<_DictOfString::KvPair@>@ GetItems() const {
    array<_DictOfString::KvPair@> ret = array<_DictOfString::KvPair@>(GetSize());
    array<string> keys = GetKeys();
    for (uint i = 0; i < keys.Length; i++) {
      auto key = keys[i];
      @ret[i] = GetItem(key);
    }
    return ret;
  }
  
  const string opIndex(const string &in key) {
    return Get(key);
  }
  
  uint GetSize() const {
    return _d.GetSize();
  }
  
  bool Delete(const string &in key) {
    return _d.Delete(K(key));
  }
  
  void DeleteAll() {
    _d.DeleteAll();
  }
}

namespace _DictOfString {
  /* Namespace // Mixin: Dict Backing */
  shared class KvPair {
    /* Properties // Mixin: Default Properties */
    private string _key;
    private string _val;
    
    /* Methods // Mixin: Default Constructor */
    KvPair(const string &in key, const string &in val) {
      this._key = key;
      this._val = val;
    }
    
    /* Methods // Mixin: Getters */
    const string get_key() const {
      return this._key;
    }
    
    const string get_val() const {
      return this._val;
    }
    
    /* Methods // Mixin: ToString */
    const string ToString() {
      return 'KvPair('
        + string::Join({'key=' + key, 'val=' + val}, ', ')
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
      ret += TRS_WrapString(_key) + ",";
      ret += TRS_WrapString(_val) + ",";
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
      WTB_LP_String(buf, _key);
      WTB_LP_String(buf, _val);
    }
    
    uint CountBufBytes() {
      uint bytes = 0;
      bytes += 4 + _key.Length;
      bytes += 4 + _val.Length;
      return bytes;
    }
    
    void WTB_LP_String(Buffer@ &in buf, const string &in s) {
      buf.Write(uint(s.Length));
      buf.Write(s);
    }
  }
  
  namespace _KvPair {
    /* Namespace // Mixin: Row Serialization */
    shared KvPair@ FromRowString(const string &in str) {
      string chunk = '', remainder = str;
      array<string> tmp = array<string>(2);
      uint chunkLen = 0;
      /* Parse field: key of type: string */
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
      string key = chunk;
      /* Parse field: val of type: string */
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
      string val = chunk;
      return KvPair(key, val);
    }
    
    shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
      if (sample != expected) {
        throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
      }
    }
    
    /* Namespace // Mixin: ToFromBuffer */
    shared KvPair@ ReadFromBuffer(Buffer@ &in buf) {
      /* Parse field: key of type: string */
      string key = RFB_LP_String(buf);
      /* Parse field: val of type: string */
      string val = RFB_LP_String(buf);
      return KvPair(key, val);
    }
    
    shared const string RFB_LP_String(Buffer@ &in buf) {
      uint len = buf.ReadUInt32();
      return buf.ReadString(len);
    }
  }
}