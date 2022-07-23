namespace UI_PlayersAndFavs {

    bool m_InProg = false;
    bool m_Loaded = false;
    bool m_Initialized = false;

    string[] playerIds = {};
    PlayerName@[] filteredPlayers = {};
    FilterAll@ filter = FilterAll();
    bool m_sortDirty = false;

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
            if (filter.MatchPlayerFull(p)) {
                filteredPlayers.InsertLast(p);
            }
        }
        m_sortDirty = true;
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
        SetFilter(DrawFilterAllTable("##players-and-favs-filters", filter, 0, FilterTableFlags::PresetPlayers));
    }

    void DrawPlayersTable() {
        if (UI::BeginTable('players-and-favs', 3, TableFlagsStretch() | UI::TableFlags::ScrollY)) { //  | UI::TableFlags::Sortable
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthFixed, 200);
            UI::TableSetupColumn("Is Fav?", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoSort, 50);
            UI::TableSetupColumn("Player ID", UI::TableColumnFlags::WidthStretch);

            UI::TableHeadersRow();

            // auto sortSpecs = UI::TableGetSortSpecs();
            // if (sortSpecs !is null && sortSpecs.Dirty || m_sortDirty) {
            //     // set this early b/c we need to do this async
            //     sortSpecs.Dirty = false;
            //     m_sortDirty = false;
            //     startnew(SortItemsCoro, sortSpecs);
            // }

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

    /* sorting is just too slow atm :(
       probs need sqlite
    */
    // void SortItemsCoro(ref@ r) {
    //     // demo of sorting: https://github.com/openplanet-nl/example-scripts/blob/010e1ad1438d764042cbe81631699878be88a8ed/Plugin_TableTest.as

    //     UI::TableSortSpecs@ ss = cast<UI::TableSortSpecs>(r);
    //     if (filteredPlayers.Length < 2) return;  // can't sort < 2 items

    //     // set this early b/c we need to do this async
    //     ss.Dirty = false;
    //     m_sortDirty = false;

    //     auto specs = ss.Specs;
    //     for (uint i = 0; i < specs.Length; i++) {
    //         auto spec = specs[i];
    //         if (spec.SortDirection == UI::SortDirection::None) continue;

    //         uint chunkSize = 100;
    //         // for (uint chunkSize = 100; chunkSize < filteredPlayers.Length; chunkSize *= 2) {
    //             for (uint sortFrom = 0; sortFrom < filteredPlayers.Length; sortFrom += chunkSize) {
    //                 if (spec.SortDirection == UI::SortDirection::Ascending) {
    //                     switch (spec.ColumnIndex) {
    //                         case 0: filteredPlayers.Sort(function(a, b) { return a.Name < b.Name; }, sortFrom, chunkSize); break;
    //                         case 2: filteredPlayers.Sort(function(a, b) { return a.Id < b.Id; }, sortFrom, chunkSize); break;
    //                     }
    //                 } else if (spec.SortDirection == UI::SortDirection::Descending) {
    //                     switch (spec.ColumnIndex) {
    //                         case 0: filteredPlayers.Sort(function(a, b) { return a.Name > b.Name; }, sortFrom, chunkSize); break;
    //                         case 2: filteredPlayers.Sort(function(a, b) { return a.Id > b.Id; }, sortFrom, chunkSize); break;
    //                     }
    //                 }
    //                 yield();
    //             }
    //         // }
    //     }
    // }
}
