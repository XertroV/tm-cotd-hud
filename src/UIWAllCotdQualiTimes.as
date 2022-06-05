WindowState w_AllCotdQualiTimes('COTD Qualifying Times', false);

namespace WAllTimes {
    void Render() {}

    void RenderInterface() {
        MainWindow();
    }

    string filterName = '';

    void MainWindow() {
        if (!w_AllCotdQualiTimes.IsVisible()) return;

        if (w_AllCotdQualiTimes.IsAppearing()) {
            UI::SetNextWindowSize(450, 800, UI::Cond::Always);
        }

        UI::Begin(w_AllCotdQualiTimes.title, w_AllCotdQualiTimes.visible.v);

        TextBigHeading("Qualifying Times | " + CotdExplorer::_ExplorerCotdTitleStr());
        UI::Separator();

        VPad();

        if (UI::BeginTable('qualiy-times-filters', 2, TableFlagsStretch())) {

            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text('Filter Name:');
            UI::TableNextColumn();
            filterName = UI::InputText('', filterName);

            UI::EndTable();
        }

        VPad();

        if (UI::BeginTable('qualiy-times', 3, TableFlagsStretch())) {

            UI::EndTable();
        }

        UI::End();
    }

    void OnFilterName() {

    }
}
