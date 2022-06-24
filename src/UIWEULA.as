/*
    THIS FILE IS EXPLICITLY IN THE PUBLIC DOMAIN!
    - the authors
*/

[Setting hidden]
bool Setting_EulaWindow = true;

WindowState w_EulaFirstLoad('COTD HUD + Explorer EULA', Setting_EulaWindow);

namespace WEULA {
    void Render() {
        if(!w_EulaFirstLoad.IsVisible()) {
            Setting_EulaWindow = false;
        }
        if (Setting_EulaAgreement) Setting_EulaWindow = false;
        if (Setting_EulaWindow) {
            if (!w_EulaFirstLoad.IsVisible()) return;
            if (w_EulaFirstLoad.IsAppearing()) {
                vec2 size = vec2(1100, 800);
                UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::Always);
                vec2 wh = vec2(Draw::GetWidth(), Draw::GetHeight());
                vec2 center = wh / 2.;
                vec2 tl = center - (size / 2.);
                UI::SetNextWindowPos(int(tl.x), int(tl.y));
            }
            UI::Begin(w_EulaFirstLoad.title, w_EulaFirstLoad.visible.v);
                RenderSettingsEula();
            UI::End();
        }
    }
}

[Setting hidden]
bool Setting_EulaAgreement = false;  // default must be false

bool State_CheckedEulaAgreeBox = false;  // false on load as reset

[SettingsTab name="EULA"]
void RenderSettingsEula() {
    CenteredTextBigHeading("\"End User License Agreement\"", BcCommands::ByCotdHudStr);
    UI::PushFont(subheadingFont);
    UI::TextWrapped(string::Join(
        { "You are asked to agree to the following 'End User License Agreement' (EULA) for COTD HUD + Explorer (i.e., \"this work\") in exchange for the utility it provides.\nIn this EULA, \"we\" refers to the developers of this software."
        , ""
        , "The EULA is that you both acknowledge and consent to all of the following:"
        , ""
        , "\t→\t This software will use \\$<\\$6efyour Trackmania account\\$> to request \\$<\\$f84A LOT\\$> of data from Nadeo's APIs. We do not know how Nadeo will react to this, or whether it will have an impact on your account. Usage of this software implies consent to download potentially a lot of data. At least 100s of KB for each COTD that you view the data of or participate in (COTN and COTM are about 10% the size)."
        , ""
        , "\t→\t \\$<\\$ee2This software is provided with no warranties or guarantees.\\$> If it is helpful to you then we are glad for that. But the authors will not accept responsibility for any harm that comes to you from use of this software, including any matters related to the above point."
        , ""
        , "\t→\t Any additional requirements as specified under any license that the distribution of this work that you are using is published under."
        , ""
        , "\t→\t \\$<\\$ee2Preliminary downloads will begin as soon as you click 'Accept EULA'.\\$> \\$<\\$bbb(Current COTD requests may also occur in the background at any time whenever Trackmania is open -- though this should be infrequent when outside of a COTD event.)\\$>"
        , ""
        , "\t→\t Revoking this agreement requires restarting Trackmania."
        , ""
        // , "\t→\t Your consent will be sought before gathering telemetry if this software ever integrates such functionality. Currently no such functionality is present. (In such a case, this clause must be replaced for the author to be considered honest.)"
        // , ""
        , "\t→\t The source code for this software (or an ancestor) is and/or has been released under a public domain license. Therefore, it is left to you -- as your responsibility -- both to verify the integrity, behavior, and origin of this software and to only agree to this EULA if said integrity, behavior, and origin meets your relevant standards."
        , ""
        , "\t→\t (Beta clause) This software may have breaking version changes which require you to re-download any and all data. Currently the DB api is unstable and we are not sure that it will remain stable."
        , ""
        , "If you consent and agree to the above, please check the following box and press the button. (This plugin will not be functional otherwise.)"
        }, "\n"));
    VPad();
    VPad();
    VPad();
    if (!Setting_EulaAgreement) {
        DrawCenteredInTable("cotd-hud-eula-agree-box", function() {
            UI::PushFont(bigHeadingFont);
            UI::AlignTextToFramePadding();
            UI::Text("→ ");
            UI::SameLine();
            UI::AlignTextToFramePadding();
            State_CheckedEulaAgreeBox = UI::Checkbox("  ←   I Agree", State_CheckedEulaAgreeBox);
            UI::PopFont();
        });
        VPad();
        VPad();
        DrawCenteredInTable("cotd-hud-eula-agree-btn", function() {
            UI::PushFont(headingFont);
            if (MDisabledButton(!State_CheckedEulaAgreeBox, "Accept EULA")) {
                State_CheckedEulaAgreeBox = false;  // if revoke is pressed this should be reset; so reset it now.
                Setting_EulaAgreement = true;
                startnew(ShowUiExplorerSlightDelay);
            }
            UI::PopFont();
        });
    } else {
        CenteredTextBigHeading("\"End User License Agreement\" Status");
        VPad();
        TextHeading(">> You have agreed to the EULA! <<", false);
        VPad();
        UI::TextWrapped("If you would like to revoke consent: you will need to click this button and then restart Trackmania (or this plugin via the Developer menu).\nAll existing data will remain but it will not be accessible through this plugin until you accept the EULA again.");
        VPad();
        if (UI::Button("Revoke EULA Consent")) {
            Setting_EulaAgreement = false;
        }
        AddSimpleTooltip("Remember: you must restart\nTrackmania for this to take effect!");
    }
    UI::PopFont();
    VPad();
    VPad();
    UI::Separator();
    VPad();
    VPad();
    if (Setting_EulaAgreement && !Setting_EulaWindow) {
        if (UI::Button("(Debug) Reset EULA conset & also show EULA popup window")) {
            Setting_EulaWindow = true;
            Setting_EulaAgreement = false;
        }
    }
}

void ShowUiExplorerSlightDelay() {
    sleep(250);
    CotdExplorer::windowActive.v = true;
}
