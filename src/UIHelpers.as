void AddSimpleTooltip(string msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}

funcdef void DrawUiElems();
funcdef void DrawUiElemsF(DrawUiElems@ f);

void DrawAsRow(DrawUiElemsF@ f, const string &in id, int cols = 64) {
    int flags = 0;
    flags |= UI::TableFlags::SizingFixedFit;
    flags |= UI::TableFlags::NoPadOuterX;
    if (UI::BeginTable(id, cols, flags)) {
        UI::TableNextRow();
        f(DrawUiElems(_TableNextColumn));
        UI::EndTable();
    }
}

void _TableNextRow() {
    UI::TableNextRow();
}
void _TableNextColumn() {
    UI::TableNextColumn();
}
