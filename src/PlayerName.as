namespace PlayerNames {
  dictionary@ _names = dictionary();
  PlayerName@ Get(const string &in id) {
    if (!_names.Exists(id)) {
      @_names[id] = PlayerName(id);
    }
    return cast<PlayerName@>(_names[id]);
  }
}

// todo: refresh player names on download new ones

const uint COOLDOWN_MS = 1250;

class PlayerName {
  /* Properties // Mixin: Default Properties */
  private string _Name;
  private string _Id;
  private bool _IsSpecial = false;
  private bool _unknownName = false;
  JsonDictDb@ playerNameDb;
  private uint copiedCooldownSince = 0;
  private int nonce = Math::Rand(-100000000, 100000000);

  /* Methods // Mixin: Default Constructor */
  PlayerName(const string &in Name, const string &in Id, bool IsSpecial, bool unknown = false) {
    this._Name = Name;
    this._Id = Id;
    this._IsSpecial = IsSpecial;
    _unknownName = unknown;
  }

  PlayerName(const string &in Id) {
    this._Id = Id;
    UpdatePlayerNameDB();
    if (playerNameDb is null || !playerNameDb.Exists(Id)) {
      this._Name = "?? " + Id.SubStr(0, 8);
      this._unknownName = true;
    } else {
      this._Name = playerNameDb.Get(Id);
      this._IsSpecial = IsSpecialPlayerId(Id);
      this._unknownName = Id.Length == 0;
    }
  }

  private void UpdatePlayerNameDB() {
    if (playerNameDb is null && PersistentData::mapDb !is null)
      @playerNameDb = PersistentData::mapDb.playerNameDb;
  }

  private void RefreshName() {
    UpdatePlayerNameDB();
    if (playerNameDb !is null && playerNameDb.Exists(Id)) {
      _Name = playerNameDb.Get(Id);
    }
  }

  private bool inTable;

  DrawUiElems@ get_Draw() {
    return DrawUiElems(_Draw);
  }

  private void _Draw() {
    _DrawInner();
  }

  void _DrawInner(bool drawSpecialFlair = true) {
    if (_unknownName) RefreshName();
    string _name = IsCoolingDown
      ? (maniaColorForCooldown(CooldownDelta, COOLDOWN_MS, true) + Name)
      : (drawSpecialFlair && IsSpecial) ? rainbowLoopColorCycle(Name, true) : Name;
    UI::Text(_name);
    // only draw stuff for known players for hereon out
    if (_unknownName) return;
    bool leftClicked = UI::IsItemClicked();

    if (leftClicked) {
      copiedCooldownSince = Time::Now;
      IO::SetClipboard(Name + ' ' + Id);
      trace('Copied: ' + Name + ' ' + Id);
    }

    if (UI::BeginPopupContextItem(Id+nonce)) {
      if (UI::MenuItem("Favorite", "", IsSpecial)) {
        if (IsSpecial) RemoveSpecialPlayer(Id);
        else AddSpecialPlayer(Id);
        _IsSpecial = !_IsSpecial;
      }
      DrawCopyMenuItems();
      UI::EndPopup();
    }
  }

  void DrawCopyMenuItems() {
    if (UI::MenuItem("Copy Id", Id.SubStr(0, 13) + '...')) {
      IO::SetClipboard(Id);
    }
    if (UI::MenuItem("Copy Name", Name)) {
      IO::SetClipboard(Name);
    }
    if (UI::MenuItem("Copy Name & Id")) {
      IO::SetClipboard(Name + ' ' + Id);
    }
  }

  bool get_IsCoolingDown() {
    return CooldownDelta < int(COOLDOWN_MS);
  }

  int get_CooldownDelta() {
    return int(Time::Now) - int(copiedCooldownSince);
  }

  /* Methods // Mixin: Getters */
  const string get_Name() const {
    return this._Name;
  }

  const string get_Id() const {
    return this._Id;
  }

  bool get_IsSpecial() const {
    return this._IsSpecial;
  }

  /* Methods // Mixin: ToString */
  const string ToString() {
    return 'PlayerName('
      + string::Join({'Name=' + Name, 'Id=' + Id, 'IsSpecial=' + '' + IsSpecial}, ', ')
      + ')';
  }

  /* Methods // Mixin: Op Eq */
  bool opEquals(const PlayerName@ &in other) {
    if (other is null) {
      return false; // this obj can never be null.
    }
    return true
      && _Name == other.Name
      && _Id == other.Id
      && _IsSpecial == other.IsSpecial
      ;
  }

  /* Methods // Mixin: ToFromBuffer */
  void WriteToBuffer(Buffer@ &in buf) {
    WTB_LP_String(buf, _Name);
    WTB_LP_String(buf, _Id);
    buf.Write(uint8(_IsSpecial ? 1 : 0));
  }

  uint CountBufBytes() {
    uint bytes = 0;
    bytes += 4 + _Name.Length;
    bytes += 4 + _Id.Length;
    bytes += 1;
    return bytes;
  }

  void WTB_LP_String(Buffer@ &in buf, const string &in s) {
    buf.Write(uint(s.Length));
    buf.Write(s);
  }
}

namespace _PlayerName {
  /* Namespace // Mixin: ToFromBuffer */
  PlayerName@ ReadFromBuffer(Buffer@ &in buf) {
    /* Parse field: Name of type: string */
    string Name = RFB_LP_String(buf);
    /* Parse field: Id of type: string */
    string Id = RFB_LP_String(buf);
    /* Parse field: IsSpecial of type: bool */
    bool IsSpecial = buf.ReadUInt8() > 0;
    return PlayerName(Name, Id, IsSpecial);
  }

  const string RFB_LP_String(Buffer@ &in buf) {
    uint len = buf.ReadUInt32();
    return buf.ReadString(len);
  }
}
