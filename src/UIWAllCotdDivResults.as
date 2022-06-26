WindowState w_AllCotdDivResults('COTD Division Results', false);

namespace WAllDivResults {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    string filterName = 'doesnt work yet';
    uint cId;  /* do not set directly */
    uint divShowOnly = 0;  /* do not set directly; 0 for show all divs */
    MapDb@ mapDb;
    string[] cache_Ranks = array<string>();
    string[] cache_DivRank = array<string>();
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

    void SetParams(uint _cId, uint _divShowOnly = 0) {
        cId = _cId;
        divShowOnly = _divShowOnly;
        @mapDb = PersistentData::mapDb;
        cotdTitleStr = CotdExplorer::_ExplorerCotdTitleStr();
        if (divShowOnly > 0)
            cotdTitleStr += " | Div " + divShowOnly;
        startnew(PopulateCache);
    }

    void PopulateCache() {
        auto matchIds = mapDb.GetMatchIdsForCotdComp(cId);
        playerId = DataManager::gi.PlayersId();
        nDivs = matchIds.Length;
        auto matches = mapDb.matchResultsDb.Get(mapDb.GetRoundIdForCotdComp(cId));
        uint lastDivN = matches.Get(matchIds[nDivs - 1]).results.Length;
        nPlayers = (nDivs - 1) * 64 + lastDivN;
        if (nDivs == 0) nPlayers = 0;
        uint arraySize = divShowOnly == 0
            ? nPlayers + nDivs
            : divShowOnly < nDivs ? 65 : 1 + lastDivN;
        cache_Ranks.Resize(arraySize);
        cache_DivRank.Resize(arraySize);
        cache_Deltas.Resize(arraySize);
        cache_DivDeltas.Resize(arraySize);
        cache_PlayerDeltas.Resize(arraySize);
        cache_Players.Resize(arraySize);
        string pid, name, _d;
        bool special, drawDiv;
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
            thisDiv = divIx + 1;
            drawDiv = thisDiv == divShowOnly || divShowOnly == 0;
            i = divIx * 64 + nDivsDone;
            if (drawDiv) {
                if (divShowOnly != 0)
                    i = 0;
                /* start of div */
                _d = "Div " + thisDiv;
                cache_Ranks[i] = c_brightBlue + 'Div ' + thisDiv;
                cache_DivRank[i] = c_brightBlue + '--------';
                cache_PlayerDeltas[i] = c_brightBlue + '--------';
                @cache_Players[i] = PlayerName(c_brightBlue + _d, '', false);
            }
            nDivsDone++;

            /* start of player rows */
            for (uint j = 0; j < match.results.Length; j++) {
                i++;
                auto r = match.results[j].rank;
                auto gr = ++gRank;
                auto maxDivRank = thisDiv * 64;
                pid = match.results[j].participant;
                auto player = PlayerName(pid);
                if (drawDiv) {
                    if (r.IsSome()) {
                        cache_Ranks[i] = '' + gr;
                        cache_DivRank[i] = ('' + r.GetOr(0xFFFFFFFF));
                    } else {
                        cache_Ranks[i] = '' + maxDivRank;
                        cache_DivRank[i] = '--';
                    }
                    @cache_Players[i] = player;
                    if (playerFound) {
                        cache_PlayerDeltas[i] = gRank == playerRank ? '' : c_timeOrange + '+' + (gRank - playerRank);
                    }
                    if (pid == playerId) {
                        playerFound = true;
                        playerRank = gRank;
                        cache_PlayerDeltas[i] = '';
                    }
                }
            }
        }

        if (playerFound) {
            nDivsDone = 0;
            for (uint divIx = 0; divIx < nDivs; divIx++) {
                auto match = matches.Get(matchIds[divIx]);
                thisDiv = divIx + 1;
                drawDiv = thisDiv == divShowOnly || divShowOnly == 0;
                i = divIx * 64 + nDivsDone + 1;
                if (divShowOnly != 0)
                    i = 1;
                for (uint j = 0; j < match.results.Length; j++) {
                    uint rank = 64 * divIx + j + 1;
                    if (rank >= playerRank) break;
                    if (drawDiv)
                        cache_PlayerDeltas[i] = rank == playerRank ? '' : c_timeBlue + '-' + (playerRank - rank);
                    i++;
                }
                nDivsDone++;
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
        if (!w_AllCotdDivResults.IsVisible()) return;

        if (w_AllCotdDivResults.IsAppearing()) {
            UI::SetNextWindowSize(476, 820, UI::Cond::Always);
        }

        UI::Begin(w_AllCotdDivResults.title, w_AllCotdDivResults.visible.v);

        TextBigHeading("Div Results | " + cotdTitleStr);
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
        int cols = 3;
        if (playerFound) cols++;
        bool drawPDelta = playerFound;

        if (UI::BeginTable('div-results', cols, TableFlagsStretch() | UI::TableFlags::ScrollY)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 50);
            if (drawPDelta)
                UI::TableSetupColumn("Rank Δ", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Div Rank", UI::TableColumnFlags::WidthFixed, 60);
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
                    if (drawPDelta) {
                        UI::TableNextColumn();
                        UI::Text(cache_PlayerDeltas[i]);
                    }
                    UI::TableNextColumn();
                    UI::Text(cache_DivRank[i]);
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
