namespace WDebugNod {
    void Render() {
        auto w = @_DebugNodWindow;
        if (w.IsVisible()) {
            UI::PushStyleVar(UI::StyleVar::WindowMinSize, vec2(600, 400));
            if (w.IsAppearing()) {
                UI::SetNextWindowSize(1000, 1000, UI::Cond::Always);
            }
            UI::Begin(w.title, w.visible.v);
            if (_DebugNod !is null) {
                UI::NodTree(_DebugNod);
            } else {
                UI::Text("\\$f00" + "Nod is null -- nothing to show.\nClose this window before trying to view this Nod again.");
            }
            UI::End();
            UI::PopStyleVar();
        }
        w.Done();
    }
}
