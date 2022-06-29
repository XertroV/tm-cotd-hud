class MatchResult {
  /* Properties // Mixin: Default Properties */
  private MaybeOfUint@ _rank;
  private MaybeOfUint@ _score;
  private string _participant;
  private string _zone;

  /* Methods // Mixin: Default Constructor */
  MatchResult(MaybeOfUint@ rank, MaybeOfUint@ score, const string &in participant, const string &in zone) {
    @this._rank = rank;
    @this._score = score;
    this._participant = participant;
    this._zone = zone;
  }

  /* Methods // Mixin: ToFrom JSON Object */
  MatchResult(const Json::Value &in j) {
    try {
      @this._rank = MaybeOfUint(j["rank"]);
      @this._score = MaybeOfUint(j["score"]);
      this._participant = j["participant"];
      this._zone = j["zone"];
    } catch {
      OnFromJsonError(j);
    }
  }

  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["rank"] = _rank.ToJson();
    j["score"] = _score.ToJson();
    j["participant"] = _participant;
    j["zone"] = _zone;
    return j;
  }

  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }

  /* Methods // Mixin: Getters */
  MaybeOfUint@ get_rank() const {
    return this._rank;
  }

  MaybeOfUint@ get_score() const {
    return this._score;
  }

  const string get_participant() const {
    return this._participant;
  }

  const string get_zone() const {
    return this._zone;
  }

  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'MatchResult('
      + string::Join({'rank=' + rank.ToString(), 'score=' + score.ToString(), 'participant=' + participant, 'zone=' + zone}, ', ')
      + ')';
  }

  /* Methods // Mixin: Op Eq */
  bool opEquals(const MatchResult@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _rank == other.rank
      && _score == other.score
      && _participant == other.participant
      && _zone == other.zone
      ;
  }

  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(_rank.ToRowString()) + ",";
    ret += TRS_WrapString(_score.ToRowString()) + ",";
    ret += TRS_WrapString(_participant) + ",";
    ret += TRS_WrapString(_zone) + ",";
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
    _rank.WriteToBuffer(buf);
    _score.WriteToBuffer(buf);
    WTB_LP_String(buf, _participant);
    WTB_LP_String(buf, _zone);
  }

  uint CountBufBytes() {
    uint bytes = 0;
    bytes += _rank.CountBufBytes();
    bytes += _score.CountBufBytes();
    bytes += 4 + _participant.Length;
    bytes += 4 + _zone.Length;
    return bytes;
  }

  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
}

namespace _MatchResult {
  /* Namespace // Mixin: Row Serialization */
  MatchResult@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: rank of type: MaybeOfUint@ */
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
    MaybeOfUint@ rank = _MaybeOfUint::FromRowString(chunk);
    /* Parse field: score of type: MaybeOfUint@ */
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
    MaybeOfUint@ score = _MaybeOfUint::FromRowString(chunk);
    /* Parse field: participant of type: string */
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
    string participant = chunk;
    /* Parse field: zone of type: string */
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
    string zone = chunk;
    return MatchResult(rank, score, participant, zone);
  }

  void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }

  /* Namespace // Mixin: ToFromBuffer */
  MatchResult@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: rank of type: MaybeOfUint@ */
    MaybeOfUint@ rank = _MaybeOfUint::ReadFromBuffer(buf);
    /* Parse field: score of type: MaybeOfUint@ */
    MaybeOfUint@ score = _MaybeOfUint::ReadFromBuffer(buf);
    /* Parse field: participant of type: string */
    string participant = RFB_LP_String(buf);
    /* Parse field: zone of type: string */
    string zone = RFB_LP_String(buf);
    return MatchResult(rank, score, participant, zone);
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}
