class Competitions {
  /* Properties // Mixin: Default Properties */
  private array<Competition@> _comps;

  /* Methods // Mixin: Default Constructor */
  Competitions(const Competition@[] &in comps) {
    this._comps = comps;
  }

  /* Methods // Mixin: ToFrom JSON Object */
  Competitions(const Json::Value &in j) {
    try {
      this._comps = array<Competition@>(j.Length);
      for (uint i = 0; i < j.Length; i++) {
        @this._comps[i] = Competition(j[i]);
      }
    } catch {
      OnFromJsonError(j);
    }
  }

  Json::Value ToJson() {
    Json::Value _tmp_comps = Json::Array();
    for (uint i = 0; i < _comps.Length; i++) {
      auto v = _comps[i];
      _tmp_comps.Add(v.ToJson());
    }
    return _tmp_comps;
  }

  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }

  /* Methods // Mixin: Getters */
  const Competition@[]@ get_comps() const {
    return this._comps;
  }

  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'Competitions('
      + string::Join({'comps=' + TS_Array_Competition(comps)}, ', ')
      + ')';
  }

  private const string TS_Array_Competition(const array<Competition@> &in arr) {
    string ret = '{';
    for (uint i = 0; i < arr.Length; i++) {
      if (i > 0) ret += ', ';
      ret += arr[i].ToString();
    }
    return ret + '}';
  }

  /* Methods // Mixin: Op Eq */
  bool opEquals(const Competitions@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    bool _tmp_arrEq_comps = _comps.Length == other.comps.Length;
    for (uint i = 0; i < _comps.Length; i++) {
      if (!_tmp_arrEq_comps) {
        break;
      }
      _tmp_arrEq_comps = _tmp_arrEq_comps && (_comps[i] == other.comps[i]);
    }
    return true
      && _tmp_arrEq_comps
      ;
  }

  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(TRS_Array_Competition(_comps)) + ",";
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

  private const string TRS_Array_Competition(const array<Competition@> &in arr) {
    string ret = '';
    for (uint i = 0; i < arr.Length; i++) {
      ret += TRS_WrapString(arr[i].ToRowString()) + ',';
    }
    return ret;
  }

  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_Array_Competition(buf, _comps);
  }

  uint CountBufBytes() {
    uint bytes = 0;
    bytes += CBB_Array_Competition(_comps);
    return bytes;
  }

  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }

  void WTB_Array_Competition(Buffer@ &in buf, const array<Competition@> &in arr) {
    buf.Write(uint(arr.Length));
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      el.WriteToBuffer(buf);
    }
  }

  uint CBB_Array_Competition(const array<Competition@> &in arr) {
    uint bytes = 4;
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      bytes += el.CountBufBytes();
    }
    return bytes;
  }

  /* Methods // Mixin: ArrayProxy */
  Competition@ opIndex(uint ix) const {
    return _comps[ix];
  }

  uint get_Length() const {
    return _comps.Length;
  }

  bool IsEmpty() const {
    return _comps.IsEmpty();
  }

  void InsertLast(Competition@ v) {
    _comps.InsertLast(v);
  }
}

namespace _Competitions {
  /* Namespace // Mixin: Row Serialization */
  Competitions@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: comps of type: array<Competition@> */
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
    array<Competition@> comps = FRS_Array_Competition(chunk);
    return Competitions(comps);
  }

  const array<Competition@>@ FRS_Array_Competition(const string &in str) {
    array<Competition@> ret = array<Competition@>(0);
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
      ret.InsertLast(_Competition::FromRowString(chunk));
    }
    return ret;
  }

  void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }

  /* Namespace // Mixin: ToFromBuffer */
  Competitions@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: comps of type: array<Competition@> */
    array<Competition@> comps = RFB_Array_Competition(buf);
    return Competitions(comps);
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }

  const array<Competition@>@ RFB_Array_Competition(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    array<Competition@> arr = array<Competition@>(len);
    for (uint i = 0; i < arr.Length; i++) {
      @arr[i] = _Competition::ReadFromBuffer(buf);
    }
    return arr;
  }
}
