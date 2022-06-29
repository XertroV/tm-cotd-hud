class CompRound {
  /* Properties // Mixin: Default Properties */
  private uint _id;
  private uint _qualifierChallengeId;
  private uint _position;
  private uint _nbMatches;
  private uint _startDate;
  private uint _endDate;
  private string _name;
  private string _status;
  private string _leaderboardComputeType;
  private MaybeOfString@ _teamLeaderboardComputeType;
  private string _matchScoreDirection;

  /* Methods // Mixin: Default Constructor */
  CompRound(uint id, uint qualifierChallengeId, uint position, uint nbMatches, uint startDate, uint endDate, const string &in name, const string &in status, const string &in leaderboardComputeType, MaybeOfString@ teamLeaderboardComputeType, const string &in matchScoreDirection) {
    this._id = id;
    this._qualifierChallengeId = qualifierChallengeId;
    this._position = position;
    this._nbMatches = nbMatches;
    this._startDate = startDate;
    this._endDate = endDate;
    this._name = name;
    this._status = status;
    this._leaderboardComputeType = leaderboardComputeType;
    @this._teamLeaderboardComputeType = teamLeaderboardComputeType;
    this._matchScoreDirection = matchScoreDirection;
  }

  /* Methods // Mixin: ToFrom JSON Object */
  CompRound(const Json::Value &in j) {
    try {
      this._id = j["id"];
      this._qualifierChallengeId = j["qualifierChallengeId"];
      this._position = j["position"];
      this._nbMatches = j["nbMatches"];
      this._startDate = j["startDate"];
      this._endDate = j["endDate"];
      this._name = j["name"];
      this._status = j["status"];
      this._leaderboardComputeType = j["leaderboardComputeType"];
      @this._teamLeaderboardComputeType = MaybeOfString(j["teamLeaderboardComputeType"]);
      this._matchScoreDirection = j["matchScoreDirection"];
    } catch {
      OnFromJsonError(j);
    }
  }

  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["id"] = _id;
    j["qualifierChallengeId"] = _qualifierChallengeId;
    j["position"] = _position;
    j["nbMatches"] = _nbMatches;
    j["startDate"] = _startDate;
    j["endDate"] = _endDate;
    j["name"] = _name;
    j["status"] = _status;
    j["leaderboardComputeType"] = _leaderboardComputeType;
    j["teamLeaderboardComputeType"] = _teamLeaderboardComputeType.ToJson();
    j["matchScoreDirection"] = _matchScoreDirection;
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

  uint get_qualifierChallengeId() const {
    return this._qualifierChallengeId;
  }

  uint get_position() const {
    return this._position;
  }

  uint get_nbMatches() const {
    return this._nbMatches;
  }

  uint get_startDate() const {
    return this._startDate;
  }

  uint get_endDate() const {
    return this._endDate;
  }

  const string get_name() const {
    return this._name;
  }

  const string get_status() const {
    return this._status;
  }

  const string get_leaderboardComputeType() const {
    return this._leaderboardComputeType;
  }

  MaybeOfString@ get_teamLeaderboardComputeType() const {
    return this._teamLeaderboardComputeType;
  }

  const string get_matchScoreDirection() const {
    return this._matchScoreDirection;
  }

  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'CompRound('
      + string::Join({'id=' + '' + id, 'qualifierChallengeId=' + '' + qualifierChallengeId, 'position=' + '' + position, 'nbMatches=' + '' + nbMatches, 'startDate=' + '' + startDate, 'endDate=' + '' + endDate, 'name=' + name, 'status=' + status, 'leaderboardComputeType=' + leaderboardComputeType, 'teamLeaderboardComputeType=' + teamLeaderboardComputeType.ToString(), 'matchScoreDirection=' + matchScoreDirection}, ', ')
      + ')';
  }

  /* Methods // Mixin: Op Eq */
  bool opEquals(const CompRound@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _id == other.id
      && _qualifierChallengeId == other.qualifierChallengeId
      && _position == other.position
      && _nbMatches == other.nbMatches
      && _startDate == other.startDate
      && _endDate == other.endDate
      && _name == other.name
      && _status == other.status
      && _leaderboardComputeType == other.leaderboardComputeType
      && _teamLeaderboardComputeType == other.teamLeaderboardComputeType
      && _matchScoreDirection == other.matchScoreDirection
      ;
  }

  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += '' + _id + ",";
    ret += '' + _qualifierChallengeId + ",";
    ret += '' + _position + ",";
    ret += '' + _nbMatches + ",";
    ret += '' + _startDate + ",";
    ret += '' + _endDate + ",";
    ret += TRS_WrapString(_name) + ",";
    ret += TRS_WrapString(_status) + ",";
    ret += TRS_WrapString(_leaderboardComputeType) + ",";
    ret += TRS_WrapString(_teamLeaderboardComputeType.ToRowString()) + ",";
    ret += TRS_WrapString(_matchScoreDirection) + ",";
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
    buf.Write(_qualifierChallengeId);
    buf.Write(_position);
    buf.Write(_nbMatches);
    buf.Write(_startDate);
    buf.Write(_endDate);
    WTB_LP_String(buf, _name);
    WTB_LP_String(buf, _status);
    WTB_LP_String(buf, _leaderboardComputeType);
    _teamLeaderboardComputeType.WriteToBuffer(buf);
    WTB_LP_String(buf, _matchScoreDirection);
  }

  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4 + _name.Length;
    bytes += 4 + _status.Length;
    bytes += 4 + _leaderboardComputeType.Length;
    bytes += _teamLeaderboardComputeType.CountBufBytes();
    bytes += 4 + _matchScoreDirection.Length;
    return bytes;
  }

  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
}

namespace _CompRound {
  /* Namespace // Mixin: Row Serialization */
  CompRound@ FromRowString(const string &in str) {
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
    /* Parse field: qualifierChallengeId of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint qualifierChallengeId = Text::ParseInt(chunk);
    /* Parse field: position of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint position = Text::ParseInt(chunk);
    /* Parse field: nbMatches of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint nbMatches = Text::ParseInt(chunk);
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
    /* Parse field: status of type: string */
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
    string status = chunk;
    /* Parse field: leaderboardComputeType of type: string */
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
    string leaderboardComputeType = chunk;
    /* Parse field: teamLeaderboardComputeType of type: MaybeOfString@ */
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
    MaybeOfString@ teamLeaderboardComputeType = _MaybeOfString::FromRowString(chunk);
    /* Parse field: matchScoreDirection of type: string */
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
    string matchScoreDirection = chunk;
    return CompRound(id, qualifierChallengeId, position, nbMatches, startDate, endDate, name, status, leaderboardComputeType, teamLeaderboardComputeType, matchScoreDirection);
  }

  void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }

  /* Namespace // Mixin: ToFromBuffer */
  CompRound@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: id of type: uint */
    uint id = buf.ReadUInt32();
    /* Parse field: qualifierChallengeId of type: uint */
    uint qualifierChallengeId = buf.ReadUInt32();
    /* Parse field: position of type: uint */
    uint position = buf.ReadUInt32();
    /* Parse field: nbMatches of type: uint */
    uint nbMatches = buf.ReadUInt32();
    /* Parse field: startDate of type: uint */
    uint startDate = buf.ReadUInt32();
    /* Parse field: endDate of type: uint */
    uint endDate = buf.ReadUInt32();
    /* Parse field: name of type: string */
    string name = RFB_LP_String(buf);
    /* Parse field: status of type: string */
    string status = RFB_LP_String(buf);
    /* Parse field: leaderboardComputeType of type: string */
    string leaderboardComputeType = RFB_LP_String(buf);
    /* Parse field: teamLeaderboardComputeType of type: MaybeOfString@ */
    MaybeOfString@ teamLeaderboardComputeType = _MaybeOfString::ReadFromBuffer(buf);
    /* Parse field: matchScoreDirection of type: string */
    string matchScoreDirection = RFB_LP_String(buf);
    return CompRound(id, qualifierChallengeId, position, nbMatches, startDate, endDate, name, status, leaderboardComputeType, teamLeaderboardComputeType, matchScoreDirection);
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}
