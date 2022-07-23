WindowState w_AllCotdDivResults('COTD Division Results', false);

namespace WAllDivResults {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    class Row {
        string rank;
        string rankDelta;
        string divRank;
        string playerDelta;
        PlayerName@ player;
        uint div;
        bool isDivRow;
        Row(const string &in r, const string &in rd, const string &in dr, uint _div, const string &in pd, PlayerName@ p, bool divRow = false) {
            rank = r;
            rankDelta = rd;
            divRank = dr;
            playerDelta = pd;
            @player = p;
            isDivRow = divRow;
            div = _div;
        }
    }

    string filterName = 'doesnt work yet';
    uint cId;  /* do not set directly */
    MapDb@ mapDb;
    Row@[] cache_rows = array<Row@>();
    Row@[] filtered_rows = array<Row@>();
    uint nPlayers = 0;
    uint nDivs = 0;
    string playerId;
    bool playerFound = false;
    uint playerRank = 0;
    string cotdTitleStr = "";
    bool cached = false;
    FilterAll@ filter;

    void SetParams(uint _cId, FilterAll@ filter = null, bool populateCache = true) {
        cached = false;
        cId = _cId;
        @mapDb = PersistentData::mapDb;
        cotdTitleStr = CotdExplorer::_ExplorerCotdTitleStr();
        SetFilter(filter);
        if (populateCache)
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
        // wait for all quali times to be cached so that we can do a comparison
        // of quali rank vs final rank
        while (!WAllTimes::cached) yield();
        while (!mapDb.HaveRoundIdForCotdComp(cId)) yield();
        while (!mapDb.HaveMatchIdsForCotdComp(cId)) yield();

        playerId = GI::PlayersId();
        auto matches = mapDb.matchResultsDb.Get(mapDb.GetRoundIdForCotdComp(cId));
        auto matchIds = mapDb.GetMatchIdsForCotdComp(cId);
        nDivs = matchIds.Length;
        uint lastDivN = matches.Get(matchIds[nDivs - 1]).results.Length;
        nPlayers = (nDivs - 1) * 64 + lastDivN;
        if (nDivs == 0) nPlayers = 0;
        uint arraySize = nPlayers + nDivs;
        cache_rows.Resize(arraySize);
        filtered_rows.Resize(0);
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
            i = divIx * 64 + nDivsDone;
            /* start of div */
            _d = "Div " + thisDiv;
            @cache_rows[i] = Row(c_brightBlue + 'Div ' + thisDiv,
                c_brightBlue + '------',
                c_brightBlue + '--------',
                thisDiv,
                c_brightBlue + '--------',
                PlayerName(c_brightBlue + _d, '', false, true), true);
            nDivsDone++;

            /* start of player rows */
            for (uint j = 0; j < match.results.Length; j++) {
                i++;
                auto r = match.results[j].rank;
                auto gr = ++gRank;
                auto maxDivRank = thisDiv * 64;
                pid = match.results[j].participant;
                auto player = PlayerNames::Get(pid);
                auto rankDelta = GetRankDeltaStr(gr, pid);
                string dr = r.IsSome() ? '' + r.GetOr(0xff) : '--';
                @cache_rows[i] = Row('' + gr, rankDelta, dr, thisDiv, '', player);
                if (playerFound) {
                    cache_rows[i].playerDelta = gRank == playerRank ? '' : c_timeOrange + '+' + (gRank - playerRank);
                }
                if (pid == playerId) {
                    playerFound = true;
                    playerRank = gRank;
                    cache_rows[i].playerDelta = '';
                }
            }
        }

        if (playerFound) {
            nDivsDone = 0;
            for (uint divIx = 0; divIx < nDivs; divIx++) {
                auto match = matches.Get(matchIds[divIx]);
                thisDiv = divIx + 1;
                i = divIx * 64 + nDivsDone + 1;
                for (uint j = 0; j < match.results.Length; j++) {
                    uint rank = 64 * divIx + j + 1;
                    if (rank >= playerRank) break;
                    cache_rows[i].playerDelta = rank == playerRank ? '' : c_timeBlue + '-' + (playerRank - rank);
                    i++;
                }
                nDivsDone++;
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

    const string GetRankDeltaStr(uint gr, const string &in pid) {
        auto qualiRank = WAllTimes::GetPlayerRank(pid);
        // todo: race condition!?
        if (qualiRank == 0) {
            yield();
            qualiRank = WAllTimes::GetPlayerRank(pid);
        }
        auto divDelta = int(gr) - int(qualiRank);
        if (divDelta == 0) return '0';
        string color = divDelta > 0 ? c_timeOrange + '+' : c_timeBlue;
        string rd = qualiRank > 0 ? color + divDelta : '??';
        return rd;
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

        if (UI::Button('Refresh Data')) {
            startnew(WAllTimes::PopulateCache);
            startnew(PopulateCache);
        }

        SetFilter(DrawFilterAllTable('cotd-div-all-res-filter', filter, nDivs));

        VPad();

        int cols = 5;
        if (playerFound) cols++;
        bool drawPDelta = playerFound;

        if (UI::BeginTable('div-results', cols, TableFlagsStretch() | UI::TableFlags::ScrollY)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Rank Δ", UI::TableColumnFlags::WidthFixed, 50);
            if (drawPDelta)
                UI::TableSetupColumn("Δ vs You", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Div Rank", UI::TableColumnFlags::WidthFixed, 60);
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Div", UI::TableColumnFlags::WidthFixed, 40);

            UI::TableHeadersRow();

            UI::ListClipper Clipper(filtered_rows.Length);
            while (Clipper.Step()) {
                for (int i = Clipper.DisplayStart; i < Clipper.DisplayEnd; i++) {
                    auto row = filtered_rows[i];
                    if (row is null) break;
                    // if (i % 64 == 0) {
                    //     DrawDivisionMarkerInTable(i / 64 + 1);
                    // }
                    UI::TableNextRow();

                    UI::TableNextColumn();
                    UI::Text(row.rank);
                    UI::TableNextColumn();
                    UI::Text(row.rankDelta);
                    if (drawPDelta) {
                        UI::TableNextColumn();
                        UI::Text(row.playerDelta);
                    }
                    UI::TableNextColumn();
                    UI::Text(row.divRank);
                    UI::TableNextColumn();
                    if (row.player !is null)
                        row.player.Draw();
                    UI::TableNextColumn();
                    UI::Text('' + row.div);
                }
            }

            UI::EndTable();
        }

        UI::End();
    }
}
