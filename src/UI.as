#if DEV
const string UI_BASE_NAME = "cotdHudDev";
#else
const string UI_BASE_NAME = "cotdHud";
#endif

const string UI_HUD = UI_BASE_NAME + "-hud";
const string UI_EXPLORER = UI_BASE_NAME + "-explorer";


namespace CotdHud {
    GameInfo@ gi = GameInfo();

    void RenderInterface() {
        if (!IsVisible()) {
            return;
        }

        SetNextWindowLocation();
        UI::Begin(UI_HUD, GetWindowFlags());
        RenderHeading();
        RenderGlobalStats();
        RenderDivs();
        UI::End();
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
        UI::Text("Updated: " + Text::Format("%.1f", msAgo / 1000.) + " s ago");
    }

    void RenderDivs() {
        auto divRows = DataManager::divRows;
        auto playerDr = DataManager::playerDivRow;
        if (divRows is null) { return; }
        int cols = Setting_HudShowDeltas ? 3 : 2;
        bool drawnOnePlusDivs = false;
        if (UI::BeginTable(UI_HUD + "-divs", cols, UI::TableFlags::None)) {
            DivRow@ dr;
            for (uint i = 0; i < divRows.Length; i++) {
                @dr = divRows[i];
                if (dr is null || !dr.visible) { continue; }
                drawnOnePlusDivs = true;

                /* should we draw the player row? */

                if (playerDr.div == dr.div)
                    RenderDivRowFromDR(playerDr, true);

                /* draw div row */

                // UI::TableNextRow();
                // UI::TableNextColumn();
                // UI::Text(dr.FmtDiv());
                // UI::TableNextColumn();
                // UI::Text(dr.FmtTime());
                // if (Setting_HudShowDeltas) {
                //     UI::TableNextColumn();
                //     UI::Text("todo");
                // }
                RenderDivRowFromDR(dr);
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
        if (Setting_HudShowDeltas) {
            int diff = int(DataManager::playerDivRow.timeMs) - int(dr.timeMs);
            bool playerAhead = diff < 0;
            hl = playerAhead ? "\\$d81+" : "\\$3ce-";
            UI::TableNextColumn();
            if (diff != 0) {
                UI::Text(hl + Time::Format(Math::Abs(diff)));
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
}
