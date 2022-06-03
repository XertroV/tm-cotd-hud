
Resources::Font@ headingFont = Resources::GetFont("DroidSans.ttf", 20, -1, -1, true, true);;
Resources::Font@ subheadingFont = Resources::GetFont("DroidSans.ttf", 18, -1, -1, true, true);;
Resources::Font@ stdBold = Resources::GetFont("DroidSans-Bold.ttf", 16, -1, -1, true, true);;

/* tooltips */

void AddSimpleTooltip(string msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}

/* button */

void DisabledButton(const string &in text, const vec2 &in size = vec2 ( )) {
    UI::BeginDisabled();
    UI::Button(text, size);
    UI::EndDisabled();
}

bool MDisabledButton(bool disabled, const string &in text, const vec2 &in size = vec2 ( )) {
    if (disabled) {
        DisabledButton(text, size);
        return false;
    } else {
        return UI::Button(text, size);
    }
}

/* padding */

void VPad() { UI::Dummy(vec2(10, 2)); }

void PaddedSep() {
    VPad();
    UI::Separator();
    VPad();
}

/* heading */

void TextHeading(string t) {
    UI::PushFont(headingFont);
    VPad();
    UI::Text(t);
    UI::Separator();
    VPad();
    UI::PopFont();
}


/* sorta functional way to draw elements dynamically as a list or row or other things. */

funcdef void DrawUiElems();
funcdef void DrawUiElemsF(DrawUiElems@ f);

void DrawAsRow(DrawUiElemsF@ f, const string &in id, int cols = 64) {
    int flags = 0;
    flags |= UI::TableFlags::SizingFixedFit;
    flags |= UI::TableFlags::NoPadOuterX;
    if (UI::BeginTable(id, cols, flags)) {
        UI::TableNextRow();
        f(DrawUiElems(_TableNextColumn));
        UI::EndTable();
    }
}

void _TableNextRow() {
    UI::TableNextRow();
}
void _TableNextColumn() {
    UI::TableNextColumn();
}

/* table column pair */

void DrawAs2Cols(const string &in c1, const string &in c2) {
    UI::TableNextColumn();
    UI::Text(c1);
    UI::TableNextColumn();
    UI::Text(c2);
}

/* cooldown colors */

Color@ cooldownStart = Color(vec3(3., 0xc, 0xe) / 16.).ToHSL();
Color@ cooldownMid = Color(vec3(.7,.9,.5)).ToHSL();
Color@ cooldownEnd = Color(vec3(1,1,1)).ToHSL();
string[] cooldownColors = ExtendStringArrs(
    maniaColorForColors(gradientColors(cooldownStart, 20, cooldownMid)),
    maniaColorForColors(gradientColors(cooldownMid, 8, cooldownEnd))
    );

string maniaColorForCooldown(int delta, int cooldownMs, bool escaped = false) {
    uint ix = Math::Round(float((cooldownColors.Length - 1) * Math::Clamp(delta, 0, cooldownMs)) / float(cooldownMs));
    string ret = cooldownColors[ix];
    if (escaped) {
        ret = "\\" + ret;
    }
    return ret;
}

/* loop colors */
Color@ loopColorStart = Color(vec3(0, 73, 53), ColorTy::HSL);
Color@ loopColorMid = Color(vec3(120, 73, 53), ColorTy::HSL);
Color@ loopColorEnd = Color(vec3(240, 73, 53), ColorTy::HSL);
Color@ loopColorStart2 = Color(vec3(360, 73, 53), ColorTy::HSL);
// Color@ loopColorMid = Color(vec3(3., 0xc, 0xe) / 16.).ToHSL();  // h=190

string[] loopColors = ExtendStringArrs(
    ExtendStringArrs(
        maniaColorForColors(gradientColors(loopColorStart, 30, loopColorMid)),
        maniaColorForColors(gradientColors(loopColorMid, 30, loopColorEnd))
    ), maniaColorForColors(gradientColors(loopColorEnd, 30, loopColorStart2))
);
// string[] loopColors = maniaColorForColors(gradientColors(loopColorStart, 60, loopColorEnd));
uint nLoopColors = loopColors.Length;

string rainbowLoopColorCycle(const string &in text, bool escape = false, float loopSecDuration = 1.5, bool fwds = true) {
    float msPerC = 1000. * loopSecDuration / float(nLoopColors);
    float startIx = uint(Time::Now / msPerC) % nLoopColors;
    string ret = "";
    string c;
    for (int i = 0; i < text.Length; i++) {
        c = loopColors[int(fwds ? nLoopColors + startIx - i : startIx + i) % nLoopColors];
        if (escape) ret += "\\";
        ret += c + text.SubStr(i, 1);
    }
    return ret;
}
