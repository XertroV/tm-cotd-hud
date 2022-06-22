[Setting hidden]
bool Setting_EulaWindow = true;

WindowState w_EulaFirstLoad('COTD HUD + Explorer EULA', Setting_EulaWindow);

namespace WEULA {
    void Render() {
        if (Setting_EulaAgreement) Setting_EulaWindow = false;
        if (Setting_EulaWindow) {
            if (!w_EulaFirstLoad.IsVisible()) return;
            if (w_EulaFirstLoad.IsAppearing()) {
                vec2 size = vec2(1000, 700);
                UI::SetNextWindowSize(size.x, size.y, UI::Cond::Always);
                vec2 wh = vec2(Draw::GetWidth(), Draw::GetHeight());
                vec2 center = wh / 2.;
                vec2 tl = center - (size / 2.);
                UI::SetNextWindowPos(tl.x, tl.y);
            }
            UI::Begin(w_EulaFirstLoad.title, w_EulaFirstLoad.visible.v);
                RenderSettingsEula();
            UI::End();
        }
    }
}

// RenderSettingsEula
