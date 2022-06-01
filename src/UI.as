#if DEV
const string UI_BASE_NAME = "cotdHudDev";
#else
const string UI_BASE_NAME = "cotdHud";
#endif

const string UI_HUD = UI_BASE_NAME + "-hud";
const string UI_EXPLORER = UI_BASE_NAME + "-explorer";


/** generate colors -- python function

def to_floats(hex: str):
  out = (int(hex[0:2], 16) / 0xff
        ,int(hex[2:4], 16) / 0xff
        , int(hex[4:], 16) / 0xff
        )
  return f"vec4({out[0]:.3f}, {out[1]:.3f}, {out[2]:.3f}, .8)  // #{hex}"


*/


namespace CotdHud {
    GameInfo@ gi = GameInfo();

    void Render() {
        if (Setting_ShowHudEvenIfInterfaceHidden) {
            _RenderAll();
        }
    }

    void RenderInterface() {
        /* we check Setting_ShowHudEvenIfInterfaceHidden here because
        * we don't want to double-render.
        */
        if (!Setting_ShowHudEvenIfInterfaceHidden) {
            _RenderAll();
        }
    }

    void _RenderAll() {
        if (IsVisible()) {
            _RenderHUD();
            _RenderHistogram();
        } else {
            _CheckOtherRenderReasons();
        }
    }

    /* Will result in double-drawing if called outside _RenderAll() */
    void _CheckOtherRenderReasons() {
        if (sTabHudHistogramActive.Either()) {
            _RenderHistogram();
        }
    }

    void _RenderHUD() {
        SetNextWindowLocation();
        UI::Begin(UI_HUD, GetWindowFlags());
        RenderHeading();
        RenderGlobalStats();
        RenderDivs();
        RenderLastDivPop();
        UI::End();
    }

    void _RenderHistogram() {
        if (Setting_HudShowHistogram || sTabHudHistogramActive.Either()) {
            uint[] data = {};
            Histogram::Draw(
                Setting_HudHistogramPos, Setting_HudHistogramSize,
                DataManager::cotd_HistogramMinMaxRank,
                // DataManager::cotd_TimesForHistogram, 30,
                _HistogramColors,
                Histogram::TimeXLabelFmt
                );
        }
    }

    vec4 _HistogramColors(uint score, float halfBucketWidth) {
        auto pdr = DataManager::playerDivRow;
        // first check if this is the player's bar
        if (Math::Abs(int(pdr.timeMs) - int(score)) < halfBucketWidth) {
            return vec3To4(Setting_HudHistPlayerColor, .8);
        }
        // make sure we actually have times
        if (DataManager::cotd_TimesForHistogram.Length == 0
            || DataManager::cotd_TimesForHistogram[0] == 0
            ) {
            return vec4(1, 1, 1, 1);
        }

        // how many divs?
        uint upperDivIx = 0;
        for (uint i = 0; i < DataManager::divRows.Length; i++) {
            auto dr = DataManager::divRows[i];
            upperDivIx = i;
            if (dr.timeMs > DataManager::cotd_TimesForHistogram[0]) {
                break;
            }
        }

        /* get actual colors now */
        for (uint d = 0; d < 5; d++) {
            if (upperDivIx + d >= DataManager::divRows.Length) { break; }
            if (DataManager::divRows[upperDivIx + d].timeMs > score) {
                switch (d) {
                    // see python function at top of file to generate colors from hex
                    case 0: return vec3To4(Setting_HudHistColor1, .8);
                    case 1: return vec3To4(Setting_HudHistColor2, .8);
                    case 2: return vec3To4(Setting_HudHistColor3, .8);
                    case 3: return vec3To4(Setting_HudHistColor4, .8);
                    case 4: return vec3To4(Setting_HudHistColor5, .8);
                }
            }
        }

        // shouldn't happen but w/e
        return vec4(1, 1, 1, 1);
    }

    /* UI:: calls to draw heading
     *
     * > COTD <date> #X
     */
    void RenderHeading() {
        // UI::Text("COTD " + DataManager::GetChallengeDateAndNumber());
        UI::Text("\\$fb3" + DataManager::GetChallengeTitle());
    }

    /* UI:: calls to draw global stats
     *
     * > 1234 Players | 23 Divs
     * > Updated: X.Xs ago
     */
    void RenderGlobalStats() {
        auto nPlayers = DataManager::GetCotdTotalPlayers();
        auto nDivs = nPlayers / 64.0f;
        UI::Text("\\$0e4" + nPlayers + " \\$zPlayers | \\$4df" + Text::Format("%.1f", nDivs) + " \\$zDivs");
        auto msAgo = Time::get_Now() - DataManager::divs_lastUpdated;
        UI::Text("\\$888Updated: " + Text::Format("%.1f", msAgo / 1000.) + " s ago");
    }

    void RenderLastDivPop() {
        if (Setting_HudShowLastDivPop) {
            auto p = DataManager::GetCotdTotalPlayers() % 64;
            UI::Text("Last Div: " + "\\$0e4" + p + "\\$z Players");
        }
    }

    bool ShouldShowDeltas() {
        return Setting_HudShowDeltas && DataManager::playerDivRow.timeMs < MAX_DIV_TIME;
    }

    void RenderDivs() {
        auto divRows = DataManager::divRows;
        auto playerDr = DataManager::playerDivRow;
        if (divRows is null) { return; }
        int cols = ShouldShowDeltas() ? 3 : 2;
        bool drawnOnePlusDivs = false;
        bool drawnPlayerDiv = false;
        if (UI::BeginTable(UI_HUD + "-divs", cols, UI::TableFlags::None)) {
            DivRow@ dr;
            for (uint i = 0; i < divRows.Length; i++) {
                @dr = divRows[i];
                if (dr is null || !dr.visible) { continue; }
                drawnOnePlusDivs = true;

                /* should we draw the player row? */
                if (Setting_HudShowPlayerDiv && !drawnPlayerDiv) {
                    if (playerDr.div <= dr.div) {
                        RenderDivRowFromDR(playerDr, true);
                        drawnPlayerDiv = true;
                    }
                }

                /* draw div row */
                RenderDivRowFromDR(dr);
            }
            if (Setting_HudShowPlayerDiv && !drawnPlayerDiv && playerDr.div > 0) {
                RenderDivRowFromDR(playerDr, true);
                drawnPlayerDiv = drawnOnePlusDivs = true;
            }
            if (!drawnOnePlusDivs) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text('--- no data ---');
            }
            UI::EndTable();
        }
    }

    void RenderDivRowFromDR(DivRow@&in dr, bool isPlayer = false) {
        // highlight
        string hl = isPlayer ? "\\$f4b" : "\\$z";
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text(hl + dr.FmtDiv());
        UI::TableNextColumn();
        UI::Text(hl + dr.FmtTime());
        if (ShouldShowDeltas()) {
            if (!isPlayer) {
                int diff = int(DataManager::playerDivRow.timeMs) - int(dr.timeMs);
                bool playerAhead = diff < 0;
                hl = playerAhead ? "\\$d81+" : "\\$3ce-";
                UI::TableNextColumn();
                if (diff != 0) {
                    UI::Text(hl + Time::Format(Math::Abs(diff)));
                }
            } else {
                UI::TableNextColumn();
                auto r = DataManager::GetCotdPlayerRank();
                string sfx;
                switch (r % 10) {
                    case 1: sfx = "st"; break;
                    case 2: sfx = "nd"; break;
                    case 3: sfx = "rd"; break;
                    default: sfx = "th";
                }
                UI::Text("\\$3ec(" + DataManager::GetCotdPlayerRank() + sfx + ")");
            }
        }
    }


    bool IsVisible() {
        // todo
        return false
            || (Setting_ShowHudInCotdKO && gi.IsCotdKO())
            || (Setting_ShowHudInCotdQuali && gi.IsCotdQuali())
            || Setting_ShowHudAlways
            ;
    }

    int GetWindowFlags() {
        int ret = UI::WindowFlags::NoTitleBar;

        if (Setting_HudWindowLocked || !UI::IsOverlayShown()) {
            ret |= UI::WindowFlags::NoMove;
            ret |= UI::WindowFlags::NoInputs;
        }

        ret |= UI::WindowFlags::NoCollapse;
        ret |= UI::WindowFlags::AlwaysAutoResize;

        return ret;
    }

    void SetNextWindowLocation() {
        // UI::SetNextWindowPos(100, 100, UI::Always);
    }

    void OnSettingsChanged() {

    }

    void RenderMenu() {}

    void RenderMainMenu() {}
}



namespace CotdExplorer {
    bool windowActive = false;
    string icon = Icons::AreaChart;
    HistoryDb@ histDb;  /* instantiated in PersistentData */

    dictionary@ cotdYMDMapTree;

    void Main() {
        while (histDb is null) {
            @histDb = PersistentData::histDb;
            yield();
        }
        startnew(ExplorerManager::ManageHistoricalTotdData);
    }

    /* window controls */

    bool IsVisible() {
        return windowActive;
    }

    void ShowWindow() {
        windowActive = true;
        startnew(OnWindowShow);
    }

    void HideWindow() {
        windowActive = false;
        DataManager::cotd_OverrideChallengeId.AsNothing();
    }

    void ToggleWindow() {
        if (IsVisible()) { HideWindow(); }
        else { ShowWindow(); }
    }

    /* Rendering Top-Level */

    void Render() {
        if (Setting_ShowHudEvenIfInterfaceHidden) {
            _RenderAll();
        }
    }

    void RenderInterface() {
        /* we check Setting_ShowHudEvenIfInterfaceHidden here because
        * we don't want to double-render.
        */
        if (!Setting_ShowHudEvenIfInterfaceHidden) {
            _RenderAll();
        }
    }

    void _RenderAll() {
        if (IsVisible()) {
            _RenderExplorerWindow();
        } else {
            _CheckOtherRenderReasons();
        }
    }

    void _CheckOtherRenderReasons() {}

    void RenderMenu() {
        if (UI::MenuItem(c_brightBlue + icon + "\\$z COTD Explorer", "", IsVisible())) {
            ToggleWindow();
        }
    }

    void RenderMainMenu() {}

    /* Events */

    void OnSettingsChanged() {}

    void OnWindowShow() {
        // DataManager::cotd_OverrideChallengeId.AsJust(DataManager::_GetChallengeId());
    }

    /* explorer window */

    void _RenderExplorerWindow() {
        UI::Begin(UI_EXPLORER, GetWindowFlags());

        if (UI::IsWindowAppearing()) {
            @cotdYMDMapTree = histDb.GetCotdYearMonthDayMapTree();
        }

        _RenderExplorerMainTree();

        UI::End();
    }

    int GetWindowFlags() {
        return UI::WindowFlags::None;
    }



    void _RenderExplorerMainTree() {
        array<int>@ keys;
        // auto yrs = cast<int[]@>(cotdYMDMapTree['__keys']);
        auto yrs = cotdYMDMapTree.GetKeys();
        string mapId;
        yrs.SortDesc();
        for (uint i = 0; i < yrs.Length; i++) {
            string yr = "" + yrs[i];
            // if (yr == "__keys") { continue; }
            if (UI::TreeNode(yr)) {
                auto dMonths = cast<dictionary@>(cotdYMDMapTree[yr]);
                // auto months = cast<int[]@>(dMonths['__keys']);
                auto months = dMonths.GetKeys();
                months.SortDesc();
                for (uint j = 0; j < months.Length; j++) {
                    string month = "" + months[j];
                    // if (month == "__keys") { continue; }
                    if (UI::TreeNode(month)) {
                        auto dDays = cast<dictionary@>(dMonths[month]);
                        // auto days = cast<int[]@>(dDays['__keys']);
                        auto days = dDays.GetKeys();
                        days.SortDesc();
                        for (uint k = 0; k < days.Length; k++) {
                            string day = "" + days[k];
                            // if (day == "__keys") { continue; }
                            if (UI::TreeNode(day)) {
                                auto map = cast<JsonBox@>(dDays[day]);
                                mapId = map.j['mapUid'];
                                UI::Text("COTD " + yr + "-" + month + "-" + day);
                                UI::Text("Map ID: " + mapId);
                                UI::TreePop();
                            }
                        }
                        UI::TreePop();
                    }
                }
                UI::TreePop();
            }
        }
    }



    void TestDrawCotdYMDTreeToUI() {
        auto yrs = cotdYMDMapTree.GetKeys();
        for (uint i = 0; i < yrs.Length; i++) {
            auto yr = yrs[i];
            UI::Text(yr);
            auto dMonths = cast<dictionary@>(cotdYMDMapTree[yr]);
            auto months = dMonths.GetKeys();
            for (uint j = 0; j < months.Length; j++) {
                auto month = months[j];
                UI::Text("  " + month);
                auto dDays = cast<dictionary@>(dMonths[month]);
                auto days = dDays.GetKeys();
                string dayLine = "    ";
                for (uint k = 0; k < days.Length; k++) {
                    string day = days[k];
                    dayLine += day + ",";
                    // UI::Text("    " + day);
                    auto map = cast<JsonBox@>(dDays[day]);
                }
                UI::Text(dayLine);
            }
        }
    }
}
