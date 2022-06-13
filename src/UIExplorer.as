Debouncer@ debounce = Debouncer();
GameInfo gi = GameInfo();

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
#if DEV
        windowActive.v = true;
#endif
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
        if (UI::MenuItem(c_menuIconColor + icon + "\\$z COTD Explorer", "", IsVisible())) {
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
            UI::SetNextWindowSize(730, 1100, UI::Cond::Always);
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

        if (cotdYMDMapTree is null || cotdYMDMapTree.GetKeys().Length == 0) {
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

    void _RenderExplorerLoading() {
        UI::Text("Loading Initial Data...");
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
        if (UI::BeginChild( "-breadcrumbsOuter", vec2(0, 40))) {
            UI::Dummy(vec2(1, 0));
            DrawAsRow(_ExplorerBreadcrumbs, UI_EXPLORER + "-breadcrumbs", 7);
            UI::EndChild();
        }
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
        if (IsJsonNull(map)) return;
        if (UI::IsItemHovered()) {  /* && PersistentData::ThumbnailCached(tnUrl) */
            // UI::PushStyleColor(UI::Col::PopupBg, vec4(.2, .2, .2, .4));
            UI::BeginTooltip();
            DrawMapInfo(map, false, true, 1.0);
            UI::EndTooltip();
            // UI::PopStyleColor(1);
        }
    }

    void DrawMapInfo(Json::Value map, bool isTitle = false, bool drawThumbnail = true, float thumbnailSizeRel = 1.0) {
        string tnUrl = map['ThumbnailUrl'];
        string authorName = map['AuthorDisplayName'];
        string authorScore = Time::Format(map['AuthorScore']);
        string mapName = map['Name'];
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
                    explYear.AsJust(Text::ParseInt(yr));
                }
                if ((i + 1) % 3 == 0) {
                    UI::TableNextColumn();
                    UI::TableNextColumn(); /* new row */
                }
            }
            UI::EndTable();
        }

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
        JsonBox@ map1 = cast<JsonBox@>(dd[days[0]]);
        JsonBox@ map;
        uint dayOffset = map1.j["day"];  /* .monthDay is the calendar day number (1-31); .day is 0-6 */
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
                @map = cast<JsonBox@>(dd[day]);
                if (map is null || IsJsonNull(map.j['mapUid'])) continue;
                string mapUid = map.j['mapUid'];
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
        explDay.AsJust(day);
        startnew(EnsureMapDataForCurrDay);
    }

    void EnsureMapDataForCurrMonth() {
        EnsureMapDataForYM('', '');
        // dictionary@ month = CotdTreeYM();
        // auto keys = month.GetKeys();
        // for (uint i = 0; i < keys.Length; i++) {
        //     auto day = cast<JsonBox@>(month[keys[i]]);
        //     mapDb.QueueMapGet(day.j['mapUid']);
        // }
    }

    void EnsureMapDataForYM(const string &in year, const string &in month) {
        // auto mo = cast<dictionary>(cast<dictionary>(cotdYMDMapTree[year])[month]);
        auto mo = CotdTreeYM(year, month);
        auto keys = mo.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto day = cast<JsonBox@>(mo[keys[i]]);
            // mapDb.QueueMapGet(day.j['mapUid']);
            EnsureMapDataForYMD(year, month, keys[i]);
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
    }

    void EnsureMapDataForYMD(const string &in _year, const string &in _month, const string &in _day) {
        JsonBox@ day = CotdTreeYMD(_year, _month, _day);
        if (day is null) return;
        string uid = day.j['mapUid'];
        if (uid.Length == 0) return;
        string seasonUid = day.j['seasonUid'];
        if (seasonUid.Length == 0) return;
        string endTs = day.j.Get('end', "1234");
        auto cIds = CotdChallengesForYMD(_year, _month, _day);
        mapDb.QueueMapGet(uid);
        mapDb.QueueMapRecordGet(seasonUid, uid, endTs);
        // for (uint i = 0; i < cIds.Length; i++) {

        // }
    }

    bool HaveAllMapDataForYMD(const string &in _year, const string &in _month, const string &in _day) {
        JsonBox@ day = CotdTreeYMD(_year, _month, _day);
        if (day is null) return true;
        string uid = day.j['mapUid'];
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

    void DrawTotdMapInfoTable(Json::Value map, const string &in seasonId, const string &in totdDate) {
        if (IsJsonNull(map)) {
            TextBigStrong("\\$fa4" + "Map is not found, it might be in the download queue.");
            DrawMapDownloadProgress();
            return;
        }
        string mapUid = map['Uid'];
        string tnUrl = map['ThumbnailUrl'];
        string authorId = map['AuthorWebServicesUserId'];
        string authorScore = Time::Format(map['AuthorScore']);
        string authorName = map['AuthorDisplayName'];
        string authorNameAndId = authorName + " " + authorId;
        // apply special after setting authorNameAndId
        if (IsSpecialPlayerId(authorId)) authorName = rainbowLoopColorCycle(authorName, true);
        string mapName = map['Name'];
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
            TextWithCooldown("Mapper: " + authorName, authorNameAndId, authorId, "\\$fff", "Click to copy author's Name and ID");
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
                gi.GetMainaTitleControlScriptAPI().PlayMap(wstring(string(map['FileUrl'])), '', '');
            };
            UI::PopFont();

            // TMX: /api/maps/get_map_info/uid/{id}
            ButtonLink("TMX", "https://trackmania.exchange/mapsearch2?trackname=" + origMapName);
            UI::SameLine();
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
        DrawTotdMapInfoTable(mapDb.GetMap(mapInfo.j['mapUid']), mapInfo.j['seasonUid'], SelectedCotdDateStr());
        PaddedSep();
        /* either select cup or draw cup info */
        if (explCup.isNone) {
            _RenderExplorerCotdCupSelection();
        } else {
            // UI::Text('' + explChallenge.val);
            _RenderExplorerCotdCup();
        }
    }

    const string[] COTD_BTNS = { "1st (COTD)\n7pm CEST/CET", "2nd (COTN)\n3am CEST/CET", "3rd (COTM)\n11am CEST/CET" };


    int[] challengeIdsForSelectedCotd = {};
    void _RenderExplorerCotdCupSelection() {
        // auto cIds = CotdChallengesForSelectedDate();
        auto cIds = challengeIdsForSelectedCotd;
        JsonBox@ totdInfo = CotdTreeYMD();
        string mapUid = totdInfo.j['mapUid'];
        bool _disabled = false;
        if (cIds.Length == 0) {
            UI::Text("\\$f81 Warning: cannot find challengeIds for COTDs on " + SelectedCotdDateStr() + "; nChallenges=" + cIds.Length);
            DrawChallengeDownloadProgress();
        } else {
            TextHeading(_ExplorerCotdTitleStr() + " | Select Cup");
            string btnLab;
            UI::PushStyleVar(UI::StyleVar::ButtonTextAlign, vec2(.5, .5));
            if (UI::BeginTable(UI_EXPLORER + "-tableChooseCId", 5, TableFlagsStretch())) {
                UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
                for (uint i = 0; i < 3; i++) UI::TableSetupColumn("" + i, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);

                UI::TableNextColumn();
                for (int i = 0; i < Math::Min(cIds.Length, COTD_BTNS.Length); i++) {
                    auto c = histDb.GetChallenge(cIds[i]);
                    if (!IsJsonNull(c)) {
                        _disabled = Text::ParseInt(c['endDate']) >= Time::Stamp;
                        btnLab = COTD_BTNS[i];
                        int cotdNum = i+1; // btnLab[0] - 48;  /* '1' = 49; 49 - 48 = 1. (ascii char value - 48 = int value); */
                        UI::TableNextColumn();
                        if (MDisabledButton(_disabled, btnLab, challengeBtnDims)) {
                            OnSelectedCotdChallenge(cotdNum, mapUid, cIds[i]);
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

    void OnSelectedCotdChallenge(int cotdNum, const string &in mapUid, int cId) {
        explCup.AsJust(cotdNum); // selection params
        explChallenge.AsJust(cId);
        lastCidDownload = -1; // reset download button
        startnew(EnsurePlayerNames); // get player names if we have times
        histToShow = mapUid + "--" + cId; // the histogram to show
        showHistogram = false;
        histUpperRank = highRankFilter = 99999; // rank filter defaults
        lowRankFilter = 0;
        if (PersistentData::MapTimesCached(mapUid, cId)) {
            startnew(_GenHistogramData); // proactively generate histograms where data is available
        }
        w_AllCotdQualiTimes.Hide(); // hide all times window if it's still around from a previous COTD
    }

    void EnsurePlayerNames() {
        int cId = explChallenge.val;
        JsonBox@ totdInfo = CotdTreeYMD();
        string mapUid = totdInfo.j['mapUid'];
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

    JsonBox@ _EmptyJsonBox = JsonBox(Json::Object());
    JsonBox@ CotdTreeYMD(const string &in year = '', const string &in month = '', string day = '') {
        if (day == '') day = Text::Format("%02d", explDay.val);
        JsonBox@ ret;
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

    void _DrawThumbnailWSize(Resources::Texture@ tex, float sizeMult) {
        UI::Image(tex, mapThumbDims * sizeMult);
    }

    void _RenderExplorerCotdCup() {
        int cId = explChallenge.val;
        TextHeading(_ExplorerCotdTitleStr());
        auto mapInfo = CotdTreeYMD();
        string mapUid = mapInfo.j['mapUid'];
        string seasonUid = mapInfo.j['seasonUid'];
        // auto map = mapDb.GetMap(mapUid);

        if (UI::BeginTable(UI_EXPLORER + "-cotdOuter", 4, TableFlagsStretch())) {
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

    void GenerateHistogramData(ref@ HistData) {

    }

    int lastCidDownload = -1;

    bool _CotdQualiTimesTable(int cId) {
        auto mapInfo = CotdTreeYMD();
        string mapUid = mapInfo.j['mapUid'];
        // string seasonUid = mapInfo.j['seasonUid'];
        bool gotTimes = PersistentData::MapTimesCached(mapUid, cId);
        bool canDownload = !(gotTimes || lastCidDownload == cId);
        bool dlDone = false;

        if (UI::BeginTable(UI_EXPLORER + "-cotdStatus", 2, TableFlagsFixed())) {
            /* map times */
            UI::TableNextColumn();
            UI::Dummy(vec2());
            UI::Text("Qualifying Times:");
            UI::TableNextColumn();
            if (canDownload) {
                if (UI::Button("Download")) {
                    lastCidDownload = cId;
                    mapDb.QueueMapChallengeTimesGet(mapUid, cId);
                }
            } else {
                UI::Dummy(vec2());
                if (!gotTimes) {
                    UI::Text("Downloading...");
                } else {
                    dlDone = _DrawCotdTimesDownloadStatus(mapUid, cId);
                }
            }
            /* other status things? */
            if (dlDone) {
                auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
                int nPlayers = jb.j['nPlayers'];
                // UI::TableNextRow();
                // DrawAs2Cols("Total Players", '' + nPlayers);
                UI::TableNextRow();
                DrawAs2Cols("Total Divisions:", '' + Text::Format("%.1f", nPlayers / 64.));
                UI::TableNextRow();
                DrawAs2Cols("Last Div:", Text::Format("%d", (nPlayers - 1) % 64 + 1) + " Players");
                DrawAs2Cols("Challenge ID:", Text::Format("%d", cId));
            }
            UI::EndTable();
        }

        if (dlDone) {
            VPad();

            /* Top times:     [show all] */
            UI::BeginTable('cotd-times-and-show-all', 2, TableFlagsStretchSame());

            UI::TableNextColumn();
            UI::PushFont(subheadingFont);
            UI::AlignTextToFramePadding();
            UI::Text("Top Times:");
            UI::PopFont();

            UI::TableNextColumn();
            if (UI::Button((w_AllCotdQualiTimes.IsVisible() ? "Hide" : "Show") + " All Times")) {
                WAllTimes::SetParams(mapUid, cId);
                w_AllCotdQualiTimes.Toggle();
                /* update the cache in a few seconds to account for getting player names if we needed to. */
                startnew(WAllTimes::CoroDelayedPopulateCache);
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
        auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
        float nPlayers = jb.j['nPlayers'];
        float chunkSize = jb.j['chunkSize'];
        uint drawNTopTimes = 10;
        auto times = jb.j['ranges']['1'];
        int lastChunkIx = int(Math::Floor((nPlayers - 1) / chunkSize) * chunkSize) + 1;
        auto lastTimes = jb.j['ranges']['' + lastChunkIx];
        // logcall('_DrawCotdTimesTableCOls', 'last times ix: ' + lastChunkIx + '; j=' + Json::Write(lastTimes));
        int topScore = times[0]['score'];
        for (uint i = 0; i < drawNTopTimes; i++) {
            _DrawCotdTimeTableRow(times[i], topScore);
        }
        UI::TableNextColumn();
        UI::Text("...");
        // UI::TableNextColumn();
        UI::TableNextRow();
        if (lastTimes.Length >= 2)
            _DrawCotdTimeTableRow(lastTimes[lastTimes.Length - 2], topScore);
        _DrawCotdTimeTableRow(lastTimes[lastTimes.Length - 1], topScore);
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

    void _DrawCotdTimeTableRow(Json::Value time, int topScore) {
        int rank = time['rank'];
        int score = time['score'];
        string pid = time['player'];
        UI::TableNextColumn();
        UI::Text('' + rank);
        UI::TableNextColumn();
        UI::Text(Time::Format(score));
        UI::TableNextColumn();
        if (rank > 1)
            UI::Text(c_timeOrange + "+" + Time::Format(score - topScore));
        UI::TableNextColumn();
        // todo player name
        bool nameExists = mapDb.playerNameDb.Exists(pid);
        string hl = CooldownHLColor(pid, nameExists ? "" : "\\$a42");
        string nameRaw = nameExists ? mapDb.playerNameDb.Get(pid) : "?? " + pid.Split('-')[0];
        string pName = IsSpecialPlayerId(pid)
            ? "\\$s" + rainbowLoopColorCycle(nameRaw, true)
            : hl + nameRaw;
        UI::Text(pName);
        if (UI::IsItemClicked()) {
            trace("Copying to clipboard: " + pid);
            IO::SetClipboard(pid);
            lastCopiedPid = pid;
            copiedCooldownSince = Time::Now;
        }
        if (!mapDb.playerNameDb.Exists(pid)) {
            AddSimpleTooltip("Player ID not found. Click to copy.");
        }
        UI::TableNextRow();
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
