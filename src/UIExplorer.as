
namespace CotdExplorer {
    bool windowActive = true;
    string icon = Icons::AreaChart;
    HistoryDb@ histDb;  /* instantiated in PersistentData */
    MapDb@ mapDb;  /* instantiated in PersistentData */

    dictionary@ cotdYMDMapTree;

    bool WaitNullRefs() {
        /* these should be set in Main */
        return histDb is null || mapDb is null;
    }

    void Main() {
        while (WaitNullRefs()) {
            @histDb = PersistentData::histDb;
            @mapDb = PersistentData::mapDb;
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
        UI::Begin(UI_EXPLORER, windowActive);

        if (UI::IsWindowAppearing()) {
            _ResetExplorerCotdSelection();
            _DevSetExplorerCotdSelection();
            startnew(LoadCotdTreeFromDb);
        }

        if (cotdYMDMapTree is null || cotdYMDMapTree.GetKeys().Length == 0) {
            _RenderExplorerLoading();
        } else {
            _RenderExplorerCotdSelection();

            // VPad();
            // UI::Separator();
            // VPad();

            // _RenderExplorerMainTree();
        }

        UI::End();
    }

    int GetWindowFlags() {
        int ret = UI::WindowFlags::NoCollapse;
        // ret |= UI::WindowFlags::AlwaysUseWindowPadding;
        return ret;
    }

    void LoadCotdTreeFromDb() {
        while (histDb is null) { yield(); }
        @cotdYMDMapTree = histDb.GetCotdYearMonthDayMapTree();
    }

    /* General UI components */

    void _RenderExplorerLoading() {
        UI::Text("Loading...");
    }

    const string ResetIcon =
        "Give Up"  // tm joke?
        // Icons::Refresh
        // Icons::Home
        // Icons::Repeat
        // Icons::ArrowLeft
        // Icons::Reply
        // Icons::FileO  // 'new file' icon
        // Icons::Reload
        ;

    void ExplorerBreadcrumbs() {
        if (explYear.isSome) {
            DrawAsRow(_ExplorerBreadcrumbs, UI_EXPLORER + "-breadcrumbs", 7);
        }
    }

    void _ExplorerBreadcrumbs(DrawUiElems@ f) {
        if (explYear.isNone) { return; }  // nothing to do before explYear is set (we are on init screen; nothing to reset)
        // UI::Columns(5);  /* just buttons -- 5 btns max */
        // UI::Columns(9);  /* if we include separators like `/` */
        f();
        if (UI::Button(ResetIcon)) {
            /* as a coroutine b/c we don't want to clear the values before we finish drawing the UI. */
            resetLevel = 0;
            startnew(_ResetExplorerCotdSelection);
        }
        f();
        if (explYear.isSome && UI::Button(Text::Format("%04d", explYear.val))) {
            resetLevel = 1;
            startnew(_ResetExplorerCotdSelection);
        }
        f();
        if (explMonth.isSome && UI::Button(Text::Format("%02d", explMonth.val))) {
            resetLevel = 2;
            startnew(_ResetExplorerCotdSelection);
        }
        f();
        if (explDay.isSome && UI::Button(Text::Format("%02d", explDay.val))) {
            resetLevel = 3;
            startnew(_ResetExplorerCotdSelection);
        }
        f();
        if (explCup.isSome && UI::Button(Text::Format("#%01d", explCup.val))) {
            resetLevel = 4;
            startnew(_ResetExplorerCotdSelection);
        }
    }

    /* Explorer UI Idea: Buttons + Breadcrumbs */

    /* idea for rendering UI:
        - buttons, select year
        -> heading: COTD: 2022-XX-XX #X | Select Month
            body: grid of buttons for months, 4x3
            -> COTD: 2022-05-XX #X | Select Day
                body: grid of buttons for days, offset to match calendar starting on sunday (leftmost col)
                -> COTD: 2022-05-22 #X | Select Cup
                    body: 3 options: COTD, COTN, COTM
                    -> Render COTD Stats
                    heading: COTD: 2022-05-22 #2 | Stats
                    body: * loading while info downloading
                            map title, map info, date, players, divs, cutoffs, etc
                            button: "Load Histogram Times"
                    body-aux: histogram of times

        actions:
        each load clears the selections beneath it
        each heading has buttons [choose year] [choose month] [choose day] [choose cup] next to
            it as appropriate (or underneath heading).
        ... etc

        entry point: _RenderExplorerCotdSelection

        COTD YYYY-MM-DD screen (Y,M,D all selected already)
        - can show stuff like mapid at this point
        - maybe show COTD # selection on this screen
        - idea for screen layout:
            ------------------------
            | title                                 a title (and breadcrumbs, etc)
            | common map info (and thumnail)        common info for all COTDs that day (e.g., mapUid)
            |                                       then
            | COTD: [1] [2] [3]                     either show buttons
            |
            | (cotd stats?)                         or show cotd stats or w/e
            ------------------------
    */

    MaybeInt@ explYear = MaybeInt(),
              explMonth = MaybeInt(),
              explDay = MaybeInt(),
              explCup = MaybeInt(),
              explQDiv = MaybeInt(),
              explMatch = MaybeInt()
              ;

    /* global var that determines how far breadcrumbs are reset to.
       We do it this way so we can call _ResetExplorerCotdSelection
       as a coroutine.
       */
    uint resetLevel = 0;

    void _ResetExplorerCotdSelection() {
        auto level = resetLevel;
        if (level <= 0) explYear.AsNothing();
        if (level <= 1) explMonth.AsNothing();
        if (level <= 2) explDay.AsNothing();
        if (level <= 3) explCup.AsNothing();
        if (level <= 4) explQDiv.AsNothing();
        if (level <= 5) explMatch.AsNothing();
        resetLevel = 0;  /* always reset this to be 0 afterwards so unprepped calls to _Reset do something sensible. */
    }

    void _DevSetExplorerCotdSelection() {
        explYear.AsJust(2022);
        explMonth.AsJust(4);
        explDay.AsJust(1);
        explCup.AsJust(2);
        // explQDiv.AsJust(1);
        // explMatch.AsJust(1);
    }

    void _RenderExplorerCotdSelection() {
        /* we are in the selection phase while explCup.isNone */
        if (explYear.isNone) {
            TextHeading("Select COTD");
        }
        ExplorerBreadcrumbs();

        if (explYear.isNone) {
            _RenderExplorerCotdYearSelection();
        } else if (explMonth.isNone) {
            _RenderExplorerCotdMonthSelection();
        } else if (explDay.isNone) {
            _RenderExplorerCotdDaySelection();
        } else if (explCup.isNone) {
            _RenderExplorerCotdCupSelection();
        } else {
            _RenderExplorerCotdCup();
        }
    }

    string _ExplorerCotdTitleStr() {
        string ret = "COTD ";
        ret += explYear.isNone ? "XXXX" : Text::Format("%4d", explYear.val);
        ret += explMonth.isNone ? "-XX" : Text::Format("-%02d", explMonth.val);
        ret += explDay.isNone ? "-XX" : Text::Format("-%02d", explDay.val);
        ret += explCup.isNone ? " #X" : Text::Format(" #%1d", explCup.val);
        return ret;
    }

    void _RenderExplorerCotdYearSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Year");
        // UI::BeginTable(UI_EXPLORER + "-yrs");
        auto yrs = cotdYMDMapTree.GetKeys();
        yrs.SortDesc();
        for (uint i = 0; i < yrs.Length; i++) {
            string yr = yrs[i];
            if (UI::Button(yr)) {
                explYear.AsJust(Text::ParseInt(yr));
            }
        }
    }

    void _RenderExplorerCotdMonthSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Month");
        auto md = cast<dictionary@>(cotdYMDMapTree["" + explYear.val]);
        auto months = md.GetKeys();
        months.SortDesc();
        string month;
        for (uint i = 0; i < months.Length; i++) {
            month = months[i];
            if (UI::Button(month)) {
                explMonth.AsJust(Text::ParseInt(month));
            }
        }
    }

    /* select a monthDay for COTD -- draw calendar for the month */
    void _RenderExplorerCotdDaySelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Day");
        auto md = cast<dictionary@>(cotdYMDMapTree["" + explYear.val]);
        auto dd = cast<dictionary@>(md[Text::Format("%02d", explMonth.val)]);
        auto days = dd.GetKeys();
        days.SortAsc();
        string day;
        JsonBox@ map1 = cast<JsonBox@>(dd[days[0]]);
        JsonBox@ map;
        uint dayOffset = map1.j["day"];  /* .monthDay is the calendar day number (1-31); .day is 0-6 */
        if (UI::BeginTable(UI_EXPLORER + "-ymd-table", 7)) {
            UI::TableNextRow();
            for (uint i = 0; i < dayOffset; i++) {
                UI::TableNextColumn();  /* skip some columns based on offset */
            }
            for (uint i = 0; i < days.Length; i++) {
                day = days[i];
                @map = cast<JsonBox@>(dd[day]);
                if (i > 0 && i + dayOffset % 7 == 0) {
                    UI::TableNextRow();
                }
                UI::TableNextColumn();
                if (UI::Button(day)) {
                    OnSelectedCotdDay(Text::ParseInt(day));
                }
            }
            UI::EndTable();
        }
    }

    void OnSelectedCotdDay(int day) {
        /* when the day is selected we should fire off a
           coroutine to ensure we have the map data.
        */
        explDay.AsJust(day);
        startnew(EnsureMapDataForCurrDay);
    }

    void EnsureMapDataForCurrDay() {
        /* check cache for map data
            if present: return
            if not:
            - get info from API
            - download thumbnail to cache file
            - populate cache
            - save cache
        */
        JsonBox@ day = CotdTreeYMD();
        string uid = day.j['mapUid'];
        // histDb
    }

    const string[] COTD_BTNS = { "1st (COTD) @ 7pm CEST/CET", "2nd (COTN) @ 3am CEST/CET", "3rd (COTM) @ 11am CEST/CET" };

    void _RenderExplorerCotdCupSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Cup");
        string btnLab;
        for (uint i = 0; i < COTD_BTNS.Length; i++) {
            btnLab = COTD_BTNS[i];
            int cotdNum = btnLab[0] - 48;  /* '1' = 49; 49 - 48 = 1. (ascii char value - 48 = int value); */
            if (UI::Button(btnLab)) {
                explCup.AsJust(cotdNum);
            }
        }
    }

    dictionary@ CotdTreeY() {
        return cast<dictionary@>(cotdYMDMapTree["" + explYear.val]);
    }

    dictionary@ CotdTreeYM() {
        return cast<dictionary@>(CotdTreeY()[Text::Format("%02d", explMonth.val)]);
    }

    JsonBox@ CotdTreeYMD() {
        return cast<JsonBox@>(CotdTreeYM()[Text::Format("%02d", explDay.val)]);
    }

    void _RenderExplorerCotdCup() {
        TextHeading(_ExplorerCotdTitleStr());
        auto map = CotdTreeYMD();
        string mapUid = map.j['mapUid'];
        UI::Text("Map ID: " + mapUid);
    }

    /* Explorer UI Idea: Tree Structure

       ? Hmm, not sure this is v good as a way to do it.
    */

    // DEPRECATED (but code is still useful)
    void _RenderExplorerMainTree() {
        // warn("_RenderExplorerMainTree is deprecated!!!");
        // auto yrs = cast<int[]@>(cotdYMDMapTree['__keys']);
        if (cotdYMDMapTree is null || cotdYMDMapTree.GetKeys().Length == 0) {
            _RenderExplorerLoading();
            return;
        }
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

    /* Explorer: test / dev / debug functions */

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
