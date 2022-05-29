[Setting category="General" name="Show HUD in COTD Qualifier?"]
bool Setting_ShowHudInCotdQuali = true;

[Setting category="General" name="Show HUD in COTD KO?"]
bool Setting_ShowHudInCotdKO = true;

[Setting category="General" name="Show HUD Always?" description="Useful for repositioning the window, or checking last COTD stats, etc. NOTE: the HUD will still be hidden when the interface is hidden (see 'Dev' tab for override)."]
bool Setting_ShowHudAlways = false;

[Setting category="General" name="HUD Window Locked?" description="When enabled: you can drag the window around. Combine with 'Show HUD Always' to allow positioning the window right now."]
bool Setting_HudWindowLocked = true;




[Setting category="HUD" name="Show div 1 cutoff?"]
bool Setting_HudShowDiv1Cutoff = true;

[Setting category="HUD" name="Show your current div and time?"]
bool Setting_HudShowPlayerDiv = true;

[Setting category="HUD" name="Show cutoffs for how many higher divs?" min="0" max="5" description="0: No divs with cutoffs above your time. 1: The cutoff for the div above yours. 2: That one and the next div up. etc"]
uint Setting_HudShowAboveDiv = 1;

[Setting category="HUD" name="Show cutoffs for how many lower divs?" min="0" max="5" description="0: No divs with cutoffs below your time. 1: The cutoff for your div. 2: Your div and the one below it. etc"]
uint Setting_HudShowPlayerDivCutoff = 1;

[Setting category="HUD" name="Show deltas?" description="Example: `-0:02.252` or `+0:11.002`"]
bool Setting_HudShowDeltas = true;



[Setting category="Dev Features" name="Show HUD even if interface is hidden?" description="This only will ignore whether the interface is hidden or not. You should also enable 'Show HUD Always' if you want the HUD to be for-sure visible."]
bool Setting_ShowHudEvenIfInterfaceHidden = false;
