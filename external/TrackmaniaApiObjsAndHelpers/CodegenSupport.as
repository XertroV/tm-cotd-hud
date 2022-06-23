void WTB_LP_String(Buffer@ &in buf, const string &in s) {
  buf.Write(uint(s.Length));
  buf.Write(s);
}

shared const string RFB_LP_String(Buffer@ &in buf) {
  uint len = buf.ReadUInt32();
  return buf.ReadString(len);
}