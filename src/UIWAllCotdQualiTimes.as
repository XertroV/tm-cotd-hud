WindowState w_AllCotdQualiTimes('COTD Qualifying Times', false);

namespace WAllTimes {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    class Row {
        string rank;
        string time;
        string delta;
        string divDelta;
        string playerDelta;
        PlayerName@ player;
        bool isDivRow;
        Row(const string &in r, const string &in t, const string &in d, const string &in dd, const string &in pd, PlayerName@ p, bool divRow = false) {
            rank = r;
            time = t;
            delta = d;
            divDelta = dd;
            playerDelta = pd;
            @player = p;
            isDivRow = divRow;
        }
    }

    string filterName = 'doesnt work yet';
    string mapUid;  /* do not set directly */
    int cId;  /* do not set directly */
    Json::Value[] times;
    Row@[] cache_rows = array<Row@>();
    uint nPlayers = 0;
    uint nDivs = 0;
    string playerId;
    bool playerFound = false;
    uint playerRank = 0;
    string cotdTitleStr = "";

    void SetParams(const string &in _mapUid, int _cId) {
        mapUid = _mapUid;
        cId = _cId;
        times = PersistentData::GetCotdMapTimesAllJ(mapUid, cId);
        cotdTitleStr = CotdExplorer::_ExplorerCotdTitleStr();
        startnew(PopulateCache);
    }

    void PopulateCache() {
        playerId = GI::PlayersId();
        nPlayers = times.Length;
        // nDivs = uint(Math::Ceil(float(nPlayers) / 64.));
        nDivs = ((nPlayers - 1) >> 6) + 1; // faster and more elegant
        cache_rows.Resize(nPlayers + nDivs);
        uint bestTime = nPlayers > 0 ? times[0]['score'] : 0;
        string pid, name, _d;
        bool special;
        uint time, nDivsDone = 0, i, bestInDiv, thisDiv, playerScore = 0;
        playerFound = false;
        uint lastBreak = 0;
        for (uint _i = 0; _i < nPlayers; _i++) {
            if (Time::Now - lastBreak > 8) {
                yield();
                lastBreak = Time::Now;
            }
            i = _i + nDivsDone;
            time = uint(times[_i]['score']);
            if (_i % 64 == 0) {
                thisDiv = uint(Math::Ceil(float(_i) / 64. + 1));
                _d = "Div " + thisDiv;
                @cache_rows[i] = Row(c_brightBlue + 'Div ' + thisDiv, c_brightBlue + '------------', c_brightBlue + '------------', c_brightBlue + '------------', c_brightBlue + '------------', PlayerName(c_brightBlue + _d, '', false));
                nDivsDone++;
                i = _i + nDivsDone;
                bestInDiv = time;
            }
            pid = times[_i]['player'];
            @cache_rows[i] = Row('' + (_i + 1),
                Time::Format(time),
                time == bestTime ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - bestTime)),
                time == bestInDiv ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - bestInDiv)),
                '',
                PlayerName(pid));  // don't get cached player name here -- right click breaks
            if (playerFound) {
                cache_rows[i].playerDelta = time == playerScore ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - playerScore));
            }
            if (pid == playerId) {
                playerFound = true;
                playerScore = time;
                playerRank = _i + 1;
                cache_rows[i].playerDelta = '';
            }
        }

        if (playerFound) {
            nDivsDone = 0;
            for (uint _i = 0; _i < playerRank - 1; _i++) {
                time = uint(times[_i]['score']);
                i = _i + nDivsDone;
                if (_i % 64 == 0) {
                    nDivsDone++;
                    i = _i + nDivsDone;
                }
                cache_rows[i].playerDelta = playerScore == time ? '' : c_timeBlue + '-' + Time::Format(Math::Abs(playerScore - time));
            }
        }
    }

    void CoroDelayedPopulateCache() {
        // sleep(3000);
        // PopulateCache();
        /*
        todo: check the last time players was updated,
        and regen player names if it's more recent than
        the last time we cached the list.
        */
    }

    void MainWindow() {
        if (!w_AllCotdQualiTimes.IsVisible()) return;

        if (w_AllCotdQualiTimes.IsAppearing()) {
            UI::SetNextWindowSize(540, 980, UI::Cond::Always);
        }

        UI::Begin(w_AllCotdQualiTimes.title, w_AllCotdQualiTimes.visible.v);

        TextBigHeading("Qualifying Times | " + cotdTitleStr);
        UI::Separator();

        VPad();

#if DEV
        if (UI::BeginTable('qualiy-times-filters', 2, TableFlagsStretch())) {

            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text('Filter Name:');
            UI::TableNextColumn();
            filterName = UI::InputText('', filterName);

            UI::EndTable();
        }

        VPad();
#endif
        int cols = 5;
        if (playerFound) cols++;
        bool drawPDelta = playerFound;

        if (UI::BeginTable('qualiy-times', cols, TableFlagsStretch() | UI::TableFlags::ScrollY)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed, 70);
            UI::TableSetupColumn("Delta", UI::TableColumnFlags::WidthFixed, 70);
            UI::TableSetupColumn("Div Δ", UI::TableColumnFlags::WidthFixed, 70);
            if (drawPDelta)
                UI::TableSetupColumn("Self Δ", UI::TableColumnFlags::WidthFixed, 70);
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);

            UI::TableHeadersRow();

            UI::ListClipper Clipper(cache_rows.Length);
            while (Clipper.Step()) {
                for (int i = Clipper.DisplayStart; i < Clipper.DisplayEnd; i++) {
                    auto row = cache_rows[i];
                    if (row is null) break;

                    UI::TableNextRow();

                    UI::TableNextColumn();
                    UI::Text(row.rank);
                    UI::TableNextColumn();
                    UI::Text(row.time);
                    UI::TableNextColumn();
                    UI::Text(row.delta);
                    UI::TableNextColumn();
                    UI::Text(row.divDelta);
                    if (drawPDelta) {
                        UI::TableNextColumn();
                        UI::Text(row.playerDelta);
                    }
                    UI::TableNextColumn();
                    if (row.player !is null)
                        row.player.Draw();
                }
            }

            UI::EndTable();
        }

        UI::End();
    }

    void OnFilterName() {

    }
}
