Resources::Font@ headingFont = Resources::GetFont("DroidSans.ttf", 20, -1, -1, true, true);;
Resources::Font@ stdBold = Resources::GetFont("DroidSans-Bold.ttf", 16, -1, -1, true, true);;

void VPad() { UI::Dummy(vec2(10, 2)); }

void PaddedSep() {
    VPad();
    UI::Separator();
    VPad();
}

void TextHeading(string t) {
    UI::PushFont(headingFont);
    VPad();
    UI::Text(t);
    UI::Separator();
    VPad();
    UI::PopFont();
}



/* global vars for settingsCustom that enable detecting the active tab */

BoolWP@ sTabHudHistogramActive = BoolWP(false);

/* namespace this so we use the explicit reference in Main.as */
namespace SettingsCustom {
    void LoopSetTabsInactive() {
        while (true) {
            sTabHudHistogramActive.Set(false);
            yield();
        }
    }
}


/**

 ##     ## ####  ######  ########  #######   ######   ########     ###    ##     ##
 ##     ##  ##  ##    ##    ##    ##     ## ##    ##  ##     ##   ## ##   ###   ###
 ##     ##  ##  ##          ##    ##     ## ##        ##     ##  ##   ##  #### ####
 #########  ##   ######     ##    ##     ## ##   #### ########  ##     ## ## ### ##
 ##     ##  ##        ##    ##    ##     ## ##    ##  ##   ##   ######### ##     ##
 ##     ##  ##  ##    ##    ##    ##     ## ##    ##  ##    ##  ##     ## ##     ##
 ##     ## ####  ######     ##     #######   ######   ##     ## ##     ## ##     ##

HISTOGRAM

*/


// #[Setting category="HUD Histogram" name="Show HUD Histogram?" description="Shows a histogram graphing the distribution of 200 players' times. Typically those will be the 100 players above you and the 99 players below you. This is useful to see if there are any *breakpoints* that are important to pass (where you would substantially improve in ranking). If you are in the top or bottom 100 players, then the top or bottom 200 times are used instead."]
// #bool Setting_HudShowHistogram = true;

// #[Setting category="HUD Histogram" name="How many bars in the histogram?" min="10" max="100" description="aka. 'bins' or 'buckets'. If set to 25 then the times that appear on the histogram will be grouped into 25 bins, thus there will be 25 vertical bars in the histogram."]
// #uint Setting_HudHistogramBuckets = 42;

// #[Setting category="HUD Histogram" name="Position of HUD Histogram?"]
// #vec2 Setting_HudHistogramPos = vec2(.85, .85);

// #[Setting category="HUD Histogram" name="Size of HUD Histogram?"]
// #vec2 Setting_HudHistogramSize = vec2(.1, .1);

[Setting hidden]
vec3 Setting_HudHistColor1 = vec3(0.803089, 0.68726, 0.105425);
[Setting hidden]
vec3 Setting_HudHistColor2 = vec3(0.105395, 0.56897, 0.779923);
[Setting hidden]
vec3 Setting_HudHistColor3 = vec3(0.043, 0.329, 0.027);
[Setting hidden]
vec3 Setting_HudHistColor4 = vec3(0.934363, 0.534925, 0.0793668);
[Setting hidden]
vec3 Setting_HudHistColor5 = vec3(0.903475, 0.193272, 0.0558131);
[Setting hidden]
vec3 Setting_HudHistPlayerColor = vec3(.9, .2, .5);

vec3[] Setting_Meta_HudHistColors = {
    Setting_HudHistColor1,
    Setting_HudHistColor2,
    Setting_HudHistColor3,
    Setting_HudHistColor4,
    Setting_HudHistColor5
};

[SettingsTab name="HUD Histogram"]
void RenderSettingsHudHistogram() {
    sTabHudHistogramActive.Set(true);

    Setting_HudShowHistogram = UI::Checkbox("Show HUD Histogram?", Setting_HudShowHistogram);
    AddSimpleTooltip("Shows a histogram graphing the distribution of 200 players' times.\n"
        + "Typically those will be the 100 players above you and the 99 players below you.\n"
        + "This is useful to see if there are any *breakpoints* that are important to pass (where you would substantially improve in ranking).\n"
        + "If you are in the top or bottom 100 players, then the top or bottom 200 times are used instead.");

    TextHeading("Position and Size");

    Setting_HudHistogramPos.x = UI::SliderFloat("Horizontal Position (%)", Setting_HudHistogramPos.x, 0, 1);
    Setting_HudHistogramPos.y = UI::SliderFloat("Vertical Position (%)", Setting_HudHistogramPos.y, 0, 1);
    VPad();
    Setting_HudHistogramSize.x = UI::SliderFloat("Width (%)", Setting_HudHistogramSize.x, 0, .5);
    Setting_HudHistogramSize.y = UI::SliderFloat("Height (%)", Setting_HudHistogramSize.y, 0, .5);

    TextHeading("Colors");

    Setting_HudHistPlayerColor = UI::InputColor3("Bar with Your Time", Setting_HudHistPlayerColor);
    AddSimpleTooltip("This will highlight the histogram bar that your time is in with this color.");
    UI::TextWrapped(
        "The histogram spans a maximum of 5 ranks (200 players).\n"
        + "Normally, your rank is the middle one. That isn't the case if you're in the top or bottom 100 players, though."
        );
    VPad();
    Setting_HudHistColor1 = UI::InputColor3("Fastest Rank", Setting_HudHistColor1);
    Setting_HudHistColor2 = UI::InputColor3("Faster Rank", Setting_HudHistColor2);
    Setting_HudHistColor3 = UI::InputColor3("Middle Rank (Yours)", Setting_HudHistColor3);
    Setting_HudHistColor4 = UI::InputColor3("Slower Rank", Setting_HudHistColor4);
    Setting_HudHistColor5 = UI::InputColor3("Slowest Rank", Setting_HudHistColor5);
    if (UI::Button("(Dev) Print Colors to Log")) {
        print(
            "Colors:\n"
            + "Player: " + Vec3ToStr(Setting_HudHistPlayerColor) + "\n"
            + "C1: " + Vec3ToStr(Setting_HudHistColor1) + "\n"
            + "C2: " + Vec3ToStr(Setting_HudHistColor2) + "\n"
            + "C3: " + Vec3ToStr(Setting_HudHistColor3) + "\n"
            + "C4: " + Vec3ToStr(Setting_HudHistColor4) + "\n"
            + "C5: " + Vec3ToStr(Setting_HudHistColor5) + "\n"
        );
    }
}


/*
    ###    ########  ##     ##    ###    ##    ##  ######  ######## ########
   ## ##   ##     ## ##     ##   ## ##   ###   ## ##    ## ##       ##     ##
  ##   ##  ##     ## ##     ##  ##   ##  ####  ## ##       ##       ##     ##
 ##     ## ##     ## ##     ## ##     ## ## ## ## ##       ######   ##     ##
 ######### ##     ##  ##   ##  ######### ##  #### ##       ##       ##     ##
 ##     ## ##     ##   ## ##   ##     ## ##   ### ##    ## ##       ##     ##
 ##     ## ########     ###    ##     ## ##    ##  ######  ######## ########
ADVANCED
*/




// [Setting category="Dev Features" name="Show HUD even if interface is hidden?" description=""]
[Setting hidden]
bool Setting_ShowHudEvenIfInterfaceHidden = false;

[Setting hidden]
bool Setting_AdvCheckPriorCotd = false;

const int s_ReloadClickWait = 15 * 1000;
int s_lastReloadClick = -1 * s_ReloadClickWait;

[SettingsTab name="Advanced"]
void RenderSettingsAdvanced() {
    auto now = Time::get_Now();

    TextHeading("Misc");

    Setting_ShowHudEvenIfInterfaceHidden = UI::Checkbox("Show HUD even if interface is hidden?", Setting_ShowHudEvenIfInterfaceHidden);
    AddSimpleTooltip("This only will ignore whether the interface is hidden or not.\nYou should also enable 'General > Show HUD Always' if you want the HUD to be for-sure visible.");

    // State_UserDidUnbindWhenPrompted = UI::Checkbox("User did unbind when prompted", State_UserDidUnbindWhenPrompted);
    // AddSimpleTooltip("This flag is true if the user unbound giveup when prompted to.\nThis is used to figure out if the rebind prompt should be shown.");

    /*****/
    TextHeading("COTD Data");

    UI::TextWrapped(
        "Reload data from Nadeo API?\n" +
        "\\$E60" + "Please do not abuse this!"
    );
    int _cooldown = s_lastReloadClick + s_ReloadClickWait - now;
    UI::BeginDisabled(_cooldown > 0);
    string b_title = "<< Reload COTD Data " + (_cooldown > 0 ? Text::Format("(%.1f) ", float(_cooldown) / 1000.) : "") + ">>";
    if (UI::Button(b_title)) {
        s_lastReloadClick = now;
        startnew(DataManager::_FullUpdateCotdStatsSeries);
    }
    UI::EndDisabled();

    VPad();

    Setting_AdvCheckPriorCotd = UI::Checkbox("Check Prior COTD?", Setting_AdvCheckPriorCotd);
    AddSimpleTooltip("Check this box to always get data for the previous COTD instead of the current one. (Except when you're actually in COTD.)\nUseful for testing. Make sure to reload COTD data after changing this setting.");

    /*****/
    TextHeading("Quick Settings");

    if (UI::Button("Set Large HUD Histogram (21:9)")) {
        Setting_HudHistogramPos = vec2(.77, .75);
        Setting_HudHistogramSize = vec2(.2, .2);
    }
    AddSimpleTooltip("Set's histogram to lower right corner with width and height set to 20%.\nSuitable for ultrawide monitors.");
}




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


[Setting hidden]
string s_GradientText = ">> Your Input Text! Colors! Wow wee. What a time to be alive. <<";

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

[SettingsTab name="Text Gradients"]
void RenderSettingsColorGradients() {
    TextHeading(s_gradientTitle);

    UI::TextWrapped("Input your text below, choose options, \\$fd0then click \\$s\\$fd8'>> Generate! <<'");

    s_GradientText = UI::InputText("Input Text", s_GradientText);
    if (UI::BeginCombo("Color Mode", ColorTyStr(s_gradientMode))) {
        for (uint i = 0; i < allColorTys.Length; i++) {
            auto ct = allColorTys[i];
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
