WindowState w_AllCotdQualiTimes('COTD Qualifying Times', false);

namespace WAllTimes {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    string filterName = 'doesnt work yet';
    string mapUid;  /* do not set directly */
    int cId;  /* do not set directly */
    Json::Value[] times;
    string[] cache_Ranks = array<string>();
    string[] cache_Times = array<string>();
    string[] cache_Deltas = array<string>();
    string[] cache_DivDeltas = array<string>();
    string[] cache_PlayerDeltas = array<string>();
    PlayerName@[] cache_Players = array<PlayerName@>();
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
        playerId = DataManager::gi.PlayersId();
        nPlayers = times.Length;
        // nDivs = uint(Math::Ceil(float(nPlayers) / 64.));
        nDivs = ((nPlayers - 1) >> 6) + 1; // faster and more elegant
        cache_Ranks.Resize(nPlayers + nDivs);
        cache_Times.Resize(nPlayers + nDivs);
        cache_Deltas.Resize(nPlayers + nDivs);
        cache_DivDeltas.Resize(nPlayers + nDivs);
        cache_PlayerDeltas.Resize(nPlayers + nDivs);
        cache_Players.Resize(nPlayers + nDivs);
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
                cache_Ranks[i] = c_brightBlue + 'Div ' + thisDiv;
                cache_Times[i] = c_brightBlue + '------------';
                cache_Deltas[i] = c_brightBlue + '------------';
                cache_DivDeltas[i] = c_brightBlue + '------------';
                cache_PlayerDeltas[i] = c_brightBlue + '------------';
                @cache_Players[i] = PlayerName(c_brightBlue + _d, '', false);
                nDivsDone++;
                i = _i + nDivsDone;
                bestInDiv = time;
            }
            cache_Ranks[i] = '' + (_i + 1);
            cache_Times[i] = Time::Format(time);
            cache_Deltas[i] = time == bestTime ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - bestTime));
            cache_DivDeltas[i] = time == bestInDiv ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - bestInDiv));
            pid = times[_i]['player'];
            @cache_Players[i] = PlayerName(pid);  // don't get cached player name here -- right click breaks
            if (playerFound) {
                cache_PlayerDeltas[i] = time == playerScore ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - playerScore));
            }
            if (pid == playerId) {
                playerFound = true;
                playerScore = time;
                playerRank = _i + 1;
                cache_PlayerDeltas[i] = '';
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
                cache_PlayerDeltas[i] = playerScore == time ? '' : c_timeBlue + '-' + Time::Format(Math::Abs(playerScore - time));
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

            UI::ListClipper Clipper(cache_Ranks.Length);
            while (Clipper.Step()) {
                for (int i = Clipper.DisplayStart; i < Clipper.DisplayEnd; i++) {
                    // if (i % 64 == 0) {
                    //     DrawDivisionMarkerInTable(i / 64 + 1);
                    // }

                    UI::TableNextRow();

                    UI::TableNextColumn();
                    UI::Text(cache_Ranks[i]);
                    UI::TableNextColumn();
                    UI::Text(cache_Times[i]);
                    UI::TableNextColumn();
                    UI::Text(cache_Deltas[i]);
                    UI::TableNextColumn();
                    UI::Text(cache_DivDeltas[i]);
                    if (drawPDelta) {
                        UI::TableNextColumn();
                        UI::Text(cache_PlayerDeltas[i]);
                    }
                    UI::TableNextColumn();
                    if (cache_Players[i] !is null)
                        cache_Players[i].Draw();
                }
            }

            UI::EndTable();
        }

        UI::End();
    }

    void OnFilterName() {

    }
}
