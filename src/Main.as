void AwaitEula() {
    while (!Setting_EulaAgreement) yield();
}

bool EulaAccepted() {
    return Setting_EulaAgreement;
}

bool UserHasCorrectPermissions() {
    bool ret = true
        && Permissions::PlayOnlineCompetition() // cotd
        && Permissions::PlayRecords() // possible future feature
        && Permissions::ViewRecords() // TOTD records are downloaded
        && Permissions::PlayPastOfficialMonthlyCampaign() // Past TOTDs can be played
        && Permissions::PlayCurrentOfficialMonthlyCampaign() // Current TOTDs can be played
        && Permissions::PlayAgainstReplay() // possible future feature
        && Permissions::PlayLocalMap() // we possibly load arbitrary URLs
        ;
    logcall("UserHasCorrectPermissions", ret ? 'true' : 'false');
    return ret;
}

void NotifyInsufficientPermissions() {
    string msg1 = "COTD HUD: Insufficient Permissions";
    string msg2 = "COTD HUD requires Club access. All features are disabled if your account lacks any of the necessary permissions.";
    UI::ShowNotification(msg1, msg2, vec4(.9, .4, .2, .9), 15 * 1000);
    warn(msg1 + "! " + msg2);
}

void Main() {
    if (!UserHasCorrectPermissions()) {
        NotifyInsufficientPermissions();
        log_warn("Exiting early due to insufficient permissions.");
        return;
    }

#if DEV
    UI::ShowNotification("Now testing NotifyInsufficientPermissions:", 15 * 1000);
    NotifyInsufficientPermissions();
#endif

    startnew(InitSpecialPlayers);

#if DEV
    // SetDevSettings();
    // startnew(DebugTest_LoadingScreen);
    // startnew(DebugTest_PrintPgUIConfigs);
    startnew(DevMain);
#endif

#if UNIT_TEST || DEV
    TestColors();
#endif

    log_trace("Main: Awaiting EULA");
    AwaitEula();
    log_trace("Main: AwaitEula complete.");

    // note: not sure if this includes standard or just club -- do we need club?
    NadeoServices::AddAudience("NadeoClubServices");
    while (!NadeoServices::IsAuthenticated("NadeoClubServices")) {
        yield();
    }
    log_trace("Main: awaited NadeoServices::IsAuthenticated('NadeoClubServices')");

    // auto c = Challenge::FromRowString("");

    startnew(PersistentData::Main);

    startnew(DataManager::Main);
    startnew(CotdExplorer::Main);

    startnew(SettingsCustom::LoopSetTabsInactive);

    startnew(ColorGradientWindow_Setup);

#if DEPENDENCY_BETTERCHAT
    startnew(BcCommands::Main);
#endif
}

void Update(float dt) {
    if (!EulaAccepted()) return;
    DataManager::Update(dt);
}

void Render() {
    WEULA::Render();
    if (!EulaAccepted()) return;
    CotdHud::Render();
    CotdExplorer::Render();
    WDebugNod::Render();
    WAllTimes::Render();
    WAllDivResults::Render();
}

void RenderInterface() {
    if (!EulaAccepted()) return;
    CotdHud::RenderInterface();
    CotdExplorer::RenderInterface();
    RenderWindowUtilityColorGradients();
    WAllTimes::RenderInterface();
    WAllDivResults::RenderInterface();
}

void RenderMenu() {
    if (!EulaAccepted()) return;
    CotdExplorer::RenderMenu();
    CotdHud::RenderMenu();
}

void RenderMainMenu() {
    if (!EulaAccepted()) return;
    CotdExplorer::RenderMainMenu();
    CotdHud::RenderMainMenu();
}

// void RenderSettings() {}

void OnSettingsChanged() {
    if (!EulaAccepted()) return;
    log_trace("Main.OnSettingsChanged");
    DataManager::OnSettingsChanged();
    CotdHud::OnSettingsChanged();
    CotdExplorer::OnSettingsChanged();
    OnSettingsChanged_UiGradientWindow();
}

void OnMouseMove(int x, int y) {
    if (!EulaAccepted()) return;
    CotdExplorer::OnMouseMove(x, y);
}

/* Plan:

*Note: Outdated by a lot, but it's indicative.*

UI Components:
- (Use same backend data)
- Div Summary During COTD (like COTDStats)
  - 'friends list' times (favorites via better-chat)
- COTD Explorer

Data Mgmt:
- Namespaced
- Call update with coroutine
- Macro update parameters stored in global vars
- (WRT per-route coros, figure out refs to pass args, or use hacky tmp global vars workaround)
  - like: set var, call global coro, yeild, that coro sets var to null, back to main loop, go again

Watchers:
- change of IsCotd -- joined COTD server
- COTD map -- update when joining new COTD server

*/

CTrackMania@ GetTmApp() {
    return cast<CTrackMania>(GetApp());
}

#if DEV
// for doing one off things like logging api results
void DevMain() {
    // auto api = CotdApi();
    // auto r = api.GetCompetitions(3, 2);
    // print("GetCompetitions: " + Json::Write(r));
    // auto rounds = api.GetCompRounds(2927, 2);
    // print("GetCompRounds: " + Json::Write(rounds));
    // auto matches = api.GetCompRoundMatches(7317, 2);
    // print("GetCompRoundMatches: " + Json::Write(matches));

    // TestStringLen();
    // MemBufTest();
    // BufTest();
}

void TestStringLen() {
    const string s = "World|Europe|Poland|Śląskie";
    print("String s: " + s);
    print("s.Length: " + s.Length);
    print("s.SubStr(0, s.Length): " + s.SubStr(0, s.Length));
    print("s.SubStr(0, s.Length).Length: " + s.SubStr(0, s.Length).Length);
}

void MemBufTest() {
    MemoryBuffer buf = MemoryBuffer(0);
    print('buf size: ' + buf.GetSize());
    buf.Write(uint(1337));
    print('buf size: ' + buf.GetSize());
    buf.Seek(0, 0);
    print('buf size: ' + buf.GetSize());
    uint gotBack = buf.ReadUInt32();
    print('buf size: ' + buf.GetSize());
    print("wanted 1337, got: " + gotBack);
    print('buf.AtEnd();' + buf.AtEnd());
    buf.Write("123456789 123456789 123456789 123456789 123456789 ");
    buf.Seek(4, 0);
    print('buf.AtEnd();' + buf.AtEnd());
    print('expect buffer size to have increased by 50');
    print('buf size: ' + buf.GetSize());
    print('read str: ' + buf.ReadString(50));
    print('buf.AtEnd();' + buf.AtEnd());
}

void BufTest() {
    Buffer@ buf = Buffer();
    BufTest1(buf);
    buf.Seek(0, 0);
    print('buf size: ' + buf.GetSize());
    BufTest2(buf);
    print('expect buffer size to have increased by 50');
    print('buf size: ' + buf.GetSize());
}

void BufTest1 (Buffer@ &in buf) {
    print('buf size: ' + buf.GetSize());
    buf.Write(uint(0));
    print('buf size: ' + buf.GetSize());
}

void BufTest2 (Buffer@ &in buf) {
    uint gotBack = buf.ReadUInt32();
    print('buf size: ' + buf.GetSize());
    print("wanted 0, got: " + gotBack);
    buf.Write("123456789 123456789 123456789 123456789 123456789 ");
}
#endif
