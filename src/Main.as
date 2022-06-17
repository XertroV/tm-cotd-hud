void Main() {
    // note: not sure if this includes standard or just club -- do we need club?
    while (!NadeoServices::IsAuthenticated("NadeoClubServices")) {
        yield();
    }

    // auto c = Challenge::FromRowString("");

    startnew(PersistentData::Main);

    startnew(DataManager::Main);
    startnew(CotdExplorer::Main);

    startnew(SettingsCustom::LoopSetTabsInactive);

    startnew(ColorGradientWindow_Setup);

#if DEPENDENCY_BETTERCHAT
    startnew(BcCommands::Main);
#endif

#if DEV
    // SetDevSettings();
    // startnew(DebugTest_LoadingScreen);
    // startnew(DebugTest_PrintPgUIConfigs);
#endif

#if UNIT_TEST || DEV
    TestColors();
#endif
}

void Update(float dt) {
    DataManager::Update(dt);
}

void Render() {
    CotdHud::Render();
    CotdExplorer::Render();
    WDebugNod::Render();
    WAllTimes::Render();
}

void RenderInterface() {
    CotdHud::RenderInterface();
    CotdExplorer::RenderInterface();
    RenderWindowUtilityColorGradients();
    WAllTimes::RenderInterface();
}

void RenderMenu() {
    CotdExplorer::RenderMenu();
    CotdHud::RenderMenu();
}

void RenderMainMenu() {
    CotdExplorer::RenderMainMenu();
    CotdHud::RenderMainMenu();
}

// void RenderSettings() {}

void OnSettingsChanged() {
    trace("Main.OnSettingsChanged");
    DataManager::OnSettingsChanged();
    CotdHud::OnSettingsChanged();
    CotdExplorer::OnSettingsChanged();
    OnSettingsChanged_UiGradientWindow();
}

void OnMouseMove(int x, int y) {
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
