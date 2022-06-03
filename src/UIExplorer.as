
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

    BoolWP@ windowActive = BoolWP(false);
    string icon = Icons::AreaChart;
    HistoryDb@ histDb;  /* instantiated in PersistentData */
    MapDb@ mapDb;  /* instantiated in PersistentData */
    vec2 gameRes;
    vec2 calendarDayBtnDims;
    vec2 calendarMonthBtnDims;
    const vec2 mapThumbDims = vec2(256, 256);

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
#if DEV
        windowActive.v = true;
#endif
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
        if (windowActive.ChangedToTrue()) {
            UI::SetNextWindowSize(730, 1000, UI::Cond::Always);
            windowActive.v = true;
        }
        UI::Begin(ExplorerWindowTitle, windowActive.v);

        if (UI::IsWindowAppearing()) {
            UI::SetWindowSize(vec2(730, 1000), UI::Cond::Always);
            _ResetExplorerCotdSelection();
            _DevSetExplorerCotdSelection();
            startnew(LoadCotdTreeFromDb);
        }

        if (cotdYMDMapTree is null || cotdYMDMapTree.GetKeys().Length == 0) {
            _RenderExplorerLoading();
        } else {
            _RenderExplorerCotdSelection();
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
        while (cotdYMDMapTree is null || cotdYMDMapTree.GetSize() == 0) {
            sleep(200);
            @cotdYMDMapTree = histDb.GetCotdYearMonthDayMapTree();
        }
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
        DrawAsRow(_ExplorerBreadcrumbs, UI_EXPLORER + "-breadcrumbs", 7);
    }

    /* the function that's passed in is meant to be run before each chunk of UI elements */
    void _ExplorerBreadcrumbs(DrawUiElems@ f) {
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
        if (level <= 4) explQDiv.AsNothing();
        if (level <= 5) explMatch.AsNothing();
        resetLevel = 0;  /* always reset this to be 0 afterwards so unprepped calls to _Reset do something sensible. */
    }

    void _DevSetExplorerCotdSelection() {
        explYear.AsJust(2022);
        explMonth.AsJust(4);
        explDay.AsJust(1);
        // explCup.AsJust(2);
        // explQDiv.AsJust(1);
        // explMatch.AsJust(1);
    }

    void _RenderExplorerCotdSelection() {
        ExplorerBreadcrumbs();
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

    int TableFlagsFixed() {
        return UI::TableFlags::SizingFixedFit;
    }
    int TableFlagsFixedSame() {
        return UI::TableFlags::SizingFixedSame;
    }
    int TableFlagsStretch() {
        return UI::TableFlags::SizingStretchProp;
    }

    void _RenderExplorerCotdYearSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Year");
        // UI::BeginTable(UI_EXPLORER + "-yrs");
        auto yrs = cotdYMDMapTree.GetKeys();
        yrs.SortAsc();
        if (UI::BeginTable(UI_EXPLORER + "-y-table", 6, TableFlagsFixedSame())) {
            for (uint i = 0; i < yrs.Length; i++) {
                UI::TableNextColumn();
                string yr = yrs[i];
                if (UI::Button(yr, calendarMonthBtnDims)) {
                    explYear.AsJust(Text::ParseInt(yr));
                }
            }
            UI::EndTable();
        }

    }

    void _RenderExplorerCotdMonthSelection() {
        TextHeading(_ExplorerCotdTitleStr() + " | Select Month");
        auto md = cast<dictionary@>(cotdYMDMapTree["" + explYear.val]);
        auto months = md.GetKeys();
        months.SortAsc();
        uint month;
        int _offs = (Text::ParseInt(months[0]));  // 2 rows of 6 months
        int _last = Text::ParseInt(months[months.Length - 1]);
        int _nMonths = months.Length;
        bool _disable;
        if (UI::BeginTable(UI_EXPLORER + "-ym-table", 6, TableFlagsFixedSame())) {
            for (int x = 1; x <= 12; x++) {
                UI::TableNextColumn();
                _disable = x < _offs || x - _offs >= _nMonths;
                if (MDisabledButton(_disable, MONTH_NAMES[x], calendarMonthBtnDims)) {
                    OnSelectedCotdMonth(x);
                }
            }
            UI::EndTable();
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
        if (UI::BeginTable(UI_EXPLORER + "-ymd-table", 7, TableFlagsFixedSame())) {
            // UI::TableNextRow();
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
        dictionary@ month = CotdTreeYM();
        auto keys = month.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto day = cast<JsonBox@>(month[keys[i]]);
            mapDb.QueueMapGet(day.j['mapUid']);
        }
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
        string seasonUid = day.j['seasonUid'];
        mapDb.QueueMapGet(uid);
        mapDb.QueueMapRecordGet(seasonUid, uid);
    }

    void DrawTotdMapInfoTable(Json::Value map, const string &in totdDate) {
        string tnUrl = map['ThumbnailUrl'];
        string authorName = map['AuthorDisplayName'];
        string authorScore = Time::Format(map['AuthorScore']);
        string mapName = map['Name'];
        mapName = EscapeRawToOpenPlanet(MakeColorsOkayDarkMode(mapName));
        mapName += " \\$z(TOTD for " + totdDate + ")";
        TextHeading(mapName);
        if (UI::BeginTable(UI_EXPLORER + '-mapInfo', 2, TableFlagsStretch())) {
            UI::TableNextColumn();
            UI::Text(EscapeRawToOpenPlanet("Mapper: " + authorName));
            UI::Text("Author Time: " + authorScore);
            DrawMapRecordsOrLoading(map['Uid']);

            UI::TableNextColumn();
            _DrawThumbnail(tnUrl, true, 1.0);
            DrawMapThumbnailBigTooltip(tnUrl);

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
        DrawTotdMapInfoTable(mapDb.GetMap(mapInfo.j['mapUid']), SelectedCotdDateStr());
        PaddedSep();
        /* either select cup or draw cup info */
        if (explCup.isNone) {
            _RenderExplorerCotdCupSelection();
        } else {
            // UI::Text('' + explChallenge.val);
            _RenderExplorerCotdCup();
        }
    }

    const string[] COTD_BTNS = { "1st (COTD) @ 7pm CEST/CET", "2nd (COTN) @ 3am CEST/CET", "3rd (COTM) @ 11am CEST/CET" };

    void _RenderExplorerCotdCupSelection() {
        auto cIds = CotdChallengesForSelectedDate();
        JsonBox@ totdInfo = CotdTreeYMD();
        string mapUid = totdInfo.j['mapUid'];
        if (cIds.Length == 0) {
            UI::Text("\\$f81 Warning: cannot find challengeIds for COTDs on " + SelectedCotdDateStr() + "; nChallenges=" + cIds.Length);
        } else {
            TextHeading(_ExplorerCotdTitleStr() + " | Select Cup");
            string btnLab;
            for (int i = 0; i < Math::Min(cIds.Length, COTD_BTNS.Length); i++) {
                auto c = histDb.GetChallenge(cIds[i]);
                if (c['startDate'] < Time::Stamp) {
                    btnLab = COTD_BTNS[i];
                    int cotdNum = btnLab[0] - 48;  /* '1' = 49; 49 - 48 = 1. (ascii char value - 48 = int value); */
                    if (UI::Button(btnLab)) {
                        OnSelectedCotdChallenge(cotdNum, mapUid, cIds[i]);
                    }
                }
            }
        }
    }

    void OnSelectedCotdChallenge(int cotdNum, const string &in mapUid, int cId) {
        explCup.AsJust(cotdNum);
        explChallenge.AsJust(cId);
        startnew(EnsurePlayerNames);
    }

    void EnsurePlayerNames() {
        int cId = explChallenge.val;
        JsonBox@ totdInfo = CotdTreeYMD();
        string mapUid = totdInfo.j['mapUid'];
        if (PersistentData::MapTimesCached(mapUid, cId)) {
            auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
            int nPlayers = jb.j['nPlayers'];
            int chunkSize = jb.j['chunkSize'];
            string[] playerIds = array<string>(nPlayers);
            string[] keys = jb.j['ranges'].GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                auto times = jb.j['ranges'][keys[i]];
                for (uint j = 0; j < times.Length; j++) {
                    playerIds[i * chunkSize + j] = times[j]['player'];
                }
            }
            mapDb.QueuePlayerNamesGet(playerIds);
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

    int[] CotdChallengesForSelectedDate() {
        return mapDb.GetChallengesForDate('' + explYear.val, Text::Format("%02d", explMonth.val), Text::Format("%02d", explDay.val));
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
            _CotdQualiTimesTable(cId);

            // UI::TableSetupColumn("Nil", UI::TableColumnFlags::WidthFixed, 20.);
            UI::TableNextColumn();

            // UI::TableSetupColumn("Histogram", UI::TableColumnFlags::WidthFixed, 350.);
            UI::TableNextColumn();
            TextHeading("Histogram");
            _CotdQualiHistogram(mapUid, cId);

            UI::EndTable();
        }
    }

    dictionary@ COTD_HISTOGRAM_DATA = dictionary();
    int lastHistGen;
    string histToShow;
    int nBuckets = 60;

    void _CotdQualiHistogram(const string &in mapUid, int cId) {
        UI::Dummy(vec2());
        if (!PersistentData::MapTimesCached(mapUid, cId)) {
            UI::TextWrapped("Please download the qualifying times first.");
        } else {
            string key = mapUid + "--" + cId;
            bool isGenerated = COTD_HISTOGRAM_DATA.Exists(key);
            UI::Text("Generation Parameters:");
            nBuckets = UI::SliderInt('Number of bars', nBuckets, 10, 200);
            if (MDisabledButton(Time::Now - lastHistGen > 1000, (isGenerated ? "Reg" : "G") + "enerate Histogram Data")) {
                // todo
                lastHistGen = Time::Now;
                histToShow = key;
            }
            if (isGenerated) {
                auto histData = cast<Histogram::HistData>(COTD_HISTOGRAM_DATA[key]);

            }
        }
    }

    int lastCidDownload = -1;

    void _CotdQualiTimesTable(int cId) {
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
                    //startnew(CoroutineFunc(mapDb._GetOneCotdMapTimes));
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
            }
            UI::EndTable();
        }

        if (dlDone) {
            VPad();
            UI::PushFont(subheadingFont);
            UI::Text("Times:");
            UI::PopFont();
            VPad();
            if (UI::BeginTable(UI_EXPLORER + "-cotdRecords", 4, TableFlagsFixed())) {
                _DrawCotdTimesTableColumns(mapUid, cId);
                UI::EndTable();
            }
        }
    }

    bool _DrawCotdTimesDownloadStatus(const string &in mapUid, int cId) {
        auto jb = PersistentData::GetCotdMapTimes(mapUid, cId);
        float nPlayers = jb.j['nPlayers'];
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

    void _DrawCotdTimeTableRow(Json::Value time, int topScore) {
        int rank = time['rank'];
        int score = time['score'];
        UI::TableNextColumn();
        UI::Text('' + rank);
        UI::TableNextColumn();
        UI::Text(Time::Format(score));
        UI::TableNextColumn();
        if (rank > 1)
            UI::Text(c_timeOrange + "+" + Time::Format(score - topScore));
        UI::TableNextColumn();
        // todo player name
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
