Debouncer@ debounce = Debouncer();

// todo TOTD times arbitrary ranges:
// https://live-services.trackmania.nadeo.live/api/token/leaderboard/group/<seasonUid>/map/<mapUid>/top?offset=300&length=15&onlyWorld=true

namespace CotdExplorer {
#if RELEASE
    const string ExplorerWindowTitle = "COTD Explorer";
#elif DEV
    const string ExplorerWindowTitle = "COTD Explorer (Dev)";
#elif UNIT_TEST
    const string ExplorerWindowTitle = "COTD Explorer (Unit)";
#else
    const string ExplorerWindowTitle = "COTD Explorer (Unk)";
#endif

    const string ByCotdHudStr = EscapeRawToOpenPlanet(BcCommands::byLineB);

    BoolWP@ windowActive = BoolWP(false);
    string icon = Icons::AreaChart;
    HistoryDb@ histDb;  /* instantiated in PersistentData */
    MapDb@ mapDb;  /* instantiated in PersistentData */
    vec2 gameRes;
    vec2 calendarDayBtnDims;
    vec2 calendarMonthBtnDims, challengeBtnDims;
    const vec2 mapThumbDims = vec2(256, 256);
    vec2 screenRes = vec2(Draw::GetWidth(), Draw::GetHeight());
    int2 mousePos = int2(0, 0);

    dictionary@ cotdYMDMapTree;



    bool WaitNullRefs() {
        /* these should be set in Main */
        return histDb is null || mapDb is null;
    }

    void Main() {
        InitAndCalcUIElementSizes();
        while (WaitNullRefs()) {
            @histDb = PersistentData::histDb;
            @mapDb = PersistentData::mapDb;
            yield();
        }
        startnew(ExplorerManager::ManageHistoricalTotdData);
        startnew(SlowlyGetAllMapData);
        _ResetExplorerCotdSelection();
    }

    void InitAndCalcUIElementSizes() {
        /* set on load, so changing the game res mid-game will not update this value. */
        gameRes = vec2(Draw::GetWidth(), Draw::GetHeight());
        /* the calendar should take up 20%,30% of the screen size,
           has a 7*5 grid typically,
           so each button is a bit less than .2/7,.3/5 of the screen size.
           tweak wider and flatter: .04,.05
           looks good on 1080 so use that as reference (not gameRes).
        */
        calendarDayBtnDims = vec2(1920, 1080) * vec2(0.04, 0.05);
        calendarMonthBtnDims = vec2(1920, 1080) * vec2(0.0472, 0.05);
        challengeBtnDims = vec2(1920, 1080) * vec2(.056, .05);
        windowActive.v = IsDev();
    }

    void OnMouseMove(int x, int y) {
        mousePos.x = x;
        mousePos.y = y;
        // logcall('OnMouseMove', '' + mousePos.x + ", " + mousePos.y);
    }

    /* window controls */

    bool IsVisible() {
        return windowActive.v;
    }

    void ShowWindow() {
        windowActive.Set(true);
        startnew(OnWindowShow);
    }

    void HideWindow() {
        windowActive.Set(false);
        DataManager::cotd_OverrideChallengeId.AsNothing();
    }

    void ToggleWindow() {
        if (IsVisible()) HideWindow();
        else ShowWindow();
    }

    /* Rendering Top-Level */

    void Render() {
    }

    void RenderInterface() {
        _RenderAll();
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
        if (UI::MenuItem(c_menuIconColor + icon + "\\$z " + ExplorerWindowTitle, "", IsVisible())) {
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
        if (windowActive.ChangedToTrue()) {
            UI::SetNextWindowSize(730, Math::Min(Draw::GetHeight() - 80, 1150), UI::Cond::Always);
            windowActive.v = true;
        }
        UI::Begin(ExplorerWindowTitle, windowActive.v, GetWindowFlags());

        if (UI::IsWindowAppearing()) {
            UI::SetWindowSize(vec2(730, 1100), UI::Cond::Always);
            startnew(LoadCotdTreeFromDb);
            // startnew(_DevSetExplorerCotdSelection);
        }

        /* menu bar */

        _RenderMenuBar();

        /* header */

        CenteredTextBigHeading("TOTD + COTD Explorer", ByCotdHudStr);
        UI::Separator();

        /* main body */

        if (!mapDb.Initialized) {
            _RenderDbLoading();
        } else if (cotdYMDMapTree is null || cotdYMDMapTree.GetKeys().Length == 0) {
            _RenderExplorerLoading();
        } else {
            _RenderExplorerCotdSelection();
        }
        UI::End();
    }

    int GetWindowFlags() {
        int ret = UI::WindowFlags::NoCollapse;
        ret |= UI::WindowFlags::MenuBar;
        // ret |= UI::WindowFlags::AlwaysUseWindowPadding;
        return ret;
    }

    void LoadCotdTreeFromDb() {
        while (histDb is null) { yield(); }
        @cotdYMDMapTree = histDb.GetCotdYearMonthDayMapTree();
        while (cotdYMDMapTree is null || cotdYMDMapTree.GetSize() == 0) {
            sleep(200);
            @cotdYMDMapTree = histDb.GetCotdYearMonthDayMapTree();
        }
    }

#if RELEASE
    const uint SlowlyGetAllMapData_InitSleep = 60 * 1000;
    const uint SlowlyGetAllMapData_LoopSleep = 180 * 1000;
#else
    const uint SlowlyGetAllMapData_InitSleep = 30 * 1000;
    const uint SlowlyGetAllMapData_LoopSleep = 60 * 1000;
#endif
    const uint SlowlyGetAllMapData_DoneSleep = 8 * 3600 * 1000;

    void SlowlyGetAllMapData() {
        // todo: refactor into a coro in mapDb that inits each start (no need for db) + detects when to skip to not waste time.
        logcall("SlowlyGetAllMapData", "Starting...");
        while (cotdYMDMapTree is null) yield();
        while (true) {
            sleep(SlowlyGetAllMapData_InitSleep);
            if (cotdYMDMapTree is null) continue;
            auto years = cotdYMDMapTree.GetKeys();
            for (uint y = 0; y < years.Length; y++) {
                dictionary@ year = cast<dictionary>(cotdYMDMapTree[years[y]]);
                auto months = year.GetKeys();
                for (uint m = 0; m < months.Length; m++) {
                    if (HaveAllMapDataForYM(years[y], months[m])) {
                        // if we have the data then skip the sleep.
                        continue;
                    }
                    logcall("SlowlyGetAllMapData", "running for " + years[y] + "-" + months[m]);
                    EnsureMapDataForYM(years[y], months[m]);
                    sleep(SlowlyGetAllMapData_LoopSleep);
                }
            }
            logcall("SlowlyGetAllMapData", "sleeping for " + int(SlowlyGetAllMapData_DoneSleep/1000) + " s");
            sleep(SlowlyGetAllMapData_DoneSleep);
        }
    }

    /* General UI components */

    void _RenderDbLoading() {
        UI::Text("Loading DB from disk...");
    }

    void _RenderExplorerLoading() {
        UI::Text("Syncing Initial Data...");
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
        UI::PushStyleColor(UI::Col::ChildBg, vec4(.1, .5, 1., .02));
        // if (UI::BeginChild( "-breadcrumbsOuter", vec2(0, 40))) {
        UI::BeginChild( "-breadcrumbsOuter", vec2(0, 40));
        UI::Dummy(vec2(1, 0));
        DrawAsRow(_ExplorerBreadcrumbs, UI_EXPLORER + "-breadcrumbs", 7);
        UI::EndChild();
        // }
        UI::PopStyleColor();
    }

    /* the function that's passed in is meant to be run before each chunk of UI elements */
    void _ExplorerBreadcrumbs(DrawUiElems@ f) {
        f();
        UI::Dummy(vec2(2, 0));

        f();

        UI::AlignTextToFramePadding();
        UI::Text("Nav:");

        f();  // always run at least once

        if (explYear.isNone) { // return early before explYear is set (we are on init screen; nothing to reset)
            DisabledButton("3.. 2.. 1..");
            return;
        }

        // base of the breadcrumbs otherwise
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
        if (explMonth.isSome && UI::Button(MONTH_NAMES[explMonth.val])) {
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

    void DrawMapTooltip(const string &in mapUid) {
        auto map = mapDb.GetMap(mapUid);
        if (UI::IsItemHovered()) {
            // UI::PushStyleColor(UI::Col::PopupBg, vec4(.2, .2, .2, .4));
            UI::BeginTooltip();
            DrawMapInfo(map, false, true, 1.0);
            UI::EndTooltip();
            // UI::PopStyleColor(1);
        }
    }

    void DrawMapInfo(TmMap@ map, bool isTitle = false, bool drawThumbnail = true, float thumbnailSizeRel = 1.0) {
        if (map is null) {
            UI::Text("Downloading Map Info...");
            UI::Text("Queued: " + mapDb.queueDb.Length + " / In Progress: " + mapDb.mapsInProgress);
            return;
        }
        string tnUrl = map.ThumbnailUrl;
        string authorName = map.AuthorDisplayName;
        string authorScore = Time::Format(map.AuthorScore);
        string mapName = map.Name;
        mapName = EscapeRawToOpenPlanet(MakeColorsOkayDarkMode(mapName));
        if (isTitle) TextHeading(mapName);
        else UI::Text(mapName);
        UI::Text(EscapeRawToOpenPlanet("By: " + authorName));
        UI::Text("Author Time: " + authorScore);
        if (drawThumbnail) {
            VPad();
            _DrawThumbnail(tnUrl, true, thumbnailSizeRel);
        }
    }

    void DrawMapThumbnailBigTooltip(const string &in tnUrl) {
        if (UI::IsItemHovered()) {  /* && PersistentData::ThumbnailCached(tnUrl) */
            // UI::PushStyleColor(UI::Col::PopupBg, vec4(.2, .2, .2, .4));
            UI::BeginTooltip();
            _DrawThumbnail(tnUrl, true, 4.0);
            UI::EndTooltip();
            // UI::PopStyleColor(1);
        }
    }

    /* MenuBar */

    void _RenderMenuBar() {
        if (UI::BeginMenuBar()) {

            if (UI::BeginMenu("Utilities")) {
                if (UI::MenuItem("Color Gradients Tool", "", windowCGradOpen.v)) {
                    windowCGradOpen.v = !windowCGradOpen.v;
                }
                UI::EndMenu();
            }

            if (UI::BeginMenu("Databases")) {
                if (UI::MenuItem("Re-index COTD Qualifiers", '', false)) {
                    startnew(DbMenuCotdIndexReset);
                }
                UI::EndMenu();
            }

            _RenderSyncMenu();

            UI::EndMenuBar();
        }
    }

    void DbMenuCotdIndexReset() {
        mapDb.cotdIndexDb.ResetAndReIndex();
        if (explDay.isSome) {
            EnsureMapDataForCurrDay();
        }
    }

    void _RenderSyncMenu() {
        /* menu for showing status of sync */
        // todo("_RenderSyncMenu");
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
              explChallenge = MaybeInt(),
              explComp = MaybeInt(),
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
        if (level <= 3) {
            explCup.AsNothing();
            explChallenge.AsNothing();
            explComp.AsNothing();
        }
        // todo: these aren't implemented yet
        if (level <= 4) explQDiv.AsNothing();
        if (level <= 5) explMatch.AsNothing();
        resetLevel = 0;  /* always reset this to be 0 afterwards so unprepped calls to _Reset do something sensible. */
    }

    void _DevSetExplorerCotdSelection() {
        while (cotdYMDMapTree is null) yield();
        sleep(250);
        warn("_DevSetExplorerCotdSelection");
        explYear.AsJust(2022);
        OnSelectedCotdMonth(4);
        OnSelectedCotdDay(29);
        // OnSelectedCotdChallenge()
        // explCup.AsJust(2);
        // explQDiv.AsJust(1);
        // explMatch.AsJust(1);
    }

    void _RenderExplorerCotdSelection() {
        ExplorerBreadcrumbs();
        UI::Separator();
        // /* we are in the selection phase while explCup.isNone */
        // if (explYear.isNone) {
        //     TextHeading("Select COTD");
        // }

        if (explYear.isNone) {
            _RenderExplorerCotdYearSelection();
        } else if (explMonth.isNone) {
            _RenderExplorerCotdMonthSelection();
        } else if (explDay.isNone) {
            _RenderExplorerCotdDaySelection();
        } else { // if (explCup.isNone)
            _RenderExplorerTotd();
        }
        // else {
        //     _RenderExplorerCotdCup();
        // }
    }

    string _ExplorerCotdTitleStr() {
        string ret = "COTD " + SelectedCotdDateStr();
        ret += explCup.isNone ? " #X" : Text::Format(" #%1d", explCup.val);
        return ret;
    }

    string SelectedCotdDateStr() {
        string ret = "";
        ret += explYear.isNone ? "XXXX" : Text::Format("%4d", explYear.val);
        ret += explMonth.isNone ? "-XX" : Text::Format("-%02d", explMonth.val);
        ret += explDay.isNone ? "-XX" : Text::Format("-%02d", explDay.val);
        return ret;
    }

    void _RenderExplorerCotdYearSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Year");
        auto yrs = cotdYMDMapTree.GetKeys();
        yrs.SortAsc();
        if (UI::BeginTable(UI_EXPLORER + "-y-table", 5, TableFlagsStretch())) {
            UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("1", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("2", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("3", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);

            UI::TableNextColumn(); /* empty */

            for (uint i = 0; i < yrs.Length; i++) {
                UI::TableNextColumn();
                string yr = yrs[i];
                if (UI::Button(yr, calendarMonthBtnDims)) {
                    OnSelectedYear(Text::ParseInt(yr));
                }
                if ((i + 1) % 3 == 0) {
                    UI::TableNextRow();
                    UI::TableNextColumn(); /* skip first col of new row */
                }
            }

            /* at end of years -- button to jump to today */
            UI::TableNextColumn();
            UI::Dummy(vec2(2, 20));
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::TableNextColumn();
            UI::TableNextColumn();
            if (UI::Button("Today's\nTrack", calendarMonthBtnDims)) {
                auto ymd = histDb.GetMostRecentTotdDate();
                OnSelectedYear(Text::ParseInt(ymd[0]));
                OnSelectedCotdMonth(Text::ParseInt(ymd[1]));
                OnSelectedCotdDay(Text::ParseInt(ymd[2]));
            }

            UI::EndTable();
        }

    }

    void OnSelectedYear(int year) {
        explYear.AsJust(year);
    }

    void _RenderExplorerCotdMonthSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Month");
        auto md = CotdTreeY();
        auto months = md.GetKeys();
        months.SortAsc();
        uint month;
        int _offs = (Text::ParseInt(months[0]));  // 2 rows of 6 months
        int _last = Text::ParseInt(months[months.Length - 1]);
        int _nMonths = months.Length;
        bool _disable;
        if (UI::BeginTable(UI_EXPLORER + "-ym-table", 8, TableFlagsFixedSame())) {
            UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
            for (uint i = 0; i < 6; i++) UI::TableSetupColumn("" + i, UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);

            UI::TableNextColumn();
            for (int x = 1; x <= 12; x++) {
                UI::TableNextColumn();
                _disable = x < _offs || x - _offs >= _nMonths;
                if (MDisabledButton(_disable, MONTH_NAMES[x], calendarMonthBtnDims)) {
                    OnSelectedCotdMonth(x);
                }
                if (x % 6 == 0) {
                    UI::TableNextColumn();
                    UI::TableNextColumn();
                }
            }
            UI::EndTable();
        }
        if (explYear.val == 2020) {
            VPad();
            VPad();
            TextBigStrong("\\$f81" + "Notice: COTD stats are not available prior to 2020-11-02. (A new API/system was introduced at that point. This plugin uses that new API.)");
        }
    }

    void OnSelectedCotdMonth(int month) {
        /* when the month is selected we should fire off a
           coroutine to ensure we have all the map data.
        */
        explMonth.AsJust(month);
        startnew(EnsureMapDataForCurrMonth);
        // startnew(LoadThumbTexturesForCurrMonth);  // idk if this is worth it
    }

    // todo -- can select june 12th but it's only june 1st

    /* select a monthDay for COTD -- draw calendar for the month */
    void _RenderExplorerCotdDaySelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Day");
        // auto md = cast<dictionary@>(cotdYMDMapTree["" + explYear.val]);
        // auto dd = cast<dictionary@>(md[Text::Format("%02d", explMonth.val)]);
        dictionary@ dd = CotdTreeYM();
        auto days = dd.GetKeys();
        days.SortAsc();
        string day;
        TrackOfTheDayEntry@ map1 = cast<TrackOfTheDayEntry@>(dd[days[0]]);
        TrackOfTheDayEntry@ map;
        uint dayOffset = map1.day;  /* .monthDay is the calendar day number (1-31); .day is 0-6 */
        if (UI::BeginTable(UI_EXPLORER + "-ymd-table", 9, TableFlagsStretch())) {
            UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
            for (uint i = 0; i < 7; i++) UI::TableSetupColumn("" + i, UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);

            UI::TableNextColumn();

            for (uint i = 0; i < dayOffset; i++) {
                UI::TableNextColumn();  /* skip some columns based on offset */
            }

            for (uint i = 0; i < days.Length; i++) {
                day = days[i];
                UI::TableNextColumn();
                @map = cast<TrackOfTheDayEntry@>(dd[day]);
                if (map is null || IsJsonNull(map.mapUid)) continue;
                string mapUid = map.mapUid;
                bool _disabled = mapUid.Length < 10;
                if (MDisabledButton(_disabled, day, calendarDayBtnDims)) {
                    OnSelectedCotdDay(Text::ParseInt(day));
                }
                DrawMapTooltip(mapUid);
                if ((i + 1 + dayOffset) % 7 == 0) {
                    UI::TableNextColumn();
                    UI::TableNextColumn();
                }
            }

            UI::EndTable();
        }
    }

    void OnSelectedCotdDay(int day) {
        /* when the day is selected we should fire off a
           coroutine to ensure we have the map data.
        */
        logcall("OnSelectedCotdDay", "Day: " + day);
        explDay.AsJust(day);
        startnew(EnsureMapDataForCurrDay);
    }

    void EnsureMapDataForCurrMonth() {
        EnsureMapDataForYM('', '');
    }

    void EnsureMapDataForYM(const string &in year, const string &in month) {
        auto mo = CotdTreeYM(year, month);
        auto keys = mo.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            EnsureMapDataForYMD(year, month, keys[i]);
        }
    }

    void LoadThumbTexturesForCurrMonth() {
        LoadThumbTexturesForYM('', '');
    }

    void LoadThumbTexturesForYM(const string &in year, const string &in month) {
        auto mo = CotdTreeYM(year, month);
        auto keys = mo.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto day = keys[i];
            auto totd = CotdTreeYMD(year, month, day);
            auto map = mapDb.GetMap(totd.mapUid);
            if (PersistentData::ThumbnailCached(map.ThumbnailUrl)) {
                yield();
                PersistentData::GetThumbTex(map.ThumbnailUrl);  // load it from disk if it isn't already
            }
        }
    }

    bool HaveAllMapDataForYM(const string &in year, const string &in month) {
        auto mo = CotdTreeYM(year, month);
        auto keys = mo.GetKeys();
        uint lastBreak = Time::Now;
        for (uint i = 0; i < keys.Length; i++) {
            if (!HaveAllMapDataForYMD(year, month, keys[i])) return false;
            if (Time::Now - lastBreak > 10) {
                yield();
                lastBreak = Time::Now;
            }
        }
        return true;
    }

    void EnsureMapDataForCurrDay() {
        EnsureMapDataForYMD('', '', '');
        challengeIdsForSelectedCotd = CotdChallengesForSelectedDate();
        compIdsForSelectedCotd = CotdCompForSelectedDate();
    }

    void EnsureMapDataForYMD(const string &in _year, const string &in _month, const string &in _day) {
        TrackOfTheDayEntry@ day = CotdTreeYMD(_year, _month, _day);
        if (day is null) return;
        string uid = day.mapUid;
        if (uid.Length == 0) return;
        string seasonUid = day.seasonUid;
        if (seasonUid.Length == 0) return;
        string endTs = '' + day.endTimestamp;
        auto cIds = CotdChallengesForYMD(_year, _month, _day);
        mapDb.QueueMapGet(uid, false);
        mapDb.QueueMapRecordGet(seasonUid, uid, endTs);
    }

    bool HaveAllMapDataForYMD(const string &in _year, const string &in _month, const string &in _day) {
        TrackOfTheDayEntry@ day = CotdTreeYMD(_year, _month, _day);
        if (day is null) return true;
        string uid = day.mapUid;
        if (uid.Length == 0) return true;
        /* add additional resources here if they're added above */
        return true
            && PersistentData::MapRecordsCached(uid)
            && mapDb.MapIsCached(uid)
            ;
    }

    void DrawMapDownloadProgress() {
        UI::TextWrapped("Map info progress | Done: " + mapDb.queueDb.CompletedHowMany + ", Queued: " + mapDb.queueDb.Length);
        if (UI::Button("Check again if available...")) {
            startnew(LoadCotdTreeFromDb);
            startnew(EnsureMapDataForCurrDay);
        }
    }

    void DrawChallengeDownloadProgress() {
        auto maxId = histDb.ChallengesSdMaxId();
        UI::TextWrapped("Challenge sync progress | ix: " + mapDb.cotdIndexDb.GetMaxId() + " / dl: " + histDb.GetChallengesMaxId() + " / total: " + maxId);
        if (UI::Button("Check again if available...")) {
            startnew(EnsureMapDataForCurrDay);
        }
    }

    void DrawCompDownloadProgress() {
        auto scanned = mapDb.cotdIndexDb.GetCompNScanned();
        UI::TextWrapped("Competition sync progress | index: " + scanned + " / dl: " + mapDb.compsDb.GetSize());
        if (UI::Button("Check again if available...")) {
            startnew(EnsureMapDataForCurrDay);
        }
    }

    PlayerName@ map_author;
    void DrawTotdMapInfoTable(TmMap@ map, const string &in seasonId, const string &in totdDate) {
        if (map is null) {
            TextBigStrong("\\$fa4" + "Map is not found, it might be in the download queue.");
            DrawMapDownloadProgress();
            return;
        }
        string mapUid = map.Uid;
        string tnUrl = map.ThumbnailUrl;
        string authorId = map.AuthorWebServicesUserId;
        string authorScore = Time::Format(map.AuthorScore);
        string authorName = map.AuthorDisplayName;
        if (map_author is null or map_author.Id != authorId) {
            // @map_author = PlayerName(authorName, authorId, IsSpecialPlayerId(authorId));
            @map_author = PlayerNames::Get(authorId);
        }
        string authorNameAndId = authorName + " " + authorId;
        // apply special after setting authorNameAndId
        // if (IsSpecialPlayerId(authorId)) authorName = rainbowLoopColorCycle(authorName, true);
        string mapName = map.Name;
        string origMapName = mapName;
        mapName = EscapeRawToOpenPlanet(MakeColorsOkayDarkMode(mapName));
        TextHeading(mapName + " \\$z(TOTD for " + totdDate + ")");
        if (UI::BeginTable(UI_EXPLORER + '-mapInfo', 5, TableFlagsStretch())) {
            UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("mapinfo", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("mid", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("thumbnail", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);

            UI::TableNextColumn(); /* left */

            UI::TableNextColumn(); /* map info */
            // UI::Text(EscapeRawToOpenPlanet("Mapper: " + authorName));
            UI::Text("Name: " + mapName);
            UI::Text("Mapper: ");
            SetCursorAtItemTopRight();
            map_author.Draw();
            UI::Text("Author Time: " + authorScore);
            DrawMapRecordsOrLoading(mapUid);
            // UI::Text("Map Uid:");
            TextWithCooldown("Uid: " + mapUid.SubStr(0, 14) + "...", mapUid, mapUid);
            UI::Dummy(vec2(0, 40));
            UI::PushFont(headingFont);
            if (MDisabledButton(!debounce.CouldProceed('play-map-btn', 2000), 'Play Map!', vec2(160, 70))) {
                if (!debounce.CanProceed('play-map-btn', 2000)) {
                    warn("debouncer said we could proceed but then said we can't proceed :(");
                }
                GI::GetMainaTitleControlScriptAPI().PlayMap(wstring(string(map.FileUrl)), '', '');
            };
            UI::PopFont();

            // TMX: /api/maps/get_map_info/uid/{id}
            // ButtonLink("TMX", "https://trackmania.exchange/mapsearch2?trackname=" + origMapName);
            // UI::SameLine();
            ButtonLink("TM.IO", "https://trackmania.io/#/totd/leaderboard/" + seasonId + "/" + mapUid);

            UI::TableNextColumn(); /* mid */
            UI::Dummy(vec2(75, 0));

            UI::TableNextColumn(); /* thumbnail */
            _DrawThumbnail(tnUrl, true, 1.0);
            DrawMapThumbnailBigTooltip(tnUrl);

            UI::TableNextColumn(); /* right */
            UI::EndTable();
        }
    }

    void DrawMapRecordsOrLoading(const string &in uid) {
        if (PersistentData::MapRecordsCached(uid)) {
            auto mr = PersistentData::GetMapRecord(uid);
            UI::Text("TOTD Record: " + Time::Format(mr.j['tops'][0]['top'][0]['score']));
        } else {
            UI::Text("Loading map records...");
        }
    }

    void _RenderExplorerTotd() {
        auto mapInfo = CotdTreeYMD();
        if (mapInfo is null) {
            UI::Text("Waiting for map info...");
            return;
        }
        DrawTotdMapInfoTable(mapDb.GetMap(mapInfo.mapUid), mapInfo.seasonUid, SelectedCotdDateStr());
        PaddedSep();
        /* either select cup or draw cup info */
        if (explCup.isNone) {
            _RenderExplorerCotdCupSelection();
        } else {
            // UI::Text('' + explChallenge.val);
            _RenderExplorerCotdCup();
        }
    }

    bool ExpectMultipleCups(int year, int month, int day) {
        return (year > 2021)
            || (year == 2021 && (
                    month > 8
                    || (month == 8 && day > 9))
            );
    }

    const string[] COTD_BTNS = { "1st (COTD)\n7pm CEST/CET", "2nd (COTN)\n3am CEST/CET", "3rd (COTM)\n11am CEST/CET" };


    int[] challengeIdsForSelectedCotd = {};
    int[] compIdsForSelectedCotd = {};
    void _RenderExplorerCotdCupSelection() {
        // auto cIds = CotdChallengesForSelectedDate();
        auto cIds = challengeIdsForSelectedCotd;
        auto compIds = compIdsForSelectedCotd;
        TrackOfTheDayEntry@ totdInfo = CotdTreeYMD();
        string mapUid = totdInfo.mapUid;
        bool _disabled = false;
        if (cIds.Length == 0) {
            UI::TextWrapped("\\$f81 Warning: cannot find challengeIds for COTDs on " + SelectedCotdDateStr() + "; nChallenges=" + cIds.Length);
            DrawChallengeDownloadProgress();
        } else if (compIds.Length == 0) {
            UI::TextWrapped("\\$f81 Warning: cannot find competition IDs for COTDs on " + SelectedCotdDateStr() + "; nComps=" + compIds.Length);
            DrawCompDownloadProgress();
        } else {
            TextHeading(_ExplorerCotdTitleStr() + " | Select Cup");
            if (cIds.Length < 3 && ExpectMultipleCups(explYear.val, explMonth.val, explDay.val)) {
                // todo: remove this when no more COTD quali visibility/indexing bugs.
                UI::TextWrapped(c_orange_600 + "If a COTD is missing, try Databases > Re-index COTD Qualifiers. If that fails, reload the plugin via Developer > Reload Plugin > COTD HUD.");
            }
            string btnLab;
            UI::PushStyleVar(UI::StyleVar::ButtonTextAlign, vec2(.5, .5));
            if (UI::BeginTable(UI_EXPLORER + "-tableChooseCId", 5, TableFlagsStretch())) {
                UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
                for (uint i = 0; i < 3; i++) UI::TableSetupColumn("" + i, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);

                UI::TableNextColumn();
                for (int i = 0; i < Math::Min(cIds.Length, COTD_BTNS.Length); i++) {
                    auto c = histDb.GetChallenge(cIds[i]);
                    if (c !is null) {
                        _disabled = c.endDate >= uint(Time::Stamp);
                        string cName = string(c.name);
                        bool isSingleton = cName.SubStr(26, 1) != "#";
                        int cotdNum = 1;
                        if (!isSingleton)
                            cotdNum = Text::ParseInt(cName.SubStr(27, 1)); // should be the number in "#2" or w/e after COTD
                        if (cotdNum <= 0 || cotdNum > 3) {
                            warn("_RenderExplorerCotdCupSelection | invalid cotdNum: " + cotdNum + " for COTD with name: " + cName);
                        }
                        btnLab = COTD_BTNS[cotdNum - 1];
                        UI::TableNextColumn();
                        if (MDisabledButton(_disabled, btnLab, challengeBtnDims)) {
                            OnSelectedCotdChallenge(cotdNum, mapUid, cIds[i], compIds[i]);
                        }
                    } else {
                        UI::TableNextColumn();
                        UI::TextWrapped("\\$f81 Warning: challenge should exist but does not. (It may be being downloaded currently.)");
                        UI::TableNextColumn();
                        UI::TextWrapped(c_green + "Sync status: " + Json::Write(histDb.ChallengesSyncData()));
                    }
                }
                UI::EndTable();
            }
            UI::PopStyleVar();
        }
    }

    void OnSelectedCotdChallenge(int cotdNum, const string &in mapUid, int cId, int compId) {
        explCup.AsJust(cotdNum); // selection params
        explChallenge.AsJust(cId);
        explComp.AsJust(compId);
        startnew(EnsurePlayerNames); // get player names if we have times

        // lastCidDownload = -1; // reset download button
        mapDb.QueueMapChallengeTimesGet(mapUid, cId);
        lastCidDownload = cId;
        mapDb.QueueCompRoundsGet({compId});
        // lastCompIdDlClick = int(compId);
        lastCompIdDlClick = -1;

        histToShow = mapUid + "--" + cId; // the histogram to show
        showHistogram = false;
        histUpperRank = highRankFilter = 99999; // rank filter defaults
        lowRankFilter = 0;
        if (PersistentData::MapTimesCached(mapUid, cId)) {
            startnew(_GenHistogramData); // proactively generate histograms where data is available
        }

        w_AllCotdQualiTimes.Hide(); // hide all times window if it's still around from a previous COTD
        w_AllCotdDivResults.Hide();
        WAllTimes::SetParams(mapUid, cId);
        WAllDivResults::SetParams(compId);
    }

    void EnsurePlayerNames() {
        int cId = explChallenge.val;
        TrackOfTheDayEntry@ totdInfo = CotdTreeYMD();
        string mapUid = totdInfo.mapUid;
        if (PersistentData::MapTimesCached(mapUid, cId)) {
            auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
            int nPlayers = jb.j['nPlayers'];
            int chunkSize = jb.j['chunkSize'];
            string[] playerIds = array<string>(nPlayers + chunkSize);  // add some excap in size of array; empty values will be skipped
            string[] keys = jb.j['ranges'].GetKeys();
            string pid;
            for (uint i = 0; i < keys.Length; i++) {
                auto times = jb.j['ranges'][keys[i]];
                for (uint j = 0; j < times.Length; j++) {
                    pid = times[j]['player'];
                    playerIds[i * chunkSize + j] = pid;
                }
            }
            mapDb.QueuePlayerNamesGet(playerIds);
        }
    }

    dictionary@ CotdTreeY(string yr = '') {
        if (yr == '') yr = "" + explYear.val;
        dictionary@ ret;
        if (cotdYMDMapTree !is null && cotdYMDMapTree.Get(yr, @ret)) {
            return ret;
        }
        return dictionary();
    }

    dictionary@ CotdTreeYM(const string &in year = '', string month = '') {
        if (month == '') month = Text::Format("%02d", explMonth.val);
        dictionary@ ret;
        if (CotdTreeY(year).Get(month, @ret)) {
            return ret;
        }
        // return cast<dictionary@>(CotdTreeY()[Text::Format("%02d", explMonth.val)]);
        return dictionary();
    }

    TrackOfTheDayEntry@ CotdTreeYMD(const string &in year = '', const string &in month = '', string day = '') {
        if (day == '') day = Text::Format("%02d", explDay.val);
        TrackOfTheDayEntry@ ret;
        if (CotdTreeYM(year, month).Get(day, @ret)) {
            return ret;
        }
        return null;
    }

    int[] CotdChallengesForSelectedDate() {
        return CotdChallengesForYMD('' + explYear.val, Text::Format("%02d", explMonth.val), Text::Format("%02d", explDay.val));
        // return mapDb.GetChallengesForDate('' + explYear.val, Text::Format("%02d", explMonth.val), Text::Format("%02d", explDay.val));
    }

    int[] CotdChallengesForYMD(const string &in year, const string &in month, const string &in day) {
        return mapDb.GetChallengesForDate(year, month, day);
    }

    int[] CotdCompForSelectedDate() {
        string[] ymd = ToYMDArr(explYear.val, explMonth.val, explDay.val);
        return mapDb.GetCompsForDate(ymd[0], ymd[1], ymd[2]);
    }

    /* returns false when showLoading=false and the image is loading */
    bool _DrawThumbnail(const string &in urlOrFileName, bool showLoading = true, float sizeMult = 1.5) {
        if (PersistentData::ThumbnailCached(urlOrFileName)) {
            auto tex = PersistentData::GetThumbTex(urlOrFileName);
            if (tex is null) {
                UI::Text("Null texture thumbnail...");
            } else {
                _DrawThumbnailWSize(tex, sizeMult);
            }
            return true;
        } else {
            UI::Text("Loading thumbnail...");
            return showLoading;
        }
    }

    void _DrawThumbnailWSize(UI::Texture@ tex, float sizeMult) {
        UI::Image(tex, mapThumbDims * sizeMult);
    }

    void ResetCotdCupButton() {
        UI::Dummy(vec2(10, 0));
        UI::SameLine();
        if (UI::Button("Select Cup #")) {
            resetLevel = 3;
            _ResetExplorerCotdSelection();
        }
    }

    void _RenderExplorerCotdCup() {
        int cId = explChallenge.val;
        int compId = explComp.val;
        TextHeading(_ExplorerCotdTitleStr(), true, ResetCotdCupButton);
        auto mapInfo = CotdTreeYMD();
        string mapUid = mapInfo.mapUid;
        string seasonUid = mapInfo.seasonUid;

        int tabBarFlags = UI::TabBarFlags::NoCloseWithMiddleMouseButton;
        UI::BeginTabBar("cotd-tabs-" + cId, tabBarFlags);
        if (UI::BeginTabItem("Qualifiers##" + cId)) {
            _DrawCotdQualiTabContents(mapUid, cId);
            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Division Results##" + compId)) {
            _DrawCotdDivisionResTabContents(compId);
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }

    void _DrawCotdQualiTabContents(const string &in mapUid, uint cId) {
        if (UI::BeginTable(UI_EXPLORER + "-cotdOuter", 5, TableFlagsStretch())) {
            // UI::TableSetupColumn("Nil", UI::TableColumnFlags::WidthFixed, 20.);
            UI::TableNextColumn();

            // UI::TableSetupColumn("Qualifying Times", UI::TableColumnFlags::WidthFixed, 320.);
            UI::TableNextColumn();
            TextHeading("Qualifiers");
            bool dlDone = _CotdQualiTimesTable(cId);

            // UI::TableSetupColumn("Nil", UI::TableColumnFlags::WidthFixed, 20.);
            UI::TableNextColumn();

            // UI::TableSetupColumn("Histogram", UI::TableColumnFlags::WidthFixed, 350.);
            UI::TableNextColumn();
            TextHeading("Histogram");
            _CotdQualiHistogram(mapUid, cId, dlDone);

            UI::EndTable();
        }
    }

    bool gotAllResultsForComp = false;
    uint gotAllResultsForCompId = 0;
    void _DrawCotdDivisionResTabContents(uint compId) {
        auto mapInfo = CotdTreeYMD();
        string mapUid = mapInfo.mapUid;
        // string seasonUid = mapInfo.seasonUid;
        bool gotRounds = mapDb.HaveRoundIdForCotdComp(compId);
        bool gotMatches = false, gotMatchResults = false;
        if (gotRounds) {
            auto round1 = mapDb.roundsDb.Get(mapDb.compsToRounds.Get(compId)[0]);
            gotMatches = mapDb.roundsToMatches.Exists(round1.id);
            if (gotMatches) {
                auto matchIds = mapDb.roundsToMatches.Get(round1.id);
                gotMatchResults = matchIds.Length == mapDb.matchResultsDb.Get(round1.id).CountExists(matchIds);
            }
        }

        if (UI::BeginTable(UI_EXPLORER + "-cotdCompOuter-" + compId, 5, TableFlagsStretch())) {
            UI::TableNextColumn();
            UI::TableNextColumn();
            TextHeading("Divisions");
            _CotdDivisionResultsTable(compId, gotRounds, gotMatches, gotMatchResults);

            UI::TableNextColumn();
            UI::TableNextColumn();
            TextHeading("View Division Results");
            if (!gotMatchResults) {
                UI::Text("Please download COTD match results first.");
            } else {
                _CotdDivisionsResultsButtons(compId);
            }
            UI::TableNextColumn();
            UI::EndTable();
        }
    }

    dictionary@ COTD_HISTOGRAM_DATA = dictionary();
    int lastHistGen;
    string histToShow;
    bool showHistogram;
    int nBuckets = 60;
    Histogram::HistData@ histData;
    int2 minMaxRank = int2(0, 0);
    uint[] rawScores;
    uint[] divCutoffs;
    uint lowRankFilter = 0, highRankFilter = 99999, histUpperRank = 99999;

    void _CotdQualiHistogram(const string &in mapUid, int cId, bool dlDone) {
        UI::Dummy(vec2());
        if (!PersistentData::MapTimesCached(mapUid, cId)) {
            UI::TextWrapped("Please download the qualifying times first.");
        } else {
            string key = mapUid + "--" + cId;
            bool isGenerated = COTD_HISTOGRAM_DATA.Exists(key);
            UI::Text("Generation Parameters:");
            nBuckets = UI::SliderInt('Number of bars', nBuckets, 10, Math::Max(200, divCutoffs.Length * 8));
            highRankFilter = Math::Min(histUpperRank, highRankFilter);
            int upperRankLimit = Math::Min(histUpperRank, highRankFilter);
            lowRankFilter = UI::SliderInt('Exclude Ranks Below', lowRankFilter, 0, upperRankLimit);
            highRankFilter = UI::SliderInt('Exclude Ranks Above', highRankFilter, lowRankFilter, histUpperRank);
            bool _disabled = Time::Now - lastHistGen < 1000;
            _disabled = _disabled || !dlDone;
            // generate histogram data
            if (MDisabledButton(_disabled, (isGenerated ? "Reg" : "G") + "enerate Histogram Data")) {
                // todo
                lastHistGen = Time::Now;
                histToShow = key;
                showHistogram = true;
                startnew(_GenHistogramData);
            }
            if (isGenerated && showHistogram) {
                auto histData = cast<Histogram::HistData>(COTD_HISTOGRAM_DATA[key]);
                uint pad = 40;
                auto wPos = UI::GetWindowPos();
                auto wSize = UI::GetWindowSize();
                screenRes = vec2(Draw::GetWidth(), Draw::GetHeight());
                vec2 newPos = vec2(wPos.x + wSize.x + pad, wPos.y) / screenRes;
                vec2 newSize = vec2(wSize.x, Math::Min(wSize.x, wSize.y) / 2.) / screenRes;
                Histogram::Draw(
                    newPos, newSize, minMaxRank,
                    histData,
                    histBarColor,
                    Histogram::TimeXLabelFmt,
                    histGetDiv,
                    vec4(.1, .1, .1, .98)
                );
                if (UI::Button("Hide Histogram")) {
                    showHistogram = false;
                }
                UI::TextWrapped(c_brightBlue + 'Note: the histogram will appear on the right of this window. It might be underneath other OpenPlanet windows (if you have any open).');
            } else if (isGenerated) {
                if (UI::Button("Show Histogram")) {
                    showHistogram = true;
                }
            }

            VPad();
            if (nBuckets > 180) {
                UI::TextWrapped('\\$ec2' + "Caution: histograms with many bars may increase frame times.");
            }
        }
    }

    const float HistHueDegreesPerDiv = 87;
    // const float HistHueDegreesPerDiv = 193;

    vec4 histBarColor(uint x, float halfBucketWidth) {
        // debug("histBarColor, x=" + x);
        uint colTime = x;
        // uint div = 1;
        // for (uint i = 0; i < divCutoffs.Length; i++) {
        //     if (divCutoffs[i] >= colTime) {
        //         div = i;
        //         break;
        //     }
        // }
        uint div = histGetDiv(x);
        float h = 15 + (HistHueDegreesPerDiv * float(div)) % 360.;
        Color@ c = Color(vec3(h, 60, 50), ColorTy::HSL);
        return c.rgba(1);
    }

    uint histGetDiv(uint xScore) {
        uint div = 0;
        for (uint i = 0; i < divCutoffs.Length; i++) {
            if (divCutoffs[i] >= xScore) {
                div = i + 1;
                break;
            }
        }
        if (div == 0) div = divCutoffs.Length + 1;
        return div;
    }

    void _GenHistogramData() {
        string key = histToShow;
        auto parts = key.Split('--');
        string mapUid = parts[0];
        int cId = Text::ParseInt(parts[1]);
        auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
        uint nPlayers = jb.j['nPlayers'];
        uint chunkSize = jb.j['chunkSize'];
        if (histUpperRank > 90000) highRankFilter = uint(Math::Floor(nPlayers * .97));
        histUpperRank = nPlayers;
        rawScores = array<uint>();
        divCutoffs = array<uint>();
        uint minR = 99999, maxR = 1, rank, score, lastScore;
        bool isLast;
        for (uint i = 1; i <= nPlayers; i += chunkSize) {
            auto times = jb.j['ranges']['' + i];
            for (uint j = 0; j < times.Length; j++) {
                isLast = i == nPlayers && j + 1 == times.Length;
                score = times[j]['score'];
                rank = times[j]['rank'];
                if ((rank % 64 == 0 || isLast)) {
                    divCutoffs.InsertLast(score);
                }
                if (rank <= lowRankFilter || rank > highRankFilter) continue;
                rawScores.InsertLast(score);
                minR = Math::Min(minR, rank);
                maxR = Math::Max(maxR, rank);
                lastScore = score;
            }
        }
        logcall("_GenHistogramData", "div cutoffs: " + string::Join(ArrayUintToString(divCutoffs), ", "));
        minMaxRank = int2(minR, maxR);
        @histData = Histogram::RawDataToHistData(rawScores, nBuckets);
        @COTD_HISTOGRAM_DATA[key] = histData;
    }


    int lastCidDownload = -1;
    CacheQualiTimes@ qtCache = CacheQualiTimes();

    bool _CotdQualiTimesTable(int cId) {
        auto mapInfo = CotdTreeYMD();
        string mapUid = mapInfo.mapUid;
        // string seasonUid = mapInfo.seasonUid;
        bool gotTimes = PersistentData::MapTimesCached(mapUid, cId);
        bool canDownload = !(gotTimes || lastCidDownload == cId);
        bool dlDone = false;

        if (UI::BeginTable(UI_EXPLORER + "-cotdStatus", 2, TableFlagsFixed())) {
            /* map times */
            DrawAs2Cols("Challenge ID:", Text::Format("%d", cId));
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text("Qualifying Times:");
            UI::TableNextColumn();
            if (canDownload) {
                if (UI::Button("Download")) {
                    lastCidDownload = cId;
                    mapDb.QueueMapChallengeTimesGet(mapUid, cId);
                }
            } else {
                UI::AlignTextToFramePadding();
                if (!gotTimes) {
                    UI::Text("Downloading...");
                } else {
                    dlDone = _DrawCotdTimesDownloadStatus(mapUid, cId);
                }
            }
            /* other status things? */
            if (dlDone) {
                if (qtCache.cId != uint(cId)) {
                    qtCache.SetCache(mapUid, uint(cId));
                }
                // auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
                int nPlayers = qtCache.nPlayers;
                // UI::TableNextRow();
                // DrawAs2Cols("Total Players", '' + nPlayers);
                UI::TableNextRow();
                DrawAs2Cols("Total Divisions:", '' + Text::Format("%.1f", nPlayers / 64.));
                UI::TableNextRow();
                DrawAs2Cols("Last Div:", Text::Format("%d", (nPlayers - 1) % 64 + 1) + " Players");
            }
            UI::EndTable();
        }

        if (dlDone) {
            VPad();

            /* Top times:     [show all] */
            UI::BeginTable('cotd-times-and-show-all', 2, TableFlagsStretchSame());

            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            TextSubheading("Top Times:");

            UI::TableNextColumn();
            if (UI::Button((w_AllCotdQualiTimes.IsVisible() ? "Hide" : "Show") + " All Times")) {
                WAllTimes::SetParams(mapUid, cId);
                w_AllCotdQualiTimes.Toggle();
            }

            UI::EndTable();

            VPad();
            if (UI::BeginTable(UI_EXPLORER + "-cotdRecords", 4, TableFlagsFixed())) {
                _DrawCotdTimesTableColumns(mapUid, cId);
                UI::EndTable();
            }
        }

        return dlDone;
    }

    uint pressedForceDownload = 0;
    bool _DrawCotdTimesDownloadStatus(const string &in mapUid, int cId) {
        auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
        float nPlayers = jb.j['nPlayers'];
        if (nPlayers == 0) {
            UI::TableNextColumn();
            UI::Dummy(vec2(300, 1));
            UI::TextWrapped("\\$fa4" + "Warning: nPlayers == 0");
            if (jb.j.HasKey('error')) {
                string k = string(jb.j['error']);
                TextWithCooldown("Error message: " + k, k, k, "\\$f41");
            } else {
                if (MDisabledButton(Time::Now < pressedForceDownload + 2000, "Force Retry Download")) {
                    pressedForceDownload = Time::Now;
                    mapDb.QueueMapChallengeTimesGet(mapUid, cId, true);
                }
            }
            return false;
        }
        int chunksDone = jb.j['ranges'].Length;
        float chunkSize = jb.j['chunkSize'];
        int expected = int(Math::Ceil(nPlayers / chunkSize));
        bool dlDone = expected == chunksDone;
        float nDone = chunksDone * chunkSize;
        float pctDone = nDone / nPlayers * 100.;
        if (!dlDone) {
            UI::Text('' + int(nDone) + ' / ' + nPlayers + ' (' + Text::Format("%4.1f", pctDone) + ' %)');
        } else {
            UI::Text('' + nPlayers);
        }
        return dlDone;
    }

    void _DrawCotdTimesTableColumns(const string &in mapUid, int cId) {
        for (uint i = 0; i < qtCache.Length; i++) {
            _DrawCotdTimeTableRow(qtCache.GetRow(i));
        }
    }

    int copiedCooldownSince = 0;
    int copiedCooldownMs = 1250;
    int cooldownDelta = 0;
    string lastCopiedPid;

    bool ShowCooldown(const string &in key) {
        cooldownDelta = Time::Now - copiedCooldownSince;
        return lastCopiedPid == key && cooldownDelta < copiedCooldownMs;
    }

    string CooldownHLColor(const string &in key, const string &in defaultColor = "\\$fff", bool escape = true) {
        return ShowCooldown(key)
            ? maniaColorForCooldown(cooldownDelta, copiedCooldownMs, escape)
            : defaultColor;
    }

    void TextWithCooldown(const string &in label, const string &in toCopy, const string &in key, const string &in defaultColor = "\\$fff", const string &in tooltipText = "Click to copy") {
        string hl = CooldownHLColor(key, defaultColor, true);
        UI::TextWrapped(hl + label);
        if (UI::IsItemClicked()) {
            trace("Copying to clipboard: " + toCopy);
            IO::SetClipboard(toCopy);
            lastCopiedPid = key;
            copiedCooldownSince = Time::Now;
        }
        if (tooltipText.Length > 0)
            AddSimpleTooltip(tooltipText);
    }

    void _DrawCotdTimeTableRow(array<string> &in row) {
        UI::TableNextColumn();
        UI::Text(row[0]);
        UI::TableNextColumn();
        UI::Text(row[1]);
        UI::TableNextColumn();
        if (row[0] != "1")
            UI::Text(row[2]);
        UI::TableNextColumn();
        // todo player name
        string pid = row[3];
        if (pid.Length > 10) {
            PlayerNames::Get(pid).Draw();
        }
        UI::TableNextRow();
    }

    void _CotdDivisionsResultsButtons(uint compId) {
        auto matchIds = mapDb.GetMatchIdsForCotdComp(compId);
        // auto roundId = mapDb.GetRoundIdForCotdComp(compId);
        if (UI::BeginTable(UI_EXPLORER + "-cotdDivBtns", 5, TableFlagsStretchSame())) {
            for (uint i = 0; i < matchIds.Length; i++) {
                UI::TableNextColumn();
                if (UI::Button("Div " + (i + 1), vec2(58, 26))) {
                    startnew(WAllTimes::PopulateCache);  // recache all times so that rank deltas work
                    WAllDivResults::SetParams(compId, FilterAll('', i + 1));
                    w_AllCotdDivResults.Show();
                }
                UI::Dummy(vec2(0,0));
            }
            UI::EndTable();
        }
    }

    void _CotdDivisionResultsTable(uint compId, bool gotRounds, bool gotMatches, bool gotMatchResults) {
        if (UI::BeginTable(UI_EXPLORER + "-cotdResults##"+compId, 2, TableFlagsFixed())) {
            DrawAs2Cols("Competition ID:", '' + compId);
            if (gotRounds)
                DrawAs2Cols("Round ID:", '' + mapDb.GetRoundIdForCotdComp(compId));
            if (!gotMatchResults) {
                UI::TableNextColumn();
                UI::AlignTextToFramePadding();
                UI::Text("# Matches");
                UI::TableNextColumn();
                _DrawCompRoundMatchesStatus(compId, gotRounds, gotMatches, gotMatchResults);
            } else {
                _DrawCompInfos(compId);
            }
            // rounds
            // -> matches
            // don't have rounds/matches -> download button
            // got rounds but not matches -> ??
            // got both -> draw stuff
            // n matches
            // winning time of each match? don't have this right
            // just players and positions
            // stats: avg movement of place?
            UI::EndTable();
        }
        if (!gotMatchResults) return;
        auto matchIds = mapDb.GetMatchIdsForCotdComp(compId);
        auto roundId = mapDb.GetRoundIdForCotdComp(compId);
        uint drawTopN = 10;
        uint drawBotN = 2;
        bool wk = true;  // winner known

        if (UI::BeginTable(UI_EXPLORER + "-cotdTopDivWinners##"+compId, 2, TableFlagsFixed())) {

            UI::TableNextColumn();
            UI::PushFont(subheadingFont);
            UI::AlignTextToFramePadding();
            UI::Text("Division Winners:");
            UI::PopFont();

            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            if (UI::Button("Show All Results")) {
                startnew(WAllTimes::PopulateCache);
                WAllDivResults::SetParams(compId);
                w_AllCotdDivResults.Show();
            }
            UI::TableNextRow();
            DrawAs2Cols("", "");

            for (uint i = 0; i < uint(Math::Min(drawTopN, matchIds.Length)); i++) {
                wk = DrawDivResultsRowForMatch(roundId, matchIds[i]) && wk; // do && with wk after calling function.
            }
            if (matchIds.Length > drawTopN + drawBotN) {
                DrawAs2Cols("...", "");
            }
            // todo, check nonvisible divs too.
            uint lastDivsStart = Math::Max(drawTopN, matchIds.Length - drawBotN);
            for (uint i = lastDivsStart; i < matchIds.Length; i++) {
                wk = DrawDivResultsRowForMatch(roundId, matchIds[i]) && wk; // do && with wk after calling function.
            }
            UI::EndTable();

            if (!wk) {
                VPad();
                if (MDisabledButton(lastCompIdDlClick == int(compId), "Re-download Results")) {
                    RedownloadRounds(compId);
                }
            }
        }
    }

    PlayerName@ UnkWinnerPlayerName = PlayerName(c_orange_600 + "Unknown Winner", "", false);
    // returns whether the winner was known or not
    bool DrawDivResultsRowForMatch(uint roundId, uint matchId) {
        auto match = mapDb.matchesDb.Get(matchId);
        auto mResults = mapDb.matchResultsDb.Get(roundId).Get(matchId);
        auto winner = mResults.results[0];
        bool matchDone = winner.rank.IsSome();
        PlayerName@ name = matchDone
            ? PlayerNames::Get(winner.participant)
            : UnkWinnerPlayerName;
        DrawAs2Cols("Div " + (match.position + 1), name.Draw);
        UI::TableNextRow();
        return winner.rank.IsSome();
    }


    int lastCompIdDlClick = -1;
    void _DrawCompRoundMatchesStatus(uint compId, bool gotRounds, bool gotMatches, bool gotMatchResults) {
        if (gotMatchResults) {
            UI::Text("All results data downloaded for: " + compId);
        } else if (gotRounds || lastCompIdDlClick == int(compId)) {
            if (gotMatches) {
                UI::Text("Downloaded rounds info.");
                UI::Text("Downloaded matches info.");
                auto matchIds = mapDb.GetMatchIdsForCotdComp(compId);
                auto roundId = mapDb.GetRoundIdForCotdComp(compId);
                UI::Text("Downloading match results: " + mapDb.matchResultsDb.Get(roundId).CountExists(matchIds) + " / " + matchIds.Length);
            } else if (gotRounds) {
                UI::Text("Downloaded rounds.");
                UI::Text("Downloaded matches info...");
            } else {
                UI::Text("Downloading rounds info...");
            }
        } else if (UI::Button("Download Matches Data")) {
            DownloadComp(compId);
            startnew(OnDownloadedComp);
        }
    }

    void DownloadComp(uint compId) {
        lastCompIdDlClick = int(compId);
        mapDb.QueueCompRoundsGet({compId});
    }

    void OnDownloadedComp() {
        sleep(1000); // allow enough time for things to happen
        // todo: wait for downloads and then regen results
        // todo: why not download both quali times and div results when someone selectes a cup #?
        // todo: like that makes sense, what else where they going to do?
    }

    void RedownloadRounds(uint compId) {
        lastCompIdDlClick = int(compId);
        auto roundId = mapDb.GetRoundIdForCotdComp(compId);
        mapDb.matchResultsDb.Get(roundId).DeleteAll();
        mapDb.QueueCompMatchResultsGet(roundId, mapDb.GetMatchIdsForCotdComp(compId));
    }


    void _DrawCompInfos(uint compId) {
        auto matchIds = mapDb.GetMatchIdsForCotdComp(compId);
        DrawAs2Cols("# Matches:", '' + matchIds.Length);
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

    void _RenderTestHistogram() {
        auto hData = DataManager::cotd_HistogramData;
        if (hData !is null) {
            float[] data = array<float>(hData.ys.Length);
            for (uint i = 0; i < hData.ys.Length; i++) {
                data[i] = float(hData.ys[i]);
            }
            UI::PlotHistogram('asdf', data, 0, 40.);
        }
    }
}
