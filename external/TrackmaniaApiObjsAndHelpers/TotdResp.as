class TotdResp {
  /* Properties // Mixin: Default Properties */
  private array<TotdMonth@> _monthList;
  private uint _itemCount;
  private uint _nextRequestTimestamp;

  /* Methods // Mixin: Default Constructor */
  TotdResp(const TotdMonth@[] &in monthList, uint itemCount, uint nextRequestTimestamp) {
    this._monthList = monthList;
    this._itemCount = itemCount;
    this._nextRequestTimestamp = nextRequestTimestamp;
  }

  /* Methods // Mixin: ToFrom JSON Object */
  TotdResp(const Json::Value &in j) {
    try {
      this._monthList = array<TotdMonth@>(j["monthList"].Length);
      for (uint i = 0; i < j["monthList"].Length; i++) {
        @this._monthList[i] = TotdMonth(j["monthList"][i]);
      }
      this._itemCount = j["itemCount"];
      this._nextRequestTimestamp = j["nextRequestTimestamp"];
    } catch {
      OnFromJsonError(j);
    }
  }

  Json::Value ToJson() {
    Json::Value j = Json::Object();
    Json::Value _tmp_monthList = Json::Array();
    for (uint i = 0; i < _monthList.Length; i++) {
      auto v = _monthList[i];
      _tmp_monthList.Add(v.ToJson());
    }
    j["monthList"] = _tmp_monthList;
    j["itemCount"] = _itemCount;
    j["nextRequestTimestamp"] = _nextRequestTimestamp;
    return j;
  }

  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }

  /* Methods // Mixin: Getters */
  const TotdMonth@[]@ get_monthList() const {
    return this._monthList;
  }

  uint get_itemCount() const {
    return this._itemCount;
  }

  uint get_nextRequestTimestamp() const {
    return this._nextRequestTimestamp;
  }

  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'TotdResp('
      + string::Join({'monthList=' + TS_Array_TotdMonth(monthList), 'itemCount=' + '' + itemCount, 'nextRequestTimestamp=' + '' + nextRequestTimestamp}, ', ')
      + ')';
  }

  private const string TS_Array_TotdMonth(const array<TotdMonth@> &in arr) {
    string ret = '{';
    for (uint i = 0; i < arr.Length; i++) {
      if (i > 0) ret += ', ';
      ret += arr[i].ToString();
    }
    return ret + '}';
  }

  /* Methods // Mixin: Op Eq */
  bool opEquals(const TotdResp@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    bool _tmp_arrEq_monthList = _monthList.Length == other.monthList.Length;
    for (uint i = 0; i < _monthList.Length; i++) {
      if (!_tmp_arrEq_monthList) {
        break;
      }
      _tmp_arrEq_monthList = _tmp_arrEq_monthList && (_monthList[i] == other.monthList[i]);
    }
    return true
      && _tmp_arrEq_monthList
      && _itemCount == other.itemCount
      && _nextRequestTimestamp == other.nextRequestTimestamp
      ;
  }

  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(TRS_Array_TotdMonth(_monthList)) + ",";
    ret += '' + _itemCount + ",";
    ret += '' + _nextRequestTimestamp + ",";
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

  private const string TRS_Array_TotdMonth(const array<TotdMonth@> &in arr) {
    string ret = '';
    for (uint i = 0; i < arr.Length; i++) {
      ret += TRS_WrapString(arr[i].ToRowString()) + ',';
    }
    return ret;
  }

  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_Array_TotdMonth(buf, _monthList);
    buf.Write(_itemCount);
    buf.Write(_nextRequestTimestamp);
  }

  uint CountBufBytes() {
    uint bytes = 0;
    bytes += CBB_Array_TotdMonth(_monthList);
    bytes += 4;
    bytes += 4;
    return bytes;
  }

  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }

  void WTB_Array_TotdMonth(Buffer@ &in buf, const array<TotdMonth@> &in arr) {
    buf.Write(uint(arr.Length));
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      el.WriteToBuffer(buf);
    }
  }

  uint CBB_Array_TotdMonth(const array<TotdMonth@> &in arr) {
    uint bytes = 4;
    for (uint ix = 0; ix < arr.Length; ix++) {
      auto el = arr[ix];
      bytes += el.CountBufBytes();
    }
    return bytes;
  }
}

namespace _TotdResp {
  /* Namespace // Mixin: Row Serialization */
  TotdResp@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: monthList of type: array<TotdMonth@> */
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
    array<TotdMonth@> monthList = FRS_Array_TotdMonth(chunk);
    /* Parse field: itemCount of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint itemCount = Text::ParseInt(chunk);
    /* Parse field: nextRequestTimestamp of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint nextRequestTimestamp = Text::ParseInt(chunk);
    return TotdResp(monthList, itemCount, nextRequestTimestamp);
  }

  const array<TotdMonth@>@ FRS_Array_TotdMonth(const string &in str) {
    array<TotdMonth@> ret = array<TotdMonth@>(0);
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
      ret.InsertLast(_TotdMonth::FromRowString(chunk));
    }
    return ret;
  }

  void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }

  /* Namespace // Mixin: ToFromBuffer */
  TotdResp@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: monthList of type: array<TotdMonth@> */
    array<TotdMonth@> monthList = RFB_Array_TotdMonth(buf);
    /* Parse field: itemCount of type: uint */
    uint itemCount = buf.ReadUInt32();
    /* Parse field: nextRequestTimestamp of type: uint */
    uint nextRequestTimestamp = buf.ReadUInt32();
    return TotdResp(monthList, itemCount, nextRequestTimestamp);
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }

  const array<TotdMonth@>@ RFB_Array_TotdMonth(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    array<TotdMonth@> arr = array<TotdMonth@>(len);
    for (uint i = 0; i < arr.Length; i++) {
      @arr[i] = _TotdMonth::ReadFromBuffer(buf);
    }
    return arr;
  }
}
