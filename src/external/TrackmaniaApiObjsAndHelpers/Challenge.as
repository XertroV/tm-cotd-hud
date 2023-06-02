class Challenge {
  /* Properties // Mixin: Default Properties */
  private uint _id;
  private string _uid;
  private string _name;
  private uint _startDate;
  private uint _endDate;
  private uint _leaderboardId;

  /* Methods // Mixin: Default Constructor */
  Challenge(uint id, const string &in uid, const string &in name, uint startDate, uint endDate, uint leaderboardId) {
    this._id = id;
    this._uid = uid;
    this._name = name;
    this._startDate = startDate;
    this._endDate = endDate;
    this._leaderboardId = leaderboardId;
  }

  /* Methods // Mixin: ToFrom JSON Object */
  Challenge(const Json::Value &in j) {
    try {
      this._id = j["id"];
      this._uid = j["uid"];
      this._name = j["name"];
      this._startDate = j["startDate"];
      this._endDate = j["endDate"];
      this._leaderboardId = j["leaderboardId"];
    } catch {
      OnFromJsonError(j);
    }
  }

  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["id"] = _id;
    j["uid"] = _uid;
    j["name"] = _name;
    j["startDate"] = _startDate;
    j["endDate"] = _endDate;
    j["leaderboardId"] = _leaderboardId;
    return j;
  }

  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }

  /* Methods // Mixin: Getters */
  uint get_id() const {
    return this._id;
  }

  const string get_uid() const {
    return this._uid;
  }

  const string get_name() const {
    return this._name;
  }

  uint get_startDate() const {
    return this._startDate;
  }

  uint get_endDate() const {
    return this._endDate;
  }

  uint get_leaderboardId() const {
    return this._leaderboardId;
  }

  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'Challenge('
      + string::Join({'id=' + '' + id, 'uid=' + uid, 'name=' + name, 'startDate=' + '' + startDate, 'endDate=' + '' + endDate, 'leaderboardId=' + '' + leaderboardId}, ', ')
      + ')';
  }

  /* Methods // Mixin: Op Eq */
  bool opEquals(const Challenge@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _id == other.id
      && _uid == other.uid
      && _name == other.name
      && _startDate == other.startDate
      && _endDate == other.endDate
      && _leaderboardId == other.leaderboardId
      ;
  }

  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += '' + _id + ",";
    ret += TRS_WrapString(_uid) + ",";
    ret += TRS_WrapString(_name) + ",";
    ret += '' + _startDate + ",";
    ret += '' + _endDate + ",";
    ret += '' + _leaderboardId + ",";
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
    buf.Write(_id);
    WTB_LP_String(buf, _uid);
    WTB_LP_String(buf, _name);
    buf.Write(_startDate);
    buf.Write(_endDate);
    buf.Write(_leaderboardId);
  }

  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4;
    bytes += 4 + _uid.Length;
    bytes += 4 + _name.Length;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    return bytes;
  }

  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
}

namespace _Challenge {
  /* Namespace // Mixin: Row Serialization */
  Challenge@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: id of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint id = Text::ParseInt(chunk);
    /* Parse field: uid of type: string */
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
    string uid = chunk;
    /* Parse field: name of type: string */
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
    string name = chunk;
    /* Parse field: startDate of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint startDate = Text::ParseInt(chunk);
    /* Parse field: endDate of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint endDate = Text::ParseInt(chunk);
    /* Parse field: leaderboardId of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint leaderboardId = Text::ParseInt(chunk);
    return Challenge(id, uid, name, startDate, endDate, leaderboardId);
  }

  void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }

  /* Namespace // Mixin: ToFromBuffer */
  Challenge@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: id of type: uint */
    uint id = buf.ReadUInt32();
    /* Parse field: uid of type: string */
    string uid = RFB_LP_String(buf);
    /* Parse field: name of type: string */
    string name = RFB_LP_String(buf);
    /* Parse field: startDate of type: uint */
    uint startDate = buf.ReadUInt32();
    /* Parse field: endDate of type: uint */
    uint endDate = buf.ReadUInt32();
    /* Parse field: leaderboardId of type: uint */
    uint leaderboardId = buf.ReadUInt32();
    return Challenge(id, uid, name, startDate, endDate, leaderboardId);
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}
