WindowState w_AllCotdQualiTimes('COTD Qualifying Times', false);

namespace WAllTimes {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    string filterName = '';
    string mapUid;  /* do not set directly */
    int cId;  /* do not set directly */
    Json::Value[] times;
    string[] cache_Ranks = array<string>();
    string[] cache_Times = array<string>();
    string[] cache_Deltas = array<string>();
    string[] cache_DivDeltas = array<string>();
    string[] cache_PlayerDeltas = array<string>();
    string[] cache_Players = array<string>();
    bool[] cache_Special = array<bool>();
    uint nPlayers = 0;
    uint nDivs = 0;
    string playerId;
    bool playerFound = false;
    uint playerRank = 0;

    void SetParams(const string &in _mapUid, int _cId) {
        mapUid = _mapUid;
        cId = _cId;
        times = PersistentData::GetCotdMapTimesAllJ(mapUid, cId);
        startnew(PopulateCache);
    }

    void PopulateCache() {
        playerId = DataManager::gi.PlayersId();
        nPlayers = times.Length;
        // nDivs = uint(Math::Ceil(float(nPlayers) / 64.));
        nDivs = ((nPlayers - 1) >> 6) + 1;
        cache_Ranks.Resize(nPlayers + nDivs);
        cache_Times.Resize(nPlayers + nDivs);
        cache_Deltas.Resize(nPlayers + nDivs);
        cache_DivDeltas.Resize(nPlayers + nDivs);
        cache_PlayerDeltas.Resize(nPlayers + nDivs);
        cache_Players.Resize(nPlayers + nDivs);
        cache_Special.Resize(nPlayers + nDivs);
        uint bestTime = nPlayers > 0 ? times[0]['score'] : 0;
        string pid, name, _d;
        bool special;
        uint time, nDivsDone = 0, i, bestInDiv, thisDiv, playerScore = 0;
        playerFound = false;
        for (uint _i = 0; _i < nPlayers; _i++) {
            i = _i + nDivsDone;
            time = uint(times[_i]['score']);
            if (_i % 64 == 0) {
                thisDiv = uint(Math::Ceil(float(_i) / 64. + 1));
                _d = "Div " + thisDiv;
                cache_Ranks[i] = c_brightBlue + 'D ' + thisDiv;
                cache_Times[i] = c_brightBlue + '------------';
                cache_Deltas[i] = c_brightBlue + '------------';
                cache_DivDeltas[i] = c_brightBlue + '------------';
                cache_PlayerDeltas[i] = c_brightBlue + '------------';
                cache_Players[i] = c_brightBlue + _d;
                cache_Special[i] = false;
                nDivsDone++;
                i = _i + nDivsDone;
                bestInDiv = time;
            }
            cache_Ranks[i] = '' + (_i + 1);
            cache_Times[i] = Time::Format(time);
            cache_Deltas[i] = time == bestTime ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - bestTime));
            cache_DivDeltas[i] = time == bestInDiv ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - bestInDiv));
            pid = times[_i]['player'];
            name = PersistentData::mapDb.playerNameDb.Get(pid);
            special = IsSpecialPlayerId(pid);
            cache_Players[i] = name;
            cache_Special[i] = special;
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
        sleep(3000);
        PopulateCache();
    }

    void MainWindow() {
        if (!w_AllCotdQualiTimes.IsVisible()) return;

        if (w_AllCotdQualiTimes.IsAppearing()) {
            UI::SetNextWindowSize(476, 820, UI::Cond::Always);
        }

        UI::Begin(w_AllCotdQualiTimes.title, w_AllCotdQualiTimes.visible.v);

        TextBigHeading("Qualifying Times | " + CotdExplorer::_ExplorerCotdTitleStr());
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
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("Delta", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("Div Δ", UI::TableColumnFlags::WidthFixed);
            if (drawPDelta)
                UI::TableSetupColumn("Self Δ", UI::TableColumnFlags::WidthFixed);
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
                    UI::Text(!cache_Special[i] ? cache_Players[i] : rainbowLoopColorCycle(cache_Players[i], true));
                }
            }

            UI::EndTable();
        }

        UI::End();
    }

    void DrawDivisionMarkerInTable(uint div) {
        throw("deprecated");
        UI::TableNextRow();

        string _d = "Div " + div;
        UI::TableNextColumn();
        UI::Text(c_brightBlue + _d);
        UI::TableNextColumn();
        UI::Text(c_brightBlue + '------------');
        UI::TableNextColumn();
        UI::Text(c_brightBlue + '------------');
        UI::TableNextColumn();
        UI::Text(c_brightBlue + _d);
    }

    void OnFilterName() {

    }
}
