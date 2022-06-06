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

/*
    #######  ##     ## ####  ######  ##    ##     ######  ######## ######## ######## #### ##    ##  ######    ######
   ##     ## ##     ##  ##  ##    ## ##   ##     ##    ## ##          ##       ##     ##  ###   ## ##    ##  ##    ##
   ##     ## ##     ##  ##  ##       ##  ##      ##       ##          ##       ##     ##  ####  ## ##        ##
   ##     ## ##     ##  ##  ##       #####        ######  ######      ##       ##     ##  ## ## ## ##   ####  ######
   ##  ## ## ##     ##  ##  ##       ##  ##            ## ##          ##       ##     ##  ##  #### ##    ##        ##
   ##    ##  ##     ##  ##  ##    ## ##   ##     ##    ## ##          ##       ##     ##  ##   ### ##    ##  ##    ##
    ##### ##  #######  ####  ######  ##    ##     ######  ########    ##       ##    #### ##    ##  ######    ######

 QUICK SETTINGS

 */

[SettingsTab name="Quick Settings"]
void RenderSettingsQuickSettings() {
    TextHeading("Quick Settings");

    if (UI::Button("Set Large HUD Histogram (21:9)")) {
        Setting_HudHistogramPos = vec2(.77, .75);
        Setting_HudHistogramSize = vec2(.2, .2);
    }
    AddSimpleTooltip("Set's histogram to lower right corner with width and height set to 20%.\nSuitable for ultrawide monitors.");

    VPad();

    if (UI::Button("Set HUD to show lots of rankings")) {
        Setting_HudShowAboveDiv = 3;
        Setting_HudShowBelowDiv = 3;
        Setting_HudShowTopDivCutoffs = 5;
        Setting_HudShowLastDivPop = true;
        Setting_HudShowPlayerDiv = true;
        Setting_HudShowDeltas = true;
        ::OnSettingsChanged();
    }
    AddSimpleTooltip("This sets the HUD to show:\n"
        + "  - Top 5 div cutoffs \n"
        + "  - 3 divs above yours \n"
        + "  - 3 divs below yours \n"
        + "  - Your div and time \n"
        + "  - # of players in last div \n"
        + "  - Deltas for times compared to yours"
        );
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

    /*

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

    */
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
[Setting category="General" name="Show HUD even if interface is hidden?"]
bool Setting_ShowHudEvenIfInterfaceHidden = true;

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

    /*****/
    TextHeading("Current COTD Data");

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

}



/*
    ########  ######## ########  ##     ##  ######
    ##     ## ##       ##     ## ##     ## ##    ##
    ##     ## ##       ##     ## ##     ## ##
    ##     ## ######   ########  ##     ## ##   ####
    ##     ## ##       ##     ## ##     ## ##    ##
    ##     ## ##       ##     ## ##     ## ##    ##
    ########  ######## ########   #######   ######
DEBUG
*/


// #if DEV || UNIT_TEST

[SettingsTab name="Debug"]
void RenderSettingsDebug() {
    auto gi = DataManager::gi;

    TextHeading("Debug Functions");

    if (UI::Button("Run ListPlayerInfos")) {
        ListPlayerInfos();
    }
    AddSimpleTooltip("Prints all players' names and userIds to the Openplanet log.");

    if (UI::Button("Nod Explorer: Network")) {
        @_DebugNod = gi.GetNetwork();
        _DebugNodWindow.SetTitle("View Nod: Network");
        _DebugNodWindow.Show();
    }

    if (UI::Button("Nod Explorer: Playground")) {
        @_DebugNod = gi.GetCurrentPlayground();
        _DebugNodWindow.SetTitle("View Nod: Playground");
        _DebugNodWindow.Show();
    }

    if (UI::Button("Nod Explorer: InputPort")) {
        @_DebugNod = gi.GetInputPort();
        _DebugNodWindow.SetTitle("View Nod: InputPort");
        _DebugNodWindow.Show();
    }

    VPad();
}

CMwNod@ _DebugNod;
WindowState@ _DebugNodWindow = WindowState("View Nod: ----", false);

// #endif



[SettingsTab name="About"]
void RenderSettingsAbout() {
    TextHeading("About COTD HUD + Explorer");
    VPad();

}
