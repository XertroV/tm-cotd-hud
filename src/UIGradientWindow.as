

/*
  ######   ########     ###    ########  #### ######## ##    ## ########
 ##    ##  ##     ##   ## ##   ##     ##  ##  ##       ###   ##    ##
 ##        ##     ##  ##   ##  ##     ##  ##  ##       ####  ##    ##
 ##   #### ########  ##     ## ##     ##  ##  ######   ## ## ##    ##
 ##    ##  ##   ##   ######### ##     ##  ##  ##       ##  ####    ##
 ##    ##  ##    ##  ##     ## ##     ##  ##  ##       ##   ###    ##
  ######   ##     ## ##     ## ########  #### ######## ##    ##    ##

GRADIENT
*/

string GRADIENT_WINDOW_TITLE = "";

[Setting hidden]
string s_GradientText = ">> Your Input Text! Colors! Wow wee. What a time to be alive. <<";

[Setting hidden]
bool Setting_UtilColorGradWindowOpen = false;

void _SetUtilColorWindowOpenSetting(bool v) {
    Setting_UtilColorGradWindowOpen = v;
}

void ColorGradientWindow_Setup() {
    windowCGradOpen.v = Setting_UtilColorGradWindowOpen;
    windowCGradOpen.RegisterCallback("updateWindowOpenSetting", _SetUtilColorWindowOpenSetting);
}

void OnSettingsChanged_UiGradientWindow() {
    windowCGradOpen.v = Setting_UtilColorGradWindowOpen;
}



BoolWP@ windowCGradOpen = BoolWP(false);

uint n_GradientColors = 4;
Color@[] s_gradientColors = {
    Color(vec3(240. / 255., 025. / 255., 144. / 255.)),
    Color(vec3(202. / 255., 130. / 255., 244. / 255.)),
    Color(vec3(014. / 255., 119. / 255., 192. / 255.)),
    Color(vec3(224. / 255., 242. / 255., 026. / 255.)),
    Color(vec3(Math::Rand(.2, 1.), Math::Rand(.2, 1.), Math::Rand(.2, 1.))),
    Color(vec3(Math::Rand(.2, 1.), Math::Rand(.2, 1.), Math::Rand(.2, 1.))),
    Color(vec3(Math::Rand(.2, 1.), Math::Rand(.2, 1.), Math::Rand(.2, 1.))),
    Color(vec3(Math::Rand(.2, 1.), Math::Rand(.2, 1.), Math::Rand(.2, 1.))),
    Color(vec3(Math::Rand(.2, 1.), Math::Rand(.2, 1.), Math::Rand(.2, 1.))),
    Color(vec3(Math::Rand(.2, 1.), Math::Rand(.2, 1.), Math::Rand(.2, 1.)))
};
ColorTy s_gradientMode = ColorTy::HSL;

string s_gradientPreview = TextGradient2Point0(s_gradientColors, n_GradientColors, s_gradientMode, s_GradientText);
string s_gradientPreviewEsc = EscapeRawToOpenPlanet(s_gradientPreview);
string s_gradientPreviewEscEsc = s_gradientPreviewEsc.Replace("\\$", "\\$$");

string s_gradientTitle = EscapeRawToOpenPlanet(TextGradient2Point0(s_gradientColors, 8, ColorTy::XYZ, "Text Gradients -- Inputs (Text, Colors, Color Mode, etc)"));

int s_lastSetClipboard = -10000;

// [SettingsTab name="Text Gradients"]
void RenderUtilityColorGradients() {
    TextHeading(s_gradientTitle);

    UI::TextWrapped("Input your text below, choose options, \\$fd0then click \\$s\\$fd8'>> Generate! <<'");

    s_GradientText = UI::InputText("Input Text", s_GradientText);
    if (UI::BeginCombo("Color Mode", ColorTyStr(s_gradientMode))) {
        for (uint i = 0; i < 4; i++) {
            auto ct = ColorTy(i);
            if (UI::Selectable(ColorTyStr(ct), ct == s_gradientMode, UI::SelectableFlags::None)) {
                s_gradientMode = ct;
            }
            if (s_gradientMode == ct) { UI::SetItemDefaultFocus(); }
        }
        UI::EndCombo();
    }
    n_GradientColors = UI::SliderInt("Number of Colors", n_GradientColors, 2, s_gradientColors.Length);

    string cs = "\\$888Colors: \\$666";
    for (uint i = 0; i < n_GradientColors; i++) {
        // s_gradientColors[i].v = UI::InputColor3("Color " + (i + 1) + "\\$888 - " + Vec3ToStr(s_gradientColors[i].v), s_gradientColors[i].v);
        s_gradientColors[i].v = UI::InputColor3("Color " + (i + 1), s_gradientColors[i].v);
        cs += "" + (i + 1) + ": " + Vec3ToStr(s_gradientColors[i].v) + ", ";
    }
    UI::TextWrapped(cs);

    TextHeading("Text Gradients -- Output");

    UI::PushFont(stdBold);
    if (UI::Button("\\$s\\$fd8>> Generate! <<")) {
        s_gradientPreview = TextGradient2Point0(s_gradientColors, n_GradientColors, s_gradientMode, s_GradientText);
        s_gradientPreviewEsc = EscapeRawToOpenPlanet(s_gradientPreview);
        s_gradientPreviewEscEsc = s_gradientPreviewEsc.Replace("\\$", "\\$$");
    }
    UI::PopFont();

    UI::Text("Preview:");
    UI::Text(s_gradientPreviewEsc);
    // UI::TextWrapped("Raw: " + s_gradientPreview);
    UI::Text("Raw: " + s_gradientPreview);
    VPad();
    UI::Columns(2, "customSettingsColorClipboardButton", false);
    if (UI::Button("Copy to Clipboard")) {
        IO::SetClipboard(s_gradientPreview);
        s_lastSetClipboard = Time::Now;
    }
    UI::NextColumn();
    if (Time::Now - s_lastSetClipboard < 1500) {
        UI::Text("\\$aaa(Done)");
    }
    UI::Columns(1);
}

void RenderWindowUtilityColorGradients() {
    if (!windowCGradOpen.v) {
        return;
    }
    if (windowCGradOpen.ChangedToTrue()) {
        UI::SetNextWindowSize(800, 600, UI::Cond::Always);
    }

    if (GRADIENT_WINDOW_TITLE == "") {
        GRADIENT_WINDOW_TITLE = "\\$s" + rainbowLoopColorCycle("Color Gradient Tool", true, 1, true, 15);
    }
    if (UI::Begin(GRADIENT_WINDOW_TITLE, windowCGradOpen.v)) {
        RenderUtilityColorGradients();
        UI::End();
    }
}
