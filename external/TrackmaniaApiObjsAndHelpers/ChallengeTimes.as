shared class ChallengeTimes {
  /* Properties // Mixin: Default Properties */
  private array<ChallengeTime@> _times;
  
  /* Methods // Mixin: Default Constructor */
  ChallengeTimes(const ChallengeTime@[] &in times) {
    this._times = times;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  ChallengeTimes(const Json::Value &in j) {
    try {
      this._times = array<ChallengeTime@>(j.Length);
      for (uint i = 0; i < j.Length; i++) {
        @this._times[i] = ChallengeTime(j[i]);
      }
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value _tmp_times = Json::Array();
    for (uint i = 0; i < _times.Length; i++) {
      auto v = _times[i];
      _tmp_times.Add(v.ToJson());
    }
    return _tmp_times;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  const ChallengeTime@[]@ get_times() const {
    return this._times;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'ChallengeTimes('
      + string::Join({'times=' + TS_Array_ChallengeTime(times)}, ', ')
      + ')';
  }
  
  private const string TS_Array_ChallengeTime(const array<ChallengeTime@> &in arr) {
    string ret = '{';
    for (uint i = 0; i < arr.Length; i++) {
      if (i > 0) ret += ', ';
      ret += arr[i].ToString();
    }
    return ret + '}';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const ChallengeTimes@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    bool _tmp_arrEq_times = _times.Length == other.times.Length;
    for (uint i = 0; i < _times.Length; i++) {
      if (!_tmp_arrEq_times) {
        break;
      }
      _tmp_arrEq_times = _tmp_arrEq_times && (_times[i] == other.times[i]);
    }
    return true
      && _tmp_arrEq_times
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(TRS_Array_ChallengeTime(_times)) + ",";
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
  
  private const string TRS_Array_ChallengeTime(const array<ChallengeTime@> &in arr) {
    string ret = '';
    for (uint i = 0; i < arr.Length; i++) {
      ret += TRS_WrapString(arr[i].ToRowString()) + ',';
    }
    return ret;
  }
  
  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_Array_ChallengeTime(buf, _times);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += CBB_Array_ChallengeTime(_times);
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  void WTB_Array_ChallengeTime(Buffer@ &in buf, const array<ChallengeTime@> &in arr) {
    buf.Write(uint(arr.Length));
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      el.WriteToBuffer(buf);
    }
  }
  
  uint CBB_Array_ChallengeTime(const array<ChallengeTime@> &in arr) {
    uint bytes = 4;
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      bytes += el.CountBufBytes();
    }
    return bytes;
  }
  
  /* Methods // Mixin: ArrayProxy */
  ChallengeTime@ opIndex(uint ix) const {
    return _times[ix];
  }
  
  uint get_Length() const {
    return _times.Length;
  }
  
  bool IsEmpty() const {
    return _times.IsEmpty();
  }
  
  void InsertLast(ChallengeTime@ v) {
    _times.InsertLast(v);
  }
}

namespace _ChallengeTimes {
  /* Namespace // Mixin: Row Serialization */
  shared ChallengeTimes@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: times of type: array<ChallengeTime@> */
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
    array<ChallengeTime@> times = FRS_Array_ChallengeTime(chunk);
    return ChallengeTimes(times);
  }
  
  shared const array<ChallengeTime@>@ FRS_Array_ChallengeTime(const string &in str) {
    array<ChallengeTime@> ret = array<ChallengeTime@>(0);
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
      ret.InsertLast(_ChallengeTime::FromRowString(chunk));
    }
    return ret;
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared ChallengeTimes@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: times of type: array<ChallengeTime@> */
    array<ChallengeTime@> times = RFB_Array_ChallengeTime(buf);
    return ChallengeTimes(times);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
  
  shared const array<ChallengeTime@>@ RFB_Array_ChallengeTime(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    array<ChallengeTime@> arr = array<ChallengeTime@>(len);
    for (uint i = 0; i < arr.Length; i++) {
      @arr[i] = _ChallengeTime::ReadFromBuffer(buf);
    }
    return arr;
  }
}