

void Main() {
    // note: not sure if this includes standard or just club -- do we need club?
    while (!NadeoServices::IsAuthenticated("NadeoClubServices")) {
        yield();
    }

    startnew(PersistentData::Main);

    startnew(DataManager::Main);
    startnew(CotdExplorer::Main);

    startnew(SettingsCustom::LoopSetTabsInactive);

#if DEPENDENCY_BETTERCHAT
    startnew(BcCommands::Main);
#endif

#if DEV
    // TestTmIoGetMapCaching();
    // SetDevSettings();
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
}

void RenderInterface() {
    CotdHud::RenderInterface();
    CotdExplorer::RenderInterface();
}

void RenderMenu() {
    CotdHud::RenderMenu();
    CotdExplorer::RenderMenu();
}

void RenderMainMenu() {
    CotdHud::RenderMainMenu();
    CotdExplorer::RenderMainMenu();
}

// void RenderSettings() {}

void OnSettingsChanged() {
    trace("Main.OnSettingsChanged");
    DataManager::OnSettingsChanged();
    CotdHud::OnSettingsChanged();
    CotdExplorer::OnSettingsChanged();
}

/* Plan:

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
- COTD map -- update when joining new COTD server; init from TMIO

*/

CTrackMania@ GetTmApp() {
    return cast<CTrackMania>(GetApp());
}

/* debug / test stuff */

void TestTmIoGetMapCaching() {
    // TmIoApi@ tmIoApi = TmIoApi("cotd-hud cache testing (by @XertroV)");
    // uint counter = 0;
    // while (true) {
    //     counter++;
    //     trace("Should get _GetTotdMap cached");
    //     auto totd = tmIoApi._GetTotdMap();
    //     auto ix = totd["days"].Length - 1;
    //     print(">> todays cotd data: " + Json::Write(totd["days"][ix]));
    //     sleep(counter * counter * 1000);
    // }
}
