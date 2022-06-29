/* global vars for settingsCustom that enable detecting the active tab */

BoolWP@ sTabHudHistogramActive = BoolWP(false);

/* namespace this so we use the explicit reference in Main.as */
namespace SettingsCustom {
    void LoopSetTabsInactive() {
        while (true) {
            sTabHudHistogramActive.Set(false);
            yield();
        }
    }
}

/*
    #######  ##     ## ####  ######  ##    ##     ######  ######## ######## ######## #### ##    ##  ######    ######
   ##     ## ##     ##  ##  ##    ## ##   ##     ##    ## ##          ##       ##     ##  ###   ## ##    ##  ##    ##
   ##     ## ##     ##  ##  ##       ##  ##      ##       ##          ##       ##     ##  ####  ## ##        ##
   ##     ## ##     ##  ##  ##       #####        ######  ######      ##       ##     ##  ## ## ## ##   ####  ######
   ##  ## ## ##     ##  ##  ##       ##  ##            ## ##          ##       ##     ##  ##  #### ##    ##        ##
   ##    ##  ##     ##  ##  ##    ## ##   ##     ##    ## ##          ##       ##     ##  ##   ### ##    ##  ##    ##
    ##### ##  #######  ####  ######  ##    ##     ######  ########    ##       ##    #### ##    ##  ######    ######

 QUICK SETTINGS

 */

[SettingsTab name="Quick Settings"]
void RenderSettingsQuickSettings() {
    TextHeading("Quick Settings");

    if (UI::Button("Set Large HUD Histogram (21:9)")) {
        Setting_HudHistogramPos = vec2(.77, .75);
        Setting_HudHistogramSize = vec2(.2, .2);
    }
    AddSimpleTooltip("Set's histogram to lower right corner with width and height set to 20%.\nSuitable for ultrawide monitors.");

    VPad();

    if (UI::Button("Set HUD to show lots of rankings")) {
        Setting_HudShowAboveDiv = 3;
        Setting_HudShowBelowDiv = 3;
        Setting_HudShowTopDivCutoffs = 5;
        Setting_HudShowLastDivPop = true;
        Setting_HudShowPlayerDiv = true;
        Setting_HudShowDeltas = true;
        ::OnSettingsChanged();
    }
    AddSimpleTooltip("This sets the HUD to show:\n"
        + "  - Top 5 div cutoffs \n"
        + "  - 3 divs above yours \n"
        + "  - 3 divs below yours \n"
        + "  - Your div and time \n"
        + "  - # of players in last div \n"
        + "  - Deltas for times compared to yours"
        );
}

/*

   ########   ######      ########     ###    ########    ###
   ##     ## ##    ##     ##     ##   ## ##      ##      ## ##
   ##     ## ##           ##     ##  ##   ##     ##     ##   ##
   ########  ##   ####    ##     ## ##     ##    ##    ##     ##
   ##     ## ##    ##     ##     ## #########    ##    #########
   ##     ## ##    ##     ##     ## ##     ##    ##    ##     ##
   ########   ######      ########  ##     ##    ##    ##     ##

BG DATA

*/

[Setting hidden]
bool Setting_SyncAllowBgQualifierTimes = false;

[Setting hidden]
bool Setting_AllowSaveQualiSnapshots = IsDev();

[SettingsTab name="Data & DBs"]
void RenderSettingsDataSync() {
    TextHeading("Data Synchronization");

    UI::BeginDisabled();
    UI::Text("NOT IMPLEMENTED YET // TODO");

    Setting_SyncAllowBgQualifierTimes = UI::Checkbox(
        "Allow Background Download of Qualifier Times for ALL COTDs?",
        Setting_SyncAllowBgQualifierTimes);
    AddSimpleTooltip("This will proactively download all COTD qualifier times in the background.\n"
        + "It will consume about 400 KB per TOTD for ~2021 onwards. (at least 200 MB)\n"
        + "This is required to show a complete list of any given player's qualifying times.");

    UI::EndDisabled();

    TextHeading("Qualifier Replays");

    // 1.5 - 15 MB per COTD
    // allows animated playback
    // must be recorded during COTD
    // folder `live-times-cache`

    Setting_AllowSaveQualiSnapshots = UI::Checkbox(
        "Save Snapshots of Qualifier Rankings?",
        Setting_AllowSaveQualiSnapshots);
    AddSimpleTooltip("This will save the full rankings during qualifiers every 8 seconds.\n"
        + "It will consume about 15 MB per COTD (and 1.5 MB for COTN / COTM).\n\n"
        + "This is required to show animated qualifier histograms and detect when someone\n"
        + "has rejoined a COTD qualifier and gets a worse time than they previously had.\n"
        + "\\$fe9  Note: these features are not implemented yet."
        );

}

/**

 ##     ## ####  ######  ########  #######   ######   ########     ###    ##     ##
 ##     ##  ##  ##    ##    ##    ##     ## ##    ##  ##     ##   ## ##   ###   ###
 ##     ##  ##  ##          ##    ##     ## ##        ##     ##  ##   ##  #### ####
 #########  ##   ######     ##    ##     ## ##   #### ########  ##     ## ## ### ##
 ##     ##  ##        ##    ##    ##     ## ##    ##  ##   ##   ######### ##     ##
 ##     ##  ##  ##    ##    ##    ##     ## ##    ##  ##    ##  ##     ## ##     ##
 ##     ## ####  ######     ##     #######   ######   ##     ## ##     ## ##     ##

HISTOGRAM

*/


// #[Setting category="HUD Histogram" name="Show HUD Histogram?" description="Shows a histogram graphing the distribution of 200 players' times. Typically those will be the 100 players above you and the 99 players below you. This is useful to see if there are any *breakpoints* that are important to pass (where you would substantially improve in ranking). If you are in the top or bottom 100 players, then the top or bottom 200 times are used instead."]
// #bool Setting_HudShowHistogram = true;

// #[Setting category="HUD Histogram" name="How many bars in the histogram?" min="10" max="100" description="aka. 'bins' or 'buckets'. If set to 25 then the times that appear on the histogram will be grouped into 25 bins, thus there will be 25 vertical bars in the histogram."]
// #uint Setting_HudHistogramBuckets = 42;

// #[Setting category="HUD Histogram" name="Position of HUD Histogram?"]
// #vec2 Setting_HudHistogramPos = vec2(.85, .85);

// #[Setting category="HUD Histogram" name="Size of HUD Histogram?"]
// #vec2 Setting_HudHistogramSize = vec2(.1, .1);

[Setting hidden]
vec3 Setting_HudHistColor1 = vec3(0.803089, 0.68726, 0.105425);
[Setting hidden]
vec3 Setting_HudHistColor2 = vec3(0.105395, 0.56897, 0.779923);
[Setting hidden]
vec3 Setting_HudHistColor3 = vec3(0.043, 0.329, 0.027);
[Setting hidden]
vec3 Setting_HudHistColor4 = vec3(0.934363, 0.534925, 0.0793668);
[Setting hidden]
vec3 Setting_HudHistColor5 = vec3(0.903475, 0.193272, 0.0558131);
[Setting hidden]
vec3 Setting_HudHistPlayerColor = vec3(.9, .2, .5);

vec3[] Setting_Meta_HudHistColors = {
    Setting_HudHistColor1,
    Setting_HudHistColor2,
    Setting_HudHistColor3,
    Setting_HudHistColor4,
    Setting_HudHistColor5
};

[SettingsTab name="HUD Histogram"]
void RenderSettingsHudHistogram() {
    sTabHudHistogramActive.Set(true);

    Setting_HudShowHistogram = UI::Checkbox("Show HUD Histogram?", Setting_HudShowHistogram);
    AddSimpleTooltip("Shows a histogram graphing the distribution of 200 players' times.\n"
        + "Typically those will be the 100 players above you and the 99 players below you.\n"
        + "This is useful to see if there are any *breakpoints* that are important to pass (where you would substantially improve in ranking).\n"
        + "If you are in the top or bottom 100 players, then the top or bottom 200 times are used instead.");

    TextHeading("Position and Size");

    Setting_HudHistogramPos.x = UI::SliderFloat("Horizontal Position (%)", Setting_HudHistogramPos.x, 0, 1);
    Setting_HudHistogramPos.y = UI::SliderFloat("Vertical Position (%)", Setting_HudHistogramPos.y, 0, 1);
    VPad();
    Setting_HudHistogramSize.x = UI::SliderFloat("Width (%)", Setting_HudHistogramSize.x, 0, .5);
    Setting_HudHistogramSize.y = UI::SliderFloat("Height (%)", Setting_HudHistogramSize.y, 0, .5);

    TextHeading("Colors");

    Setting_HudHistPlayerColor = UI::InputColor3("Bar with Your Time", Setting_HudHistPlayerColor);
    AddSimpleTooltip("This will highlight the histogram bar that your time is in with this color.");

    /*

    UI::TextWrapped(
        "The histogram spans a maximum of 5 ranks (200 players).\n"
        + "Normally, your rank is the middle one. That isn't the case if you're in the top or bottom 100 players, though."
        );
    VPad();
    Setting_HudHistColor1 = UI::InputColor3("Fastest Rank", Setting_HudHistColor1);
    Setting_HudHistColor2 = UI::InputColor3("Faster Rank", Setting_HudHistColor2);
    Setting_HudHistColor3 = UI::InputColor3("Middle Rank (Yours)", Setting_HudHistColor3);
    Setting_HudHistColor4 = UI::InputColor3("Slower Rank", Setting_HudHistColor4);
    Setting_HudHistColor5 = UI::InputColor3("Slowest Rank", Setting_HudHistColor5);
    if (UI::Button("(Dev) Print Colors to Log")) {
        print(
            "Colors:\n"
            + "Player: " + Vec3ToStr(Setting_HudHistPlayerColor) + "\n"
            + "C1: " + Vec3ToStr(Setting_HudHistColor1) + "\n"
            + "C2: " + Vec3ToStr(Setting_HudHistColor2) + "\n"
            + "C3: " + Vec3ToStr(Setting_HudHistColor3) + "\n"
            + "C4: " + Vec3ToStr(Setting_HudHistColor4) + "\n"
            + "C5: " + Vec3ToStr(Setting_HudHistColor5) + "\n"
        );
    }

    */
}


/*
    ###    ########  ##     ##    ###    ##    ##  ######  ######## ########
   ## ##   ##     ## ##     ##   ## ##   ###   ## ##    ## ##       ##     ##
  ##   ##  ##     ## ##     ##  ##   ##  ####  ## ##       ##       ##     ##
 ##     ## ##     ## ##     ## ##     ## ## ## ## ##       ######   ##     ##
 ######### ##     ##  ##   ##  ######### ##  #### ##       ##       ##     ##
 ##     ## ##     ##   ## ##   ##     ## ##   ### ##    ## ##       ##     ##
 ##     ## ########     ###    ##     ## ##    ##  ######  ######## ########
ADVANCED
*/




// [Setting category="Dev Features" name="Show HUD even if interface is hidden?" description=""]
[Setting category="General" name="Show HUD even if interface is hidden?"]
bool Setting_ShowHudEvenIfInterfaceHidden = true;

[Setting hidden]
bool Setting_AdvCheckPriorCotd = false;

const int s_ReloadClickWait = 15 * 1000;
int s_lastReloadClick = -1 * s_ReloadClickWait;

[SettingsTab name="Advanced"]
void RenderSettingsAdvanced() {
    auto now = Time::get_Now();

    TextHeading("Misc");

    Setting_ShowHudEvenIfInterfaceHidden = UI::Checkbox("Show HUD even if interface is hidden?", Setting_ShowHudEvenIfInterfaceHidden);
    AddSimpleTooltip("This only will ignore whether the interface is hidden or not.\nYou should also enable 'General > Show HUD Always' if you want the HUD to be for-sure visible.");

    /*****/
    TextHeading("Current COTD Data");

    UI::TextWrapped(
        "Reload data from Nadeo API?\n" +
        "\\$E60" + "Please do not abuse this!"
    );
    int _cooldown = s_lastReloadClick + s_ReloadClickWait - now;
    UI::BeginDisabled(_cooldown > 0);
    string b_title = "<< Reload COTD Data " + (_cooldown > 0 ? Text::Format("(%.1f) ", float(_cooldown) / 1000.) : "") + ">>";
    if (UI::Button(b_title)) {
        s_lastReloadClick = now;
        startnew(DataManager::_FullUpdateCotdStatsSeries);
    }
    UI::EndDisabled();

    VPad();

    Setting_AdvCheckPriorCotd = UI::Checkbox("Check Prior COTD?", Setting_AdvCheckPriorCotd);
    AddSimpleTooltip("Check this box to always get data for the previous COTD instead of the current one. (Except when you're actually in COTD.)\nUseful for testing. Make sure to reload COTD data after changing this setting.");

}



/*
    ########  ######## ########  ##     ##  ######
    ##     ## ##       ##     ## ##     ## ##    ##
    ##     ## ##       ##     ## ##     ## ##
    ##     ## ######   ########  ##     ## ##   ####
    ##     ## ##       ##     ## ##     ## ##    ##
    ##     ## ##       ##     ## ##     ## ##    ##
    ########  ######## ########   #######   ######
DEBUG
*/


// #if DEV || UNIT_TEST

[SettingsTab name="Debug"]
void RenderSettingsDebug() {
    TextHeading("Debug Functions");

    if (UI::Button("Run ListPlayerInfos")) {
        ListPlayerInfos();
    }
    AddSimpleTooltip("Prints all players' names and userIds to the Openplanet log.");

    if (UI::Button("Nod Explorer: Network")) {
        @_DebugNod = GI::GetNetwork();
        // _DebugNodWindow.SetTitle("View Nod: Network");
        // _DebugNodWindow.Show();
        ExploreNod("Network", GI::GetNetwork());
    }

    if (UI::Button("Nod Explorer: CurrentPlayground")) {
        ExploreNod("CurrentPlayground", GI::GetCurrentPlayground());
    }

    if (UI::Button("Nod Explorer: InputPort")) {
        ExploreNod("InputPort", GI::GetInputPort());
    }

    // if (UI::Button("Load Replay (TEST)")) {
    //     startnew(TestLoadReplay);
    // }

    if (UI::Button("Test save replay")) {
        startnew(TestSaveReplay);
    }

    VPad();
}

void TestSaveReplay() {
    // auto network = GetTmApp().Network;
    // auto pg = network.PlaygroundClientScriptAPI;
    // pg.SaveReplay('test-' + Time::Stamp);
    // auto pg2 = network.ClientManiaAppPlayground;
    // auto b = MwFastBuffer<wstring>();
    // pg2.SendCustomEvent(wstring("playmap-endracemenu-save-replay"), b);
    // pg2.SendCustomEvent(wstring("playmap-endracemenu-save-replay"), b);
    auto scoreMgr = GI::GetScoreMgr();
    MwFastBuffer<CGamePlayer@> currPlayers = GI::GetCurrentPlayground().Players;
    auto g = scoreMgr.Playground_GetPlayerGhost(GI::GetControlledPlayer().ScriptAPI);
    if (g is null) {
        debug("GetPlayerGhost returned null. :(");
    }
}

// void TestRefreshReplays() {
//     CSmArenaRulesMode@ pgs = cast<CSmArenaRulesMode@>(GetTmApp().PlaygroundScript);
//     auto dfm = pgs.DataFileMgr;
//     dfm.Replay_RefreshFromDisk();
// }

// string[] _TestLoadReplays = {
//     // odarath
//     "test-1654825414",
//     "test-1654825344",
//     "test-1654824065",
//     "test-1654823979",
//     "test-1654823870",
//     "test-1654823287",
//     "My Replays/$s$06fOdarath_XertroV_10-06-2022_12-12-28(00'47''268)",
//     // sketch 01
//     "test-1654822510",
//     "test-1654822504",
//     "test-1654822480",
//     "test-1654822472",
//     "test-1654822418",
//     "test-1654822415"
// };

// string[] _TestLoadReplaysViaMenu = {
//     "My Replays/$s$06fOdarath_XertroV_11_47_49",
//     "My Replays/$s$06fOdarath_XertroV_11_41_52",
//     "My Replays/$s$06fOdarath_XertroV_11_41_51",
//     "My Replays/$s$06fOdarath_XertroV_11_21_01",
//     "My Replays/$s$06fOdarath_XertroV_11_21_00",
//     "My Replays/$s$06fOdarath_XertroV_11_19_32",
//     "My Replays/$s$06fOdarath_XertroV_11_17_41",
//     "My Replays/$s$06fOdarath_XertroV_11_07_59",
//     // "Autosaves/XertroV_$s$06fOdarath_PersonalBest_TimeAttack",
//     "My Replays/$s$06fOdarath_XertroV_10-06-2022_12-12-28(00'47''268)"
// };

// void TestLoadReplay() {
//     print("TestLoadReplay");
//     CSmArenaRulesMode@ pgs = cast<CSmArenaRulesMode@>(GetTmApp().PlaygroundScript);
//     auto dfm = pgs.DataFileMgr;
//     // auto ghostMgr = pgs.GhostMgr;
//     string replayName;
//     for (uint i = 0; i <= 7; i++) {
//         replayName = _TestLoadReplays[i];
//         // replayName = _TestLoadReplaysViaMenu[i];
//         auto res = dfm.Replay_Load(replayName);
//         // auto res = dfm.Replay_Load("Autosaves/XertroV_$o$nSTRETCH $FFcft dom_PersonalBest_TimeAttack");
//         while (res.IsProcessing) yield();
//         if (res.HasSucceeded) {
//             auto ghosts = res.Ghosts;
//             print("Loaded " + replayName + ".Replay with " + ghosts.Length + " ghosts.");
//             for (uint i = 0; i < ghosts.Length; i++) {
//                 auto ghost = ghosts[i];
//                 if (ghost.Result.Time > 0xefffffff) continue;
//                 auto c = pgs.Ghost_Add(ghost, true);
//                 print("added ghost instance: " + Text::Format("%08x", c.Value) + ", " + c.GetName() + ", " + ghost.Nickname + ", " + ghost.Result.Time + ", visible:" + pgs.Ghost_IsVisible(c) + ", over:" + pgs.Ghost_IsReplayOver(c));
//             }
//         } else {
//             warn("replay load failure -- c:" + res.ErrorCode + ", t:" + res.ErrorType + ", d:" + res.ErrorDescription);
//         }
//     }
// }

/*
network.ClientManiaAppPlayground.UILayers[20] (20 in single player, 16 on totd)
SendCustomEvent("playmap-endracemenu-save-replay", [])
*/

CMwNod@ _DebugNod;
WindowState@ _DebugNodWindow = WindowState("View Nod: ----", false);

// #endif

const string mkRainbowName(const string &in name) {
    return rainbowLoopColorCycle(name, true);
}

[SettingsTab name="About"]
void RenderSettingsAbout() {
    TextHeading("About COTD HUD + Explorer");
    UI::Text("By " + mkRainbowName("XertroV"));
    UI::Text("Inspired by COTD Stats by " + mkRainbowName("chipsTM"));
    UI::Text("Thanks to " + mkRainbowName("Miss") + "\\$z for OpenPlanet \\$f39" + Icons::Heartbeat);
    VPad();
    UI::Text(c_orange_600 + "todo");
    VPad();
    ButtonLink(Icons::Github + "\\$z GitHub Repo", "https://github.com/XertroV/tm-cotd-hud");
}
