void DebugTest_JsonWritePrecision() {
    auto j = Json::Object();
    j['test1'] = 1;
    j['test5'] = 5;
    j['test10'] = 10;
    j['test50'] = 50;
    j['test100'] = 100;
    j['test500'] = 500;
    j['test1000'] = 1000;
    j['test5000'] = 5000;
    j['test10000'] = 10000;
    j['test50000'] = 50000;
    j['test100000'] = 100000;
    j['test500000'] = 500000;
    j['test1000000'] = 1000000;
    j['test5000000'] = 5000000;
    j['test10000000'] = 10000000;
    j['test50000000'] = 50000000;
    print(Json::Write(j));
}

void DebugTest_LoadingScreen() {
    auto gi = GameInfo();
    while (true) {
        debug("IsLoadingScreen: " + gi.IsLoadingScreen());
        sleep(100);
    }
    // result: seems to work
}

void DebugTest_CompareUIConfigs() {
    auto gi = GameInfo();
    while (true) {
        auto uis = gi.GetPlaygroundUIConfigs();
        for (uint i = 0; i < uis.Length; i++) {
            // debug("uis["+i+"].UISequence: " + uis[i].UISequence);
        }
        sleep(100);
    }
}


void DebugTest_MonitorActiveUILayers() {
    bool[] activeUiLayers = array<bool>(300);
    auto gi = GameInfo();
    while(true) {
        // [15] / #20: home screen
        auto mc = gi.GetMenuCustom();
        auto nlayers = mc.UILayers.Length;
        string dbgMsg = "\\$3d8" + "Active UI Layers: ";
        string dbgNewlyVis = "";
        for (uint i = 0; i < activeUiLayers.Length; i++) {
            if (i < nlayers) {
                auto l = gi.GetUILayer(i);
                if (l.IsVisible && !activeUiLayers[i]) {
                    dbgNewlyVis += ", " + i;
                }
                activeUiLayers[i] = l.IsVisible;
                bool pvis = cast<CGameManiaAppTitleLayerScriptHandler>(l.LocalPage.ScriptHandler).PageIsVisible;
                if (l.IsVisible)
                    dbgMsg += "(" + i + ": " + l.IdName + ", " + (pvis?"T":"F") + "), ";
            } else {
                activeUiLayers[i] = false;
            }
        }
        print(dbgMsg);
        if (dbgNewlyVis.Length > 0)
            print("Newly visible! " + dbgNewlyVis);

        sleep(250);
    }
}


void ListPlayerInfos() {
    debug(">> ListPlayerInfos");
    auto gi = GameInfo();
    auto pis = gi.getPlayerInfos();
    for (uint i = 0; i < pis.Length; i++) {
        CTrackManiaPlayerInfo@ pi = cast<CTrackManiaPlayerInfo@>(pis[i]);
        debug("Player Info for: " + pi.Name);
        debug("  pi.WebServicesUserId: " + pi.WebServicesUserId);
    }
    debug(">> Done ListPlayerInfos");
}
