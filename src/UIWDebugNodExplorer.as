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
                // if (_DebugNod.BaseType) {
                //     UI::NodTree(_DebugNod.BaseType);
                // }
            } else {
                UI::Text("\\$f00" + "Nod is null -- nothing to show.\nClose this window before trying to view this Nod again.");
            }
            UI::End();
            UI::PopStyleVar();
        }
        w.Done();
    }

    void DumpProperties(const Reflection::MwClassInfo@ c) {
        print("Type: " + c.Name);
        auto members = c.Members;
        for (uint i = 0; i < members.Length; i++) {
            print("Member: " + members[i].Name);
        }
        if (c.BaseType !is null) {
            DumpProperties(c.BaseType);
        }
    }
}
