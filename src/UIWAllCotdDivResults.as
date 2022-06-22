WindowState w_AllCotdDivResults('COTD Division Results', false);

namespace WAllDivResults {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    string filterName = 'doesnt work yet';
    string mapUid;  /* do not set directly */
    uint cId;  /* do not set directly */
    // CompRoundMatches@[] matches;
    MapDb@ mapDb;
    string[] cache_Ranks = array<string>();
    string[] cache_DivRank = array<string>();
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

    void SetParams(uint _cId) {
        cId = _cId;
        @mapDb = PersistentData::mapDb;
        startnew(PopulateCache);
    }

    void PopulateCache() {
        auto matchIds = mapDb.GetMatchIdsForCotdComp(cId);
        playerId = DataManager::gi.PlayersId();
        // nDivs = uint(Math::Ceil(float(nPlayers) / 64.));
        nDivs = matchIds.Length; // faster and more elegant
        auto matches = mapDb.matchResultsDb.Get(mapDb.GetRoundIdForCotdComp(cId));
        nPlayers = (nDivs - 1) * 64 + matches.Get(matchIds[nDivs - 1]).results.Length;
        if (nDivs == 0) nPlayers = 0;
        cache_Ranks.Resize(nPlayers + nDivs);
        cache_DivRank.Resize(nPlayers + nDivs);
        cache_Deltas.Resize(nPlayers + nDivs);
        cache_DivDeltas.Resize(nPlayers + nDivs);
        cache_PlayerDeltas.Resize(nPlayers + nDivs);
        cache_Players.Resize(nPlayers + nDivs);
        cache_Special.Resize(nPlayers + nDivs);
        // uint bestTime = nPlayers > 0 ? times[0]['score'] : 0;
        string pid, name, _d;
        bool special;
        uint nDivsDone = 0, i, bestInDiv, thisDiv, playerScore = 0;
        playerFound = false;
        uint lastBreak = 0;
        uint gRank = 0;
        for (uint divIx = 0; divIx < nDivs; divIx++) {
            if (Time::Now - lastBreak > 8) {
                yield();
                lastBreak = Time::Now;
            }
            auto match = matches.Get(matchIds[divIx]);
            i = divIx * 64 + nDivsDone;
            /* start of div */
            thisDiv = divIx + 1;
            _d = "Div " + thisDiv;
            cache_Ranks[i] = c_brightBlue + 'D ' + thisDiv;
            cache_DivRank[i] = c_brightBlue + '-----';
            // cache_Deltas[i] = c_brightBlue + '------------';
            // cache_DivDeltas[i] = c_brightBlue + '------------';
            // cache_PlayerDeltas[i] = c_brightBlue + '------------';
            cache_Players[i] = c_brightBlue + _d;
            cache_Special[i] = false;
            nDivsDone++;

            /* start of player rows */
            for (uint j = 0; j < match.results.Length; j++) {
                i++;
                auto r = match.results[j].rank;
                auto gr = ++gRank;
                auto maxDivRank = thisDiv * 64;
                if (r.IsSome()) {
                    cache_Ranks[i] = '' + gr;
                    cache_DivRank[i] = ('' + r.GetOr(0xFFFFFFFF));
                } else {
                    cache_Ranks[i] = '' + maxDivRank;
                    cache_DivRank[i] = '--';
                }
                pid = match.results[j].participant;
                name = PersistentData::mapDb.playerNameDb.Get(pid);
                special = IsSpecialPlayerId(pid);
                cache_Players[i] = name;
                cache_Special[i] = special;
                if (playerFound) {
                    // cache_PlayerDeltas[i] = time == playerScore ? '' : c_timeOrange + '+' + Time::Format(Math::Abs(time - playerScore));
                }
                if (pid == playerId) {
                    playerFound = true;
                    // playerScore = time;
                    playerRank = gRank;
                    // cache_PlayerDeltas[i] = '';
                }
            }
        }

        // if (playerFound) {
        //     nDivsDone = 0;
        //     for (uint _i = 0; _i < playerRank - 1; _i++) {
        //         time = uint(times[_i]['score']);
        //         i = _i + nDivsDone;
        //         if (_i % 64 == 0) {
        //             nDivsDone++;
        //             i = _i + nDivsDone;
        //         }
        //         cache_PlayerDeltas[i] = playerScore == time ? '' : c_timeBlue + '-' + Time::Format(Math::Abs(playerScore - time));
        //     }
        // }
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
        if (!w_AllCotdDivResults.IsVisible()) return;

        if (w_AllCotdDivResults.IsAppearing()) {
            UI::SetNextWindowSize(476, 820, UI::Cond::Always);
        }

        UI::Begin(w_AllCotdDivResults.title, w_AllCotdDivResults.visible.v);

        TextBigHeading("Division Results | " + CotdExplorer::_ExplorerCotdTitleStr());
        UI::Separator();

        VPad();

#if DEV
        if (UI::BeginTable('div-results-filters', 2, TableFlagsStretch())) {

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

        if (UI::BeginTable('div-results', cols, TableFlagsStretch() | UI::TableFlags::ScrollY)) {
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
                    UI::Text(cache_DivRank[i]);
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

    void OnFilterName() {

    }
}
