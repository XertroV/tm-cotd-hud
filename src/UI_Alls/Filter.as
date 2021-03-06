class FilterAll {
    string f_name = '';
    string f_id = '';
    bool f_favorites = false;
    uint f_div = 0;
    FilterAll(const string &in name = '', uint div = 0, bool onlyFavorites = false, const string &in _id = "") {
        f_name = name;
        f_div = div;
        f_favorites = onlyFavorites;
        f_id = _id;
    }

    FilterAll(FilterAll@ other) {
        if (other is null) {
            @other = FilterAll();
        }
        f_name = other.f_name;
        f_favorites = other.f_favorites;
        f_div = other.f_div;
        f_id = other.f_id;
    }

    const string get_name() {
        return f_name;
    }

    uint get_div() {
        return f_div;
    }

    bool opEquals(FilterAll@ other) {
        if (other is null) return false;
        return f_name == other.f_name
            && f_id == other.f_id
            && f_favorites == other.f_favorites
            && f_div == other.f_div;
    }

    bool MatchPlayerFull(PlayerName@ pn) {
        return MatchName(pn)
            && MatchPlayerId(pn)
            && MatchFavorites(pn);
    }

    bool MatchPlayerName(PlayerName@ pn) {
        return MatchName(pn)
            && MatchFavorites(pn);
    }

    bool MatchName(PlayerName@ pn) {
        return f_name.Length == 0 || pn.Name.ToLower().Contains(f_name.ToLower());
    }

    bool MatchPlayerId(PlayerName@ pn) {
        return f_id.Length == 0 || pn.Id.Contains(f_id);
    }

    bool MatchDiv(uint div) {
        return f_div == 0 || f_div == div;
    }

    bool MatchFavorites(PlayerName@ pn) {
        return !f_favorites || pn.IsSpecial;
    }
}

enum FilterTableFlags {
    None = 0,
    Name = 1,
    FavOnly = 2,
    Divs = 4,
    PresetCotdResults = 7,
    Ids = 8,
    PresetPlayers = 1 | 2 | 8,
    All = 15
}

FilterAll@ DrawFilterAllTable(const string &in id, FilterAll@ filter, uint nDivs, FilterTableFlags flags = FilterTableFlags::PresetCotdResults) {
    FilterAll@ ret = FilterAll(filter);
    TextSubheading("Filters:");
    if (UI::BeginTable(id, 3, TableFlagsStretch())) {
        UI::PushStyleColor(UI::Col::FrameBg, vec4(.15, .15, .15, 1.));

        if (flags & FilterTableFlags::Name > 0) {
            // filter name
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text('Name:');
            UI::TableNextColumn();
            ret.f_name = UI::InputText('##' + id + '-f-name', filter.f_name);
            UI::TableNextColumn();
            if (UI::Button(Icons::Times + '##' + id + '-reset-name')) {
                ret.f_name = '';
            }
        }
        if (flags & FilterTableFlags::Ids > 0) {
            // filter name
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text('ID:');
            UI::TableNextColumn();
            ret.f_id = UI::InputText('##' + id + '-f-id', filter.f_id);
            UI::TableNextColumn();
            if (UI::Button(Icons::Times + '##' + id + '-reset-id')) {
                ret.f_id = '';
            }
        }

        if (flags & FilterTableFlags::FavOnly > 0) {
            // filter favorites
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text('Fav Only:');
            UI::TableNextColumn();
            ret.f_favorites = UI::Checkbox('##cb-' + id, filter.f_favorites);
            UI::TableNextColumn();
            if (UI::Button(Icons::Times + '##' + id + '-reset-favs')) {
                ret.f_favorites = false;
            }
        }

        if (flags & FilterTableFlags::Divs > 0) {
            // filter div // todo
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text('Division:');
            UI::TableNextColumn();
            string currDiv = filter.div == 0 ? 'All' : 'Div ' + filter.f_div;
            if (UI::BeginCombo('##' + id + '-div-combo', currDiv)) {
                if (UI::Selectable('All', filter.f_div == 0)) {
                    ret.f_div = 0;
                }
                for (uint i = 1; i <= nDivs; i++) {
                    if (UI::Selectable('Div ' + i, filter.f_div == i)) {
                        ret.f_div = i;
                    }
                }
                UI::EndCombo();
            }
            UI::TableNextColumn();
            if (UI::Button(Icons::Times + '##' + id + '-reset-div')) {
                ret.f_div = 0;
            }
        }

        UI::PopStyleColor(1);
        UI::EndTable();
        return ret;
    }
    return filter;
}
