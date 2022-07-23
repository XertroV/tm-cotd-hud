namespace UI_PlayersAndFavs {

    bool m_InProg = false;
    bool m_Loaded = false;
    bool m_Initialized = false;

    string[] playerIds = {};
    PlayerName@[] filteredPlayers = {};
    FilterAll@ filter = FilterAll();

    void RenderInner() {
        if (!m_Initialized) {
            m_Initialized = true;
            startnew(ClearAndLoad);
        } else {
            DrawFiltersAndTable();
        }
    }

    void ClearAndLoad() {
        if (m_InProg) return;
        m_InProg = true;
        PersistentData::mapDb.AwaitInitialized();
        playerIds.RemoveRange(0, playerIds.Length);
        while (PersistentData::mapDb is null) yield();
        auto mapDb = PersistentData::mapDb;
        while (mapDb.playerNameDb is null) yield();
        playerIds = mapDb.playerNameDb.GetKeys();
        logcall("playerIds.Length", '' + playerIds.Length);
        @filter = FilterAll();
        PopulateFiltered();
        m_Loaded = true;
        m_InProg = false;
    }

    void PopulateFiltered() {
        filteredPlayers.Resize(0);
        uint lastBreak = Time::Now;
        for (uint i = 0; i < playerIds.Length; i++) {
            if (Time::Now > lastBreak + 15) {
                yield();
                lastBreak = Time::Now;
            }
            auto p = PlayerNames::Get(playerIds[i]);
            if (filter.MatchPlayerName(p)) {
                filteredPlayers.InsertLast(p);
            }
        }
    }

    void SetFilter(FilterAll@ f = null) {
        if (f is null) {
            @f = FilterAll();
        }
        if (f != filter) {
            @filter = f;
            startnew(PopulateFiltered);
        }
    }

    void DrawFiltersAndTable() {
        if (MDisabledButton(m_InProg, "Refresh##players-and-favs")) {
            startnew(ClearAndLoad);
        }
        DrawFilters();
        UI::Text('N Players: ' + playerIds.Length);
        UI::Text('Table currently shows: ' + filteredPlayers.Length);
        DrawPlayersTable();
    }

    void DrawFilters() {
        SetFilter(DrawFilterAllTable("##players-and-favs-filters", filter, 0, FilterTableFlags::NameAndFav));
    }

    void DrawPlayersTable() {
        if (UI::BeginTable('players-and-favs', 3, TableFlagsStretch() | UI::TableFlags::ScrollY)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthFixed, 200);
            UI::TableSetupColumn("Is Fav?", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Player ID", UI::TableColumnFlags::WidthStretch);

            UI::TableHeadersRow();

            UI::ListClipper Clipper(filteredPlayers.Length);
            while (Clipper.Step()) {
                for (int i = Clipper.DisplayStart; i < Clipper.DisplayEnd; i++) {
                    auto player = filteredPlayers[i];

                    UI::TableNextRow();

                    UI::TableNextColumn();
                    player.Draw();
                    UI::TableNextColumn();
                    UI::Text(player.IsSpecial ? Icons::Check : "");
                    UI::TableNextColumn();
                    UI::Text(player.Id);
                }
            }
            UI::EndTable();
        }
    }

}
