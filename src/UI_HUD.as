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
        RenderFavorites();
        UI::End();
    }

    void _RenderHistogram() {
        // todo: histogram in quali only option -- might interfer with preview
        // if (Setting_HistogramOnlyInQuali && )
        if (Setting_HudShowHistogram || sTabHudHistogramActive.Either()) {
            uint[] data = {};
            Histogram::Draw(
                Setting_HudHistogramPos, Setting_HudHistogramSize,
                DataManager::cotd_HistogramMinMaxRank,
                DataManager::cotd_HistogramData,
                histBarColor,
                Histogram::TimeXLabelFmt,
                getDivFromScore
                );
        }
    }

    // vec4 _HistogramColors(uint score, float halfBucketWidth) {
    //     auto pdr = DataManager::playerDivRow;
    //     // first check if this is the player's bar
    //     if (Math::Abs(int(pdr.timeMs) - int(score)) < halfBucketWidth) {
    //         return vec3To4(Setting_HudHistPlayerColor, .8);
    //     }
    //     // make sure we actually have times
    //     if (DataManager::cotd_TimesForHistogram.Length == 0
    //         || DataManager::cotd_TimesForHistogram[0] == 0
    //         ) {
    //         return vec4(1, 1, 1, 1);
    //     }

    //     // how many divs?
    //     uint upperDivIx = 0;
    //     for (uint i = 0; i < DataManager::divRows.Length; i++) {
    //         auto dr = DataManager::divRows[i];
    //         upperDivIx = i;
    //         if (dr.timeMs > DataManager::cotd_TimesForHistogram[0]) {
    //             break;
    //         }
    //     }

    //     /* get actual colors now */
    //     for (uint d = 0; d < 5; d++) {
    //         if (upperDivIx + d >= DataManager::divRows.Length) { break; }
    //         if (DataManager::divRows[upperDivIx + d].timeMs > score) {
    //             switch (d) {
    //                 // see python function at top of file to generate colors from hex
    //                 case 0: return vec3To4(Setting_HudHistColor1, .8);
    //                 case 1: return vec3To4(Setting_HudHistColor2, .8);
    //                 case 2: return vec3To4(Setting_HudHistColor3, .8);
    //                 case 3: return vec3To4(Setting_HudHistColor4, .8);
    //                 case 4: return vec3To4(Setting_HudHistColor5, .8);
    //             }
    //         }
    //     }

    //     // shouldn't happen but w/e
    //     return vec4(1, 1, 1, 1);
    // }

    vec4 histBarColor(uint score, float halfBucketWidth) {
        auto pdr = DataManager::playerDivRow;
        // first check if this is the player's bar
        if (Math::Abs(int(pdr.timeMs) - int(score)) < halfBucketWidth) {
            return vec3To4(Setting_HudHistPlayerColor, .99);
        }
        uint div = getDivFromScore(score);
        float h = 15 + (87. * float(div)) % 360.;
        Color@ c = Color(vec3(h, 70, 50), ColorTy::HSL);
        return c.rgba(.8);
    }

    uint getDivFromScore(uint score) {
        uint div = 0;
        for (uint i = 0; i < DataManager::divRows.Length; i++) {
            uint divScore = DataManager::divRows[i].timeMs;
            if (divScore >= score && divScore != MAX_DIV_TIME) {
                div = i + 1;
                break;
            }
        }
        if (div == 0) div = 99;
        return div;
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
            if (p == 0) p = 64;
            string players = "Players";
            if (p == 1) players = "Player \\$920(rip)";
            UI::Text("Last Div: " + "\\$0e4" + p + "\\$z " + players);
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
                if (Setting_HudShowPlayerDiv && !drawnPlayerDiv && playerDr.div > 0) {
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

    bool ShowTimeAsRainbow(DivRow@&in dr, bool isPlayer) {
        bool div1Condition = dr.div == 1 && Setting_HudShowMyTimeAsRainbowInDiv1;
        bool ret = isPlayer && (div1Condition || Setting_HudAlwaysShowRainbowPlayerTime);
        return ret;
    }

    void RenderDivRowFromDR(DivRow@&in dr, bool isPlayer = false) {
        // highlight
        string hl = isPlayer ? "\\$f4b" : "\\$z";
        string time = dr.FmtTime();
        if (ShowTimeAsRainbow(dr, isPlayer)) {
            time = rainbowLoopColorCycle(time, true, 1.3);
        }
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text(hl + dr.FmtDiv());
        UI::TableNextColumn();
        UI::Text(hl + time);
        if (ShouldShowDeltas()) {
            if (!isPlayer) {
                int diff = int(DataManager::playerDivRow.timeMs) - int(dr.timeMs);
                bool playerAhead = diff < 0;
                hl = playerAhead ? c_timeOrange + "+" : c_timeBlue + "-";
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


    void RenderFavorites() {
        if (Setting_HudShowFavoritedPlayersTimes) {
            auto pids = DataManager::favoritesOrder;
            if (pids.Length > 0) {
                VPad();
                UI::Separator();
                VPad();
                if (UI::BeginTable(UI_HUD + "-favs", 4, TableFlagsFixed())) {
                    UI::TableSetupColumn("name");
                    UI::TableSetupColumn("rank", UI::TableColumnFlags::PreferSortAscending);
                    UI::TableSetupColumn("div");
                    UI::TableSetupColumn("time");
                    // UI::TableHeadersRow();
                    for (uint i = 0; i < pids.Length; i++) {
                        auto cols = string(DataManager::favoritesTimes[pids[i]]).Split('|', 2);
                        UI::TableNextColumn();
                        PlayerNames::Get(pids[i])._DrawInner(false);
                        UI::TableNextColumn();
                        UI::Text(cols[1]);
                        UI::TableNextColumn();
                        UI::Text('(' + (((Text::ParseInt(cols[1]) - 1) >> 6) + 1) + ')');
                        UI::TableNextColumn();
                        UI::Text(cols[0]);
                    }
                    UI::EndTable();
                }
            }
        }
    }


    bool IsVisible() {
        bool ret = false
            || (Setting_ShowHudInCotdKO && GI::IsCotdKO())
            || (Setting_ShowHudInCotdQuali && GI::IsCotdQuali())
            || Setting_ShowHudAlways
            ;
        ret = Setting_ShowHud && ret;
        if (Setting_HideWithGameUI && !UI::IsGameUIVisible()) return false;
        return ret;
    }

    int GetWindowFlags() {
        int ret = UI::WindowFlags::NoTitleBar;

        if (Setting_HudWindowLocked || !UI::IsOverlayShown()) {
            ret |= UI::WindowFlags::NoMove;
            // ret |= UI::WindowFlags::NoInputs;
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

    void RenderMenu() {
        if (UI::MenuItem(c_menuIconColor + Icons::Signal + "\\$z COTD HUD", "", Setting_ShowHud)) {
            Setting_ShowHud = !Setting_ShowHud;
        }
    }

    void RenderMainMenu() {}
}
