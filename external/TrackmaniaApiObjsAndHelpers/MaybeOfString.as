shared class MaybeOfString {
  /* Properties // Mixin: Default Properties */
  private string _val;
  private bool _hasVal;
  
  /* Methods // Mixin: JMaybes */
  MaybeOfString(const string &in val) {
    _hasVal = true;
    _val = val;
  }
  
  MaybeOfString() {
    _hasVal = false;
  }
  
  MaybeOfString(const Json::Value &in j) {
    if (j.GetType() % Json::Type::Null == 0) {
      _hasVal = false;
    } else {
      _hasVal = true;
      _val = string(j);
    }
  }
  
  bool opEquals(const MaybeOfString@ &in other) {
    if (IsJust()) {
      return other.IsJust() && (_val == other.val);
    }
    return other.IsNothing();
  }
  
  const string ToString() {
    string ret = 'MaybeOfString(';
    if (IsJust()) {
      ret += _val;
    }
    return ret + ')';
  }
  
  const string ToRowString() {
    if (!_hasVal) {
      return 'null,';
    }
    return TRS_WrapString(_val) + ',';
  }
  
  private const string TRS_WrapString(const string &in s) {
    string _s = s.Replace('\n', '\\n').Replace('\r', '\\r');
    string ret = '(' + _s.Length + ':' + _s + ')';
    if (ret.Length != (3 + _s.Length + ('' + _s.Length).Length)) {
      throw('bad string length encoding. expected: ' + (3 + _s.Length + ('' + _s.Length).Length) + '; but got ' + ret.Length);
    }
    return ret;
  }
  
  Json::Value ToJson() {
    if (IsNothing()) {
      return Json::Value(); // json null
    }
    return Json::Value(_val);
  }
  
  void WriteToBuffer(Buffer@ &in buf) {
    if (IsNothing()) {
      buf.Write(uint8(0));
    } else {
      buf.Write(uint8(1));
      WTB_LP_String(buf, _val);
    }
  }
  
  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
  
  uint CountBufBytes() {
    if (IsNothing()) {
      return 1;
    }
    return 1 + 4 + _val.Length;
  }
  
  const string get_val() const {
    if (!_hasVal) {
      throw('Attempted to access .val of a Nothing');
    }
    return _val;
  }
  
  const string GetOr(const string &in _default) {
    return _hasVal ? _val : _default;
  }
  
  bool IsJust() const {
    return _hasVal;
  }
  
  bool IsSome() const {
    return IsJust();
  }
  
  bool IsNothing() const {
    return !_hasVal;
  }
  
  bool IsNone() const {
    return IsNothing();
  }
}

namespace _MaybeOfString {
  /* Namespace // Mixin: JMaybes */
  shared MaybeOfString@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    if (remainder.SubStr(0, 4) == 'null') {
      return MaybeOfString();
    }
    /* Parse field: val of type: string */
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
    string val = chunk;
    return MaybeOfString(chunk);
  }
  
  shared void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }
  
  shared MaybeOfString@ ReadFromBuffer(Buffer@ &in buf) {
    bool isNothing = 0 == buf.ReadUInt8();
    if (isNothing) {
      return MaybeOfString();
    } else {
      /* Parse field: val of type: string */
      string val = RFB_LP_String(buf);
      return MaybeOfString(val);
    }
  }
  
  shared const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}