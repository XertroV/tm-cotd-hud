WindowState w_AllCotdQualiTimes('COTD Qualifying Times', false);

namespace WAllTimes {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    class Row {
        string rank;
        string time;
        uint div;
        string delta;
        string divDelta;
        string playerDelta;
        PlayerName@ player;
        bool isDivRow;
        Row(const string &in r, const string &in t, uint _div, const string &in d, const string &in dd, const string &in pd, PlayerName@ p, bool divRow = false) {
            rank = r;
            time = t;
            div = _div;
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
    Row@[] filtered_rows = array<Row@>();
    dictionary@ pidToRank = dictionary();
    uint nPlayers = 0;
    uint nDivs = 0;
    string playerId;
    bool playerFound = false;
    uint playerRank = 0;
    string cotdTitleStr = "";
    bool cached = false;
    FilterAll@ filter;

    void SetParams(const string &in _mapUid, int _cId, FilterAll@ filter = null) {
        cached = false;
        mapUid = _mapUid;
        cId = _cId;
        times = PersistentData::GetCotdMapTimesAllJ(mapUid, cId);
        cotdTitleStr = CotdExplorer::_ExplorerCotdTitleStr();
        SetFilter(filter);
        startnew(PopulateCache);
    }

    void SetFilter(FilterAll@ f = null) {
        if (f is null) {
            @f = FilterAll();
        }
        if (f != filter) {
            @filter = f;
            PopulateFiltered();
            cotdTitleStr = CotdExplorer::_ExplorerCotdTitleStr();
            if (f.f_div > 0)
                cotdTitleStr = CotdExplorer::_ExplorerCotdTitleStr() + " | Div " + f.f_div;
        }
    }

    void PopulateCache() {
        playerId = GI::PlayersId();
        nPlayers = times.Length;
        // nDivs = uint(Math::Ceil(float(nPlayers) / 64.));
        nDivs = ((nPlayers - 1) >> 6) + 1; // faster and more elegant
        cache_rows.Resize(nPlayers + nDivs);
        @pidToRank = dictionary();
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
                @cache_rows[i] = Row(c_brightBlue + 'Div ' + thisDiv,
                    c_brightBlue + '------------',
                    thisDiv,
                    c_brightBlue + '------------',
                    c_brightBlue + '------------',
                    c_brightBlue + '------------',
                    PlayerName(c_brightBlue + _d, '', false, true), true);
                nDivsDone++;
                i = _i + nDivsDone;
                bestInDiv = time;
            }
            pid = times[_i]['player'];
            uint rank = (_i + 1);
            pidToRank[pid] = rank;
            @cache_rows[i] = Row('' + rank,
                Time::Format(time),
                thisDiv,
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

        PopulateFiltered();
        cached = true;
    }

    void PopulateFiltered() {
        filtered_rows.Resize(0);
        for (uint i = 0; i < cache_rows.Length; i++) {
            auto row = cache_rows[i];
            if (filter.MatchPlayerName(row.player) && filter.MatchDiv(row.div)) {
                filtered_rows.InsertLast(row);
            }
        }
    }

    uint GetPlayerRank(const string &in pid) {
        if (pidToRank.Exists(pid))
            return uint(pidToRank[pid]);
        return 0;
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

        if (UI::Button('Refresh Data')) {
            startnew(PopulateCache);
        }

        SetFilter(DrawFilterAllTable('cotd-div-all-res-filter', filter, nDivs));

        VPad();

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
                UI::TableSetupColumn("Δ vs You", UI::TableColumnFlags::WidthFixed, 70);
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);

            UI::TableHeadersRow();

            UI::ListClipper Clipper(filtered_rows.Length);
            while (Clipper.Step()) {
                for (int i = Clipper.DisplayStart; i < Clipper.DisplayEnd; i++) {
                    auto row = filtered_rows[i];
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
}
