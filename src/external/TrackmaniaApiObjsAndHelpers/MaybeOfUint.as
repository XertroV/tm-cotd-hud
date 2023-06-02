class MaybeOfUint {
  /* Properties // Mixin: Default Properties */
  private uint _val;
  private bool _hasVal;

  /* Methods // Mixin: JMaybes */
  MaybeOfUint(uint val) {
    _hasVal = true;
    _val = val;
  }

  MaybeOfUint() {
    _hasVal = false;
  }

  MaybeOfUint(const Json::Value &in j) {
    if (j.GetType() % Json::Type::Null == 0) {
      _hasVal = false;
    } else {
      _hasVal = true;
      _val = uint(j);
    }
  }

  bool opEquals(const MaybeOfUint@ &in other) {
    if (IsJust()) {
      return other.IsJust() && (_val == other.val);
    }
    return other.IsNothing();
  }

  const string ToString() {
    string ret = 'MaybeOfUint(';
    if (IsJust()) {
      ret += '' + _val;
    }
    return ret + ')';
  }

  const string ToRowString() {
    if (!_hasVal) {
      return 'null,';
    }
    return '' + _val + ',';
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
      buf.Write(_val);
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
    return 1 + 4;
  }

  uint get_val() const {
    if (!_hasVal) {
      throw('Attempted to access .val of a Nothing');
    }
    return _val;
  }

  uint GetOr(uint _default) {
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

namespace _MaybeOfUint {
  /* Namespace // Mixin: JMaybes */
  MaybeOfUint@ FromRowString(const string &in str) {
    string chunk = '', remainder = str;
    array<string> tmp = array<string>(2);
    uint chunkLen = 0;
    if (remainder.SubStr(0, 4) == 'null') {
      return MaybeOfUint();
    }
    /* Parse field: val of type: uint */
    try {
      tmp = remainder.Split(',', 2);
      chunk = tmp[0]; remainder = tmp[1];
    } catch {
      warn('Error getting chunk/remainder: chunkLen / chunk.Length / remainder =' + string::Join({'' + chunkLen, '' + chunk.Length, remainder}, ' / ') +  '\nException info: ' + getExceptionInfo());
      throw(getExceptionInfo());
    }
    uint val = Text::ParseInt(chunk);
    return MaybeOfUint(Text::ParseInt(chunk));
  }

  void FRS_Assert_String_Eq(const string &in sample, const string &in expected) {
    if (sample != expected) {
      throw('[FRS_Assert_String_Eq] expected sample string to equal: "' + expected + '" but it was "' + sample + '" instead.');
    }
  }

  MaybeOfUint@ ReadFromBuffer(Buffer@ &in buf) {
    bool isNothing = 0 == buf.ReadUInt8();
    if (isNothing) {
      return MaybeOfUint();
    } else {
      /* Parse field: val of type: uint */
      uint val = buf.ReadUInt32();
      return MaybeOfUint(val);
    }
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}
