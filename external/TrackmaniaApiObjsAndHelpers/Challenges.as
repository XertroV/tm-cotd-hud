shared class Challenges {
  /* Properties // Mixin: Default Properties */
  private array<Challenge@> _challenges;
  
  /* Methods // Mixin: Default Constructor */
  Challenges(const Challenge@[] &in challenges) {
    this._challenges = challenges;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  Challenges(const Json::Value &in j) {
    try {
      this._challenges = array<Challenge@>(j.Length);
      for (uint i = 0; i < j.Length; i++) {
        @this._challenges[i] = Challenge(j[i]);
      }
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value _tmp_challenges = Json::Array();
    for (uint i = 0; i < _challenges.Length; i++) {
      auto v = _challenges[i];
      _tmp_challenges.Add(v.ToJson());
    }
    return _tmp_challenges;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  const Challenge@[]@ get_challenges() const {
    return this._challenges;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'Challenges('
      + string::Join({'challenges=' + TS_Array_Challenge(challenges)}, ', ')
      + ')';
  }
  
  private const string TS_Array_Challenge(const array<Challenge@> &in arr) {
    string ret = '{';
    for (uint i = 0; i < arr.Length; i++) {
      if (i > 0) ret += ', ';
      ret += arr[i].ToString();
    }
    return ret + '}';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const Challenges@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    bool _tmp_arrEq_challenges = _challenges.Length == other.challenges.Length;
    for (uint i = 0; i < _challenges.Length; i++) {
      if (!_tmp_arrEq_challenges) {
        break;
      }
      _tmp_arrEq_challenges = _tmp_arrEq_challenges && (_challenges[i] == other.challenges[i]);
    }
    return true
      && _tmp_arrEq_challenges
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(TRS_Array_Challenge(_challenges)) + ",";
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
  
  private const string TRS_Array_Challenge(const array<Challenge@> &in arr) {
    string ret = '';
    for (uint i = 0; i < arr.Length; i++) {
      ret += TRS_WrapString(arr[i].ToRowString()) + ',';
    }
    return ret;
  }
  
  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_Array_Challenge(buf, _challenges);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += CBB_Array_Challenge(_challenges);
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  void WTB_Array_Challenge(Buffer@ &in buf, const array<Challenge@> &in arr) {
    buf.Write(uint(arr.Length));
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      el.WriteToBuffer(buf);
    }
  }
  
  uint CBB_Array_Challenge(const array<Challenge@> &in arr) {
    uint bytes = 4;
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      bytes += el.CountBufBytes();
    }
    return bytes;
  }
  
  /* Methods // Mixin: ArrayProxy */
  Challenge@ opIndex(uint ix) const {
    return _challenges[ix];
  }
  
  uint get_Length() const {
    return _challenges.Length;
  }
  
  bool IsEmpty() const {
    return _challenges.IsEmpty();
  }
  
  void InsertLast(Challenge@ v) {
    _challenges.InsertLast(v);
  }
}

namespace _Challenges {
  /* Namespace // Mixin: Row Serialization */
  shared Challenges@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: challenges of type: array<Challenge@> */
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
    array<Challenge@> challenges = FRS_Array_Challenge(chunk);
    return Challenges(challenges);
  }
  
  shared const array<Challenge@>@ FRS_Array_Challenge(const string &in str) {
    array<Challenge@> ret = array<Challenge@>(0);
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
      ret.InsertLast(_Challenge::FromRowString(chunk));
    }
    return ret;
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared Challenges@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: challenges of type: array<Challenge@> */
    array<Challenge@> challenges = RFB_Array_Challenge(buf);
    return Challenges(challenges);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
  
  shared const array<Challenge@>@ RFB_Array_Challenge(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    array<Challenge@> arr = array<Challenge@>(len);
    for (uint i = 0; i < arr.Length; i++) {
      @arr[i] = _Challenge::ReadFromBuffer(buf);
    }
    return arr;
  }
}