shared class TrackOfTheDayEntry {
  /* Properties // Mixin: Default Properties */
  private uint _campaignId;
  private string _mapUid;
  private uint _day;
  private uint _monthDay;
  private string _seasonUid;
  private uint _startTimestamp;
  private uint _endTimestamp;
  
  /* Methods // Mixin: Default Constructor */
  TrackOfTheDayEntry(uint campaignId, const string &in mapUid, uint day, uint monthDay, const string &in seasonUid, uint startTimestamp, uint endTimestamp) {
    this._campaignId = campaignId;
    this._mapUid = mapUid;
    this._day = day;
    this._monthDay = monthDay;
    this._seasonUid = seasonUid;
    this._startTimestamp = startTimestamp;
    this._endTimestamp = endTimestamp;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  TrackOfTheDayEntry(const Json::Value &in j) {
    try {
      this._campaignId = j["campaignId"];
      this._mapUid = j["mapUid"];
      this._day = j["day"];
      this._monthDay = j["monthDay"];
      this._seasonUid = j["seasonUid"];
      this._startTimestamp = j["startTimestamp"];
      this._endTimestamp = j["endTimestamp"];
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["campaignId"] = _campaignId;
    j["mapUid"] = _mapUid;
    j["day"] = _day;
    j["monthDay"] = _monthDay;
    j["seasonUid"] = _seasonUid;
    j["startTimestamp"] = _startTimestamp;
    j["endTimestamp"] = _endTimestamp;
    return j;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  uint get_campaignId() const {
    return this._campaignId;
  }
  
  const string get_mapUid() const {
    return this._mapUid;
  }
  
  uint get_day() const {
    return this._day;
  }
  
  uint get_monthDay() const {
    return this._monthDay;
  }
  
  const string get_seasonUid() const {
    return this._seasonUid;
  }
  
  uint get_startTimestamp() const {
    return this._startTimestamp;
  }
  
  uint get_endTimestamp() const {
    return this._endTimestamp;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'TrackOfTheDayEntry('
      + string::Join({'campaignId=' + '' + campaignId, 'mapUid=' + mapUid, 'day=' + '' + day, 'monthDay=' + '' + monthDay, 'seasonUid=' + seasonUid, 'startTimestamp=' + '' + startTimestamp, 'endTimestamp=' + '' + endTimestamp}, ', ')
      + ')';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const TrackOfTheDayEntry@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _campaignId == other.campaignId
      && _mapUid == other.mapUid
      && _day == other.day
      && _monthDay == other.monthDay
      && _seasonUid == other.seasonUid
      && _startTimestamp == other.startTimestamp
      && _endTimestamp == other.endTimestamp
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += '' + _campaignId + ",";
    ret += TRS_WrapString(_mapUid) + ",";
    ret += '' + _day + ",";
    ret += '' + _monthDay + ",";
    ret += TRS_WrapString(_seasonUid) + ",";
    ret += '' + _startTimestamp + ",";
    ret += '' + _endTimestamp + ",";
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
    buf.Write(_campaignId);
    WTB_LP_String(buf, _mapUid);
    buf.Write(_day);
    buf.Write(_monthDay);
    WTB_LP_String(buf, _seasonUid);
    buf.Write(_startTimestamp);
    buf.Write(_endTimestamp);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4;
    bytes += 4 + _mapUid.Length;
    bytes += 4;
    bytes += 4;
    bytes += 4 + _seasonUid.Length;
    bytes += 4;
    bytes += 4;
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
}

namespace _TrackOfTheDayEntry {
  /* Namespace // Mixin: Row Serialization */
  shared TrackOfTheDayEntry@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: campaignId of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint campaignId = Text::ParseInt(chunk);
    /* Parse field: mapUid of type: string */
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
    string mapUid = chunk;
    /* Parse field: day of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint day = Text::ParseInt(chunk);
    /* Parse field: monthDay of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint monthDay = Text::ParseInt(chunk);
    /* Parse field: seasonUid of type: string */
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
    string seasonUid = chunk;
    /* Parse field: startTimestamp of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint startTimestamp = Text::ParseInt(chunk);
    /* Parse field: endTimestamp of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint endTimestamp = Text::ParseInt(chunk);
    return TrackOfTheDayEntry(campaignId, mapUid, day, monthDay, seasonUid, startTimestamp, endTimestamp);
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared TrackOfTheDayEntry@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: campaignId of type: uint */
    uint campaignId = buf.ReadUInt32();
    /* Parse field: mapUid of type: string */
    string mapUid = RFB_LP_String(buf);
    /* Parse field: day of type: uint */
    uint day = buf.ReadUInt32();
    /* Parse field: monthDay of type: uint */
    uint monthDay = buf.ReadUInt32();
    /* Parse field: seasonUid of type: string */
    string seasonUid = RFB_LP_String(buf);
    /* Parse field: startTimestamp of type: uint */
    uint startTimestamp = buf.ReadUInt32();
    /* Parse field: endTimestamp of type: uint */
    uint endTimestamp = buf.ReadUInt32();
    return TrackOfTheDayEntry(campaignId, mapUid, day, monthDay, seasonUid, startTimestamp, endTimestamp);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}