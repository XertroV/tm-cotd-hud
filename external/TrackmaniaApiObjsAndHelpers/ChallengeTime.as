shared class ChallengeTime {
  /* Properties // Mixin: Default Properties */
  private uint _rank;
  private uint _time;
  private uint _score;
  private string _player;
  
  /* Methods // Mixin: Default Constructor */
  ChallengeTime(uint rank, uint time, uint score, const string &in player) {
    this._rank = rank;
    this._time = time;
    this._score = score;
    this._player = player;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  ChallengeTime(const Json::Value &in j) {
    try {
      this._rank = j["rank"];
      this._time = j["time"];
      this._score = j["score"];
      this._player = j["player"];
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["rank"] = _rank;
    j["time"] = _time;
    j["score"] = _score;
    j["player"] = _player;
    return j;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  uint get_rank() const {
    return this._rank;
  }
  
  uint get_time() const {
    return this._time;
  }
  
  uint get_score() const {
    return this._score;
  }
  
  const string get_player() const {
    return this._player;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'ChallengeTime('
      + string::Join({'rank=' + '' + rank, 'time=' + '' + time, 'score=' + '' + score, 'player=' + player}, ', ')
      + ')';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const ChallengeTime@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _rank == other.rank
      && _time == other.time
      && _score == other.score
      && _player == other.player
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += '' + _rank + ",";
    ret += '' + _time + ",";
    ret += '' + _score + ",";
    ret += TRS_WrapString(_player) + ",";
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
    buf.Write(_rank);
    buf.Write(_time);
    buf.Write(_score);
    WTB_LP_String(buf, _player);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4 + _player.Length;
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
}

namespace _ChallengeTime {
  /* Namespace // Mixin: Row Serialization */
  shared ChallengeTime@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: rank of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint rank = Text::ParseInt(chunk);
    /* Parse field: time of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint time = Text::ParseInt(chunk);
    /* Parse field: score of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint score = Text::ParseInt(chunk);
    /* Parse field: player of type: string */
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
    string player = chunk;
    return ChallengeTime(rank, time, score, player);
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared ChallengeTime@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: rank of type: uint */
    uint rank = buf.ReadUInt32();
    /* Parse field: time of type: uint */
    uint time = buf.ReadUInt32();
    /* Parse field: score of type: uint */
    uint score = buf.ReadUInt32();
    /* Parse field: player of type: string */
    string player = RFB_LP_String(buf);
    return ChallengeTime(rank, time, score, player);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}