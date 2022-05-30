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
        if (IsVisible() && Setting_ShowHudEvenIfInterfaceHidden) {
            _RenderAll();
        }
    }

    void RenderInterface() {
        if (!IsVisible() || Setting_ShowHudEvenIfInterfaceHidden) {
            /* we check Setting_ShowHudEvenIfInterfaceHidden here because
            * we don't want to double-render.
            */
            return;
        }
        _RenderAll();
    }

    void _RenderAll() {
        _RenderHUD();
        _RenderHistogram();
    }

    void _RenderHUD() {
        SetNextWindowLocation();
        UI::Begin(UI_HUD, GetWindowFlags());
        RenderHeading();
        RenderGlobalStats();
        RenderDivs();
        UI::End();
    }

    void _RenderHistogram() {
        if (Setting_HudShowHistogram) {
            uint[] data = {};
            Histogram::Draw(
                Setting_HudHistogramPos, Setting_HudHistogramSize,
                DataManager::cotd_TimesForHistogram, 30,
                _HistogramColors
                );
        }
    }

    vec4 _HistogramColors(uint score, float halfBucketWidth) {
        auto pdr = DataManager::playerDivRow;
        // first check if this is the player's bar
        if (Math::Abs(int(pdr.timeMs) - int(score)) < halfBucketWidth) {
            return vec4(.9, .2, .5, 1);
        }
        // make sure we actually have times
        if (DataManager::cotd_TimesForHistogram.Length == 0
            || DataManager::cotd_TimesForHistogram[0] == 0
            ) {
            return vec4(1, 1, 1, 1);
        }

        // how many divs?
        uint upperDivIx = 0;
        auto drs = DataManager::divRows;
        auto dmTimes = DataManager::cotd_TimesForHistogram;
        for (uint i = 0; i < drs.Length; i++) {
            auto dr = drs[i];
            upperDivIx = i;
            if (dr.timeMs > dmTimes[0]) {
                break;
            }
        }

        /* get actual colors now */
        for (uint d = 0; d < 5; d++) {
            if (upperDivIx + d >= drs.Length) { break; }
            if (drs[upperDivIx + d].timeMs > score) {
                switch (d) {
                    // see python function at top of file to generate colors from hex
                    case 0: return vec4(0.196, 0.733, 0.701, .8);  // #32BBB5
                    case 1: return vec4(0.141, 0.635, 0.780, .8);  // #24a2c7
                    case 2: return vec4(0.925, 0.745, 0.878, .8);  // #ECBEE0
                    case 3: return vec4(0.933, 0.686, 0.102, .8);  // #EEAF1A
                    case 4: return vec4(0.851, 0.447, 0.125, .8);  // #D97220
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

    bool ShouldShowDeltas() {
        return Setting_HudShowDeltas && DataManager::playerDivRow.timeMs < MAX_DIV_TIME;
    }

    void RenderDivs() {
        auto divRows = DataManager::divRows;
        auto playerDr = DataManager::playerDivRow;
        if (divRows is null) { return; }
        int cols = ShouldShowDeltas() ? 3 : 2;
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
        if (ShouldShowDeltas()) {
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
