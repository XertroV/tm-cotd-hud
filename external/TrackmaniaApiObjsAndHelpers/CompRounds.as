shared class CompRounds {
  /* Properties // Mixin: Default Properties */
  private array<CompRound@> _rounds;
  
  /* Methods // Mixin: Default Constructor */
  CompRounds(const CompRound@[] &in rounds) {
    this._rounds = rounds;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  CompRounds(const Json::Value &in j) {
    try {
      this._rounds = array<CompRound@>(j.Length);
      for (uint i = 0; i < j.Length; i++) {
        @this._rounds[i] = CompRound(j[i]);
      }
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value _tmp_rounds = Json::Array();
    for (uint i = 0; i < _rounds.Length; i++) {
      auto v = _rounds[i];
      _tmp_rounds.Add(v.ToJson());
    }
    return _tmp_rounds;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  const CompRound@[]@ get_rounds() const {
    return this._rounds;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'CompRounds('
      + string::Join({'rounds=' + TS_Array_CompRound(rounds)}, ', ')
      + ')';
  }
  
  private const string TS_Array_CompRound(const array<CompRound@> &in arr) {
    string ret = '{';
    for (uint i = 0; i < arr.Length; i++) {
      if (i > 0) ret += ', ';
      ret += arr[i].ToString();
    }
    return ret + '}';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const CompRounds@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    bool _tmp_arrEq_rounds = _rounds.Length == other.rounds.Length;
    for (uint i = 0; i < _rounds.Length; i++) {
      if (!_tmp_arrEq_rounds) {
        break;
      }
      _tmp_arrEq_rounds = _tmp_arrEq_rounds && (_rounds[i] == other.rounds[i]);
    }
    return true
      && _tmp_arrEq_rounds
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(TRS_Array_CompRound(_rounds)) + ",";
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
  
  private const string TRS_Array_CompRound(const array<CompRound@> &in arr) {
    string ret = '';
    for (uint i = 0; i < arr.Length; i++) {
      ret += TRS_WrapString(arr[i].ToRowString()) + ',';
    }
    return ret;
  }
  
  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_Array_CompRound(buf, _rounds);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += CBB_Array_CompRound(_rounds);
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  void WTB_Array_CompRound(Buffer@ &in buf, const array<CompRound@> &in arr) {
    buf.Write(uint(arr.Length));
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      el.WriteToBuffer(buf);
    }
  }
  
  uint CBB_Array_CompRound(const array<CompRound@> &in arr) {
    uint bytes = 4;
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      bytes += el.CountBufBytes();
    }
    return bytes;
  }
  
  /* Methods // Mixin: ArrayProxy */
  CompRound@ opIndex(uint ix) const {
    return _rounds[ix];
  }
  
  uint get_Length() const {
    return _rounds.Length;
  }
  
  bool IsEmpty() const {
    return _rounds.IsEmpty();
  }
  
  void InsertLast(CompRound@ v) {
    _rounds.InsertLast(v);
  }
}

namespace _CompRounds {
  /* Namespace // Mixin: Row Serialization */
  shared CompRounds@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: rounds of type: array<CompRound@> */
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
    array<CompRound@> rounds = FRS_Array_CompRound(chunk);
    return CompRounds(rounds);
  }
  
  shared const array<CompRound@>@ FRS_Array_CompRound(const string &in str) {
    array<CompRound@> ret = array<CompRound@>(0);
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
      ret.InsertLast(_CompRound::FromRowString(chunk));
    }
    return ret;
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared CompRounds@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: rounds of type: array<CompRound@> */
    array<CompRound@> rounds = RFB_Array_CompRound(buf);
    return CompRounds(rounds);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
  
  shared const array<CompRound@>@ RFB_Array_CompRound(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    array<CompRound@> arr = array<CompRound@>(len);
    for (uint i = 0; i < arr.Length; i++) {
      @arr[i] = _CompRound::ReadFromBuffer(buf);
    }
    return arr;
  }
}