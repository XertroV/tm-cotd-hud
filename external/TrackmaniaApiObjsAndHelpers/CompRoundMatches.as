shared class CompRoundMatches {
  /* Properties // Mixin: Default Properties */
  private array<CompRoundMatch@> _matches;
  
  /* Methods // Mixin: Default Constructor */
  CompRoundMatches(const CompRoundMatch@[] &in matches) {
    this._matches = matches;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  CompRoundMatches(const Json::Value &in j) {
    try {
      this._matches = array<CompRoundMatch@>(j.Length);
      for (uint i = 0; i < j.Length; i++) {
        @this._matches[i] = CompRoundMatch(j[i]);
      }
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value _tmp_matches = Json::Array();
    for (uint i = 0; i < _matches.Length; i++) {
      auto v = _matches[i];
      _tmp_matches.Add(v.ToJson());
    }
    return _tmp_matches;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  const CompRoundMatch@[]@ get_matches() const {
    return this._matches;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'CompRoundMatches('
      + string::Join({'matches=' + TS_Array_CompRoundMatch(matches)}, ', ')
      + ')';
  }
  
  private const string TS_Array_CompRoundMatch(const array<CompRoundMatch@> &in arr) {
    string ret = '{';
    for (uint i = 0; i < arr.Length; i++) {
      if (i > 0) ret += ', ';
      ret += arr[i].ToString();
    }
    return ret + '}';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const CompRoundMatches@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    bool _tmp_arrEq_matches = _matches.Length == other.matches.Length;
    for (uint i = 0; i < _matches.Length; i++) {
      if (!_tmp_arrEq_matches) {
        break;
      }
      _tmp_arrEq_matches = _tmp_arrEq_matches && (_matches[i] == other.matches[i]);
    }
    return true
      && _tmp_arrEq_matches
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(TRS_Array_CompRoundMatch(_matches)) + ",";
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
  
  private const string TRS_Array_CompRoundMatch(const array<CompRoundMatch@> &in arr) {
    string ret = '';
    for (uint i = 0; i < arr.Length; i++) {
      ret += TRS_WrapString(arr[i].ToRowString()) + ',';
    }
    return ret;
  }
  
  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_Array_CompRoundMatch(buf, _matches);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += CBB_Array_CompRoundMatch(_matches);
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  void WTB_Array_CompRoundMatch(Buffer@ &in buf, const array<CompRoundMatch@> &in arr) {
    buf.Write(uint(arr.Length));
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      el.WriteToBuffer(buf);
    }
  }
  
  uint CBB_Array_CompRoundMatch(const array<CompRoundMatch@> &in arr) {
    uint bytes = 4;
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      bytes += el.CountBufBytes();
    }
    return bytes;
  }
  
  /* Methods // Mixin: ArrayProxy */
  CompRoundMatch@ opIndex(uint ix) const {
    return _matches[ix];
  }
  
  uint get_Length() const {
    return _matches.Length;
  }
  
  bool IsEmpty() const {
    return _matches.IsEmpty();
  }
  
  void InsertLast(CompRoundMatch@ v) {
    _matches.InsertLast(v);
  }
}

namespace _CompRoundMatches {
  /* Namespace // Mixin: Row Serialization */
  shared CompRoundMatches@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: matches of type: array<CompRoundMatch@> */
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
    array<CompRoundMatch@> matches = FRS_Array_CompRoundMatch(chunk);
    return CompRoundMatches(matches);
  }
  
  shared const array<CompRoundMatch@>@ FRS_Array_CompRoundMatch(const string &in str) {
    array<CompRoundMatch@> ret = array<CompRoundMatch@>(0);
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    while (remainder.Length > 0) {
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
      ret.InsertLast(_CompRoundMatch::FromRowString(chunk));
    }
    return ret;
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared CompRoundMatches@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: matches of type: array<CompRoundMatch@> */
    array<CompRoundMatch@> matches = RFB_Array_CompRoundMatch(buf);
    return CompRoundMatches(matches);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
  
  shared const array<CompRoundMatch@>@ RFB_Array_CompRoundMatch(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    array<CompRoundMatch@> arr = array<CompRoundMatch@>(len);
    for (uint i = 0; i < arr.Length; i++) {
      @arr[i] = _CompRoundMatch::ReadFromBuffer(buf);
    }
    return arr;
  }
}