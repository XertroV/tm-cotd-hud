[Setting category="General" name="HUD Enabled?" description="If false, the HUD will not be displayed."]
bool Setting_ShowHud = true;

[Setting category="General" name="Show HUD in COTD Qualifier?"]
bool Setting_ShowHudInCotdQuali = true;

[Setting category="General" name="Show HUD in COTD KO?"]
bool Setting_ShowHudInCotdKO = true;

[Setting category="General" name="Show HUD Always?" description="Useful for repositioning the window, or checking last COTD stats, etc. NOTE: the HUD will still be hidden when the interface is hidden."]
bool Setting_ShowHudAlways = false;

[Setting category="General" name="HUD Window Locked?" description="When disabled: you can drag the window around. Combine with 'Show HUD Always' to allow positioning the window right now."]
bool Setting_HudWindowLocked = false;

[Setting category="General" name="Show HUD even if interface is hidden?"]
bool Setting_ShowHudEvenIfInterfaceHidden = true;


[Setting category="HUD" name="Show deltas?" description="Example: `-0:02.252` or `+0:11.002`"]
bool Setting_HudShowDeltas = true;

[Setting category="HUD" name="Show cutoffs for how many top divs?" min="0" max="5" description="0: No top div cutoffs. 1: Div 1 cutoff. 2: Cutoffs for Divs 1 and 2. etc"]
int Setting_HudShowTopDivCutoffs = 1;

[Setting category="HUD" name="Show your current div and time?"]
bool Setting_HudShowPlayerDiv = true;

[Setting category="HUD" name="Show cutoffs for how many higher divs?" min="0" max="5" description="0: No divs with cutoffs above your time. 1: The cutoff for the div above yours. 2: That one and the next div up. etc"]
int Setting_HudShowAboveDiv = 1;

[Setting category="HUD" name="Show cutoffs for how many lower divs?" min="0" max="5" description="0: No divs with cutoffs below your time. 1: The cutoff for your div. 2: Your div and the one below it. etc"]
int Setting_HudShowBelowDiv = 1;

[Setting category="HUD" name="Show cutoffs for all divs?" description="Yup. ALL of them."]
bool Setting_HudShowAllDivs = false;

[Setting category="HUD" name="Show last div population?" description="..."]
bool Setting_HudShowLastDivPop = false;

[Setting category="HUD" name="Show your time in rainbow?" description="..."]
bool Setting_HudAlwaysShowRainbowPlayerTime = false;

[Setting category="HUD" name="Show your time in rainbow when you're in Div 1?" description="..."]
bool Setting_HudShowMyTimeAsRainbowInDiv1 = true;

[Setting category="HUD" name="Show times of favorited players?" description="Right click on a player's name in the explorer to favorite or unfavorite them."]
bool Setting_HudShowFavoritedPlayersTimes = false;

// [Setting category="HUD Histogram" name="Show HUD Histogram?" description="Shows a histogram graphing the distribution of 200 players' times. Typically those will be the 100 players above you and the 99 players below you. This is useful to see if there are any *breakpoints* that are important to pass (where you would substantially improve in ranking). If you are in the top or bottom 100 players, then the top or bottom 200 times are used instead."]
[Setting hidden]
bool Setting_HudShowHistogram = true;

// [Setting category="HUD Histogram" name="How many bars in the histogram?" min="10" max="100" description="aka. 'bins' or 'buckets'. If set to 25 then the times that appear on the histogram will be grouped into 25 bins, thus there will be 25 vertical bars in the histogram."]
[Setting hidden]
uint Setting_HudHistogramBuckets = 42;

// [Setting category="HUD Histogram" name="Position of HUD Histogram?"]
[Setting hidden]
vec2 Setting_HudHistogramPos = vec2(.763, .772);

// [Setting category="HUD Histogram" name="Size of HUD Histogram?"]
[Setting hidden]
vec2 Setting_HudHistogramSize = vec2(.2, .16);



void SetDevSettings() {
    Setting_ShowHudAlways = true;
    Setting_HudShowAboveDiv = 3;
    Setting_HudShowBelowDiv = 3;
    Setting_HudShowTopDivCutoffs = 3;
    Setting_HudShowAllDivs = true;
    Setting_HudShowHistogram = true;
    Setting_HudHistogramPos = vec2(.77, .75);
    Setting_HudHistogramSize = vec2(.2, .2);
}
