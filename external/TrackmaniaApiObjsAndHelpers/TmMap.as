shared class TmMap {
  /* Properties // Mixin: Default Properties */
  private string _Id;
  private string _Uid;
  private string _Name;
  private string _FileName;
  private uint _AuthorScore;
  private uint _GoldScore;
  private uint _SilverScore;
  private uint _BronzeScore;
  private string _AuthorDisplayName;
  private string _AuthorAccountId;
  private string _AuthorWebServicesUserId;
  private string _SubmitterAccountId;
  private string _SubmitterWebServicesUserId;
  private string _Style;
  private uint _TimeStamp;
  private string _Type;
  private string _FileUrl;
  private string _ThumbnailUrl;
  
  /* Methods // Mixin: Default Constructor */
  TmMap(const string &in Id, const string &in Uid, const string &in Name, const string &in FileName, uint AuthorScore, uint GoldScore, uint SilverScore, uint BronzeScore, const string &in AuthorDisplayName, const string &in AuthorAccountId, const string &in AuthorWebServicesUserId, const string &in SubmitterAccountId, const string &in SubmitterWebServicesUserId, const string &in Style, uint TimeStamp, const string &in Type, const string &in FileUrl, const string &in ThumbnailUrl) {
    this._Id = Id;
    this._Uid = Uid;
    this._Name = Name;
    this._FileName = FileName;
    this._AuthorScore = AuthorScore;
    this._GoldScore = GoldScore;
    this._SilverScore = SilverScore;
    this._BronzeScore = BronzeScore;
    this._AuthorDisplayName = AuthorDisplayName;
    this._AuthorAccountId = AuthorAccountId;
    this._AuthorWebServicesUserId = AuthorWebServicesUserId;
    this._SubmitterAccountId = SubmitterAccountId;
    this._SubmitterWebServicesUserId = SubmitterWebServicesUserId;
    this._Style = Style;
    this._TimeStamp = TimeStamp;
    this._Type = Type;
    this._FileUrl = FileUrl;
    this._ThumbnailUrl = ThumbnailUrl;
  }
  
  /* Methods // Mixin: ToFrom JSON Object */
  TmMap(const Json::Value &in j) {
    try {
      this._Id = j["Id"];
      this._Uid = j["Uid"];
      this._Name = j["Name"];
      this._FileName = j["FileName"];
      this._AuthorScore = j["AuthorScore"];
      this._GoldScore = j["GoldScore"];
      this._SilverScore = j["SilverScore"];
      this._BronzeScore = j["BronzeScore"];
      this._AuthorDisplayName = j["AuthorDisplayName"];
      this._AuthorAccountId = j["AuthorAccountId"];
      this._AuthorWebServicesUserId = j["AuthorWebServicesUserId"];
      this._SubmitterAccountId = j["SubmitterAccountId"];
      this._SubmitterWebServicesUserId = j["SubmitterWebServicesUserId"];
      this._Style = j["Style"];
      this._TimeStamp = j["TimeStamp"];
      this._Type = j["Type"];
      this._FileUrl = j["FileUrl"];
      this._ThumbnailUrl = j["ThumbnailUrl"];
    } catch {
      OnFromJsonError(j);
    }
  }
  
  Json::Value ToJson() {
    Json::Value j = Json::Object();
    j["Id"] = _Id;
    j["Uid"] = _Uid;
    j["Name"] = _Name;
    j["FileName"] = _FileName;
    j["AuthorScore"] = _AuthorScore;
    j["GoldScore"] = _GoldScore;
    j["SilverScore"] = _SilverScore;
    j["BronzeScore"] = _BronzeScore;
    j["AuthorDisplayName"] = _AuthorDisplayName;
    j["AuthorAccountId"] = _AuthorAccountId;
    j["AuthorWebServicesUserId"] = _AuthorWebServicesUserId;
    j["SubmitterAccountId"] = _SubmitterAccountId;
    j["SubmitterWebServicesUserId"] = _SubmitterWebServicesUserId;
    j["Style"] = _Style;
    j["TimeStamp"] = _TimeStamp;
    j["Type"] = _Type;
    j["FileUrl"] = _FileUrl;
    j["ThumbnailUrl"] = _ThumbnailUrl;
    return j;
  }
  
  void OnFromJsonError(const Json::Value &in j) const {
    warn('Parsing json failed: ' + Json::Write(j));
    throw('Failed to parse JSON: ' + getExceptionInfo());
  }
  
  /* Methods // Mixin: Getters */
  const string get_Id() const {
    return this._Id;
  }
  
  const string get_Uid() const {
    return this._Uid;
  }
  
  const string get_Name() const {
    return this._Name;
  }
  
  const string get_FileName() const {
    return this._FileName;
  }
  
  uint get_AuthorScore() const {
    return this._AuthorScore;
  }
  
  uint get_GoldScore() const {
    return this._GoldScore;
  }
  
  uint get_SilverScore() const {
    return this._SilverScore;
  }
  
  uint get_BronzeScore() const {
    return this._BronzeScore;
  }
  
  const string get_AuthorDisplayName() const {
    return this._AuthorDisplayName;
  }
  
  const string get_AuthorAccountId() const {
    return this._AuthorAccountId;
  }
  
  const string get_AuthorWebServicesUserId() const {
    return this._AuthorWebServicesUserId;
  }
  
  const string get_SubmitterAccountId() const {
    return this._SubmitterAccountId;
  }
  
  const string get_SubmitterWebServicesUserId() const {
    return this._SubmitterWebServicesUserId;
  }
  
  const string get_Style() const {
    return this._Style;
  }
  
  uint get_TimeStamp() const {
    return this._TimeStamp;
  }
  
  const string get_Type() const {
    return this._Type;
  }
  
  const string get_FileUrl() const {
    return this._FileUrl;
  }
  
  const string get_ThumbnailUrl() const {
    return this._ThumbnailUrl;
  }
  
  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'TmMap('
      + string::Join({'Id=' + Id, 'Uid=' + Uid, 'Name=' + Name, 'FileName=' + FileName, 'AuthorScore=' + '' + AuthorScore, 'GoldScore=' + '' + GoldScore, 'SilverScore=' + '' + SilverScore, 'BronzeScore=' + '' + BronzeScore, 'AuthorDisplayName=' + AuthorDisplayName, 'AuthorAccountId=' + AuthorAccountId, 'AuthorWebServicesUserId=' + AuthorWebServicesUserId, 'SubmitterAccountId=' + SubmitterAccountId, 'SubmitterWebServicesUserId=' + SubmitterWebServicesUserId, 'Style=' + Style, 'TimeStamp=' + '' + TimeStamp, 'Type=' + Type, 'FileUrl=' + FileUrl, 'ThumbnailUrl=' + ThumbnailUrl}, ', ')
      + ')';
  }
  
  /* Methods // Mixin: Op Eq */
  bool opEquals(const TmMap@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _Id == other.Id
      && _Uid == other.Uid
      && _Name == other.Name
      && _FileName == other.FileName
      && _AuthorScore == other.AuthorScore
      && _GoldScore == other.GoldScore
      && _SilverScore == other.SilverScore
      && _BronzeScore == other.BronzeScore
      && _AuthorDisplayName == other.AuthorDisplayName
      && _AuthorAccountId == other.AuthorAccountId
      && _AuthorWebServicesUserId == other.AuthorWebServicesUserId
      && _SubmitterAccountId == other.SubmitterAccountId
      && _SubmitterWebServicesUserId == other.SubmitterWebServicesUserId
      && _Style == other.Style
      && _TimeStamp == other.TimeStamp
      && _Type == other.Type
      && _FileUrl == other.FileUrl
      && _ThumbnailUrl == other.ThumbnailUrl
      ;
  }
  
  /* Methods // Mixin: Row Serialization */
  const string ToRowString() {
    string ret = "";
    ret += TRS_WrapString(_Id) + ",";
    ret += TRS_WrapString(_Uid) + ",";
    ret += TRS_WrapString(_Name) + ",";
    ret += TRS_WrapString(_FileName) + ",";
    ret += '' + _AuthorScore + ",";
    ret += '' + _GoldScore + ",";
    ret += '' + _SilverScore + ",";
    ret += '' + _BronzeScore + ",";
    ret += TRS_WrapString(_AuthorDisplayName) + ",";
    ret += TRS_WrapString(_AuthorAccountId) + ",";
    ret += TRS_WrapString(_AuthorWebServicesUserId) + ",";
    ret += TRS_WrapString(_SubmitterAccountId) + ",";
    ret += TRS_WrapString(_SubmitterWebServicesUserId) + ",";
    ret += TRS_WrapString(_Style) + ",";
    ret += '' + _TimeStamp + ",";
    ret += TRS_WrapString(_Type) + ",";
    ret += TRS_WrapString(_FileUrl) + ",";
    ret += TRS_WrapString(_ThumbnailUrl) + ",";
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
    WTB_LP_String(buf, _Id);
    WTB_LP_String(buf, _Uid);
    WTB_LP_String(buf, _Name);
    WTB_LP_String(buf, _FileName);
    buf.Write(_AuthorScore);
    buf.Write(_GoldScore);
    buf.Write(_SilverScore);
    buf.Write(_BronzeScore);
    WTB_LP_String(buf, _AuthorDisplayName);
    WTB_LP_String(buf, _AuthorAccountId);
    WTB_LP_String(buf, _AuthorWebServicesUserId);
    WTB_LP_String(buf, _SubmitterAccountId);
    WTB_LP_String(buf, _SubmitterWebServicesUserId);
    WTB_LP_String(buf, _Style);
    buf.Write(_TimeStamp);
    WTB_LP_String(buf, _Type);
    WTB_LP_String(buf, _FileUrl);
    WTB_LP_String(buf, _ThumbnailUrl);
  }
  
  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4 + _Id.Length;
    bytes += 4 + _Uid.Length;
    bytes += 4 + _Name.Length;
    bytes += 4 + _FileName.Length;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4;
    bytes += 4 + _AuthorDisplayName.Length;
    bytes += 4 + _AuthorAccountId.Length;
    bytes += 4 + _AuthorWebServicesUserId.Length;
    bytes += 4 + _SubmitterAccountId.Length;
    bytes += 4 + _SubmitterWebServicesUserId.Length;
    bytes += 4 + _Style.Length;
    bytes += 4;
    bytes += 4 + _Type.Length;
    bytes += 4 + _FileUrl.Length;
    bytes += 4 + _ThumbnailUrl.Length;
    return bytes;
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  /* Methods // Mixin: From Game Object: CNadeoServicesMap */
  TmMap(CNadeoServicesMap@ &in gameObj) {
    this._Id = gameObj.Id;
    this._Uid = gameObj.Uid;
    this._Name = gameObj.Name;
    this._FileName = gameObj.FileName;
    this._AuthorScore = gameObj.AuthorScore;
    this._GoldScore = gameObj.GoldScore;
    this._SilverScore = gameObj.SilverScore;
    this._BronzeScore = gameObj.BronzeScore;
    this._AuthorDisplayName = gameObj.AuthorDisplayName;
    this._AuthorAccountId = gameObj.AuthorAccountId;
    this._AuthorWebServicesUserId = gameObj.AuthorWebServicesUserId;
    this._SubmitterAccountId = gameObj.SubmitterAccountId;
    this._SubmitterWebServicesUserId = gameObj.SubmitterWebServicesUserId;
    this._Style = gameObj.Style;
    this._TimeStamp = gameObj.TimeStamp;
    this._Type = gameObj.Type;
    this._FileUrl = gameObj.FileUrl;
    this._ThumbnailUrl = gameObj.ThumbnailUrl;
  }
}

namespace _TmMap {
  /* Namespace // Mixin: Row Serialization */
  shared TmMap@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    /* Parse field: Id of type: string */
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
    string Id = chunk;
    /* Parse field: Uid of type: string */
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
    string Uid = chunk;
    /* Parse field: Name of type: string */
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
    string Name = chunk;
    /* Parse field: FileName of type: string */
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
    string FileName = chunk;
    /* Parse field: AuthorScore of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint AuthorScore = Text::ParseInt(chunk);
    /* Parse field: GoldScore of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint GoldScore = Text::ParseInt(chunk);
    /* Parse field: SilverScore of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint SilverScore = Text::ParseInt(chunk);
    /* Parse field: BronzeScore of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint BronzeScore = Text::ParseInt(chunk);
    /* Parse field: AuthorDisplayName of type: string */
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
    string AuthorDisplayName = chunk;
    /* Parse field: AuthorAccountId of type: string */
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
    string AuthorAccountId = chunk;
    /* Parse field: AuthorWebServicesUserId of type: string */
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
    string AuthorWebServicesUserId = chunk;
    /* Parse field: SubmitterAccountId of type: string */
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
    string SubmitterAccountId = chunk;
    /* Parse field: SubmitterWebServicesUserId of type: string */
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
    string SubmitterWebServicesUserId = chunk;
    /* Parse field: Style of type: string */
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
    string Style = chunk;
    /* Parse field: TimeStamp of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint TimeStamp = Text::ParseInt(chunk);
    /* Parse field: Type of type: string */
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
    string Type = chunk;
    /* Parse field: FileUrl of type: string */
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
    string FileUrl = chunk;
    /* Parse field: ThumbnailUrl of type: string */
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
    string ThumbnailUrl = chunk;
    return TmMap(Id, Uid, Name, FileName, AuthorScore, GoldScore, SilverScore, BronzeScore, AuthorDisplayName, AuthorAccountId, AuthorWebServicesUserId, SubmitterAccountId, SubmitterWebServicesUserId, Style, TimeStamp, Type, FileUrl, ThumbnailUrl);
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  /* Namespace // Mixin: ToFromBuffer */
  shared TmMap@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: Id of type: string */
    string Id = RFB_LP_String(buf);
    /* Parse field: Uid of type: string */
    string Uid = RFB_LP_String(buf);
    /* Parse field: Name of type: string */
    string Name = RFB_LP_String(buf);
    /* Parse field: FileName of type: string */
    string FileName = RFB_LP_String(buf);
    /* Parse field: AuthorScore of type: uint */
    uint AuthorScore = buf.ReadUInt32();
    /* Parse field: GoldScore of type: uint */
    uint GoldScore = buf.ReadUInt32();
    /* Parse field: SilverScore of type: uint */
    uint SilverScore = buf.ReadUInt32();
    /* Parse field: BronzeScore of type: uint */
    uint BronzeScore = buf.ReadUInt32();
    /* Parse field: AuthorDisplayName of type: string */
    string AuthorDisplayName = RFB_LP_String(buf);
    /* Parse field: AuthorAccountId of type: string */
    string AuthorAccountId = RFB_LP_String(buf);
    /* Parse field: AuthorWebServicesUserId of type: string */
    string AuthorWebServicesUserId = RFB_LP_String(buf);
    /* Parse field: SubmitterAccountId of type: string */
    string SubmitterAccountId = RFB_LP_String(buf);
    /* Parse field: SubmitterWebServicesUserId of type: string */
    string SubmitterWebServicesUserId = RFB_LP_String(buf);
    /* Parse field: Style of type: string */
    string Style = RFB_LP_String(buf);
    /* Parse field: TimeStamp of type: uint */
    uint TimeStamp = buf.ReadUInt32();
    /* Parse field: Type of type: string */
    string Type = RFB_LP_String(buf);
    /* Parse field: FileUrl of type: string */
    string FileUrl = RFB_LP_String(buf);
    /* Parse field: ThumbnailUrl of type: string */
    string ThumbnailUrl = RFB_LP_String(buf);
    return TmMap(Id, Uid, Name, FileName, AuthorScore, GoldScore, SilverScore, BronzeScore, AuthorDisplayName, AuthorAccountId, AuthorWebServicesUserId, SubmitterAccountId, SubmitterWebServicesUserId, Style, TimeStamp, Type, FileUrl, ThumbnailUrl);
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}