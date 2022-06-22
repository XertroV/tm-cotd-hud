UI::Font@ bigHeadingFont = UI::LoadFont("DroidSans.ttf", 26, -1, -1, true, true);
UI::Font@ headingFont = UI::LoadFont("DroidSans.ttf", 20, -1, -1, true, true);
UI::Font@ subheadingFont = UI::LoadFont("DroidSans.ttf", 18, -1, -1, true, true);
UI::Font@ subheadingBolFont = UI::LoadFont("DroidSans-Bold.ttf", 18, -1, -1, true, true);
UI::Font@ stdBold = UI::LoadFont("DroidSans-Bold.ttf", 16, -1, -1, true, true);

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

bool ButtonLink(const string &in label, const string &in href, const vec2 &in size = vec2 ( )) {
    bool clicked = UI::Button(label, size);
    if (clicked)
        OpenBrowserURL(href);
    return clicked;
}

/* padding */

void VPad() { UI::Dummy(vec2(10, 2)); }

void PaddedSep() {
    VPad();
    UI::Separator();
    VPad();
}

/* heading & text */

void TextBigStrong(const string &in t) {
    UI::PushFont(subheadingBolFont);
    UI::TextWrapped(t);
    UI::PopFont();
}

void TextHeading(string t, bool withLine = true, DrawUiElems@ func = null) {
    VPad();
    UI::PushFont(headingFont);
    UI::AlignTextToFramePadding();
    UI::Text(t);
    UI::PopFont();
    if (func !is null) {
        UI::SameLine();
        func();
    }
    if (withLine) UI::Separator();
    VPad();
}

void TextBigHeading(string t, bool withLine = false) {
    UI::PushFont(bigHeadingFont);
    VPad();
    UI::Text(t);
    if (withLine) UI::Separator();
    VPad();
    UI::PopFont();
}

void CenteredTextBigHeading(const string &in t, const string &in subtitle = "") {
    DrawCenteredInTable(t, function(ref@ r) {
        StrPairBox@ b = cast<StrPairBox@>(r);
        UI::PushFont(bigHeadingFont);
        UI::Text(b.fst);
        UI::PopFont();
    }, StrPairBox(t, subtitle));
    if (subtitle.Length > 0) {
        DrawCenteredInTable(subtitle, function(ref@ r) {
            StrPairBox@ b = cast<StrPairBox@>(r);
            UI::PushFont(headingFont);
            UI::Text(b.snd);
            UI::PopFont();
        }, StrPairBox(t, subtitle));
    }
}

/* tables */

int TableFlagsFixed() {
    return UI::TableFlags::SizingFixedFit;
}
int TableFlagsFixedSame() {
    return UI::TableFlags::SizingFixedSame;
}
int TableFlagsStretch() {
    return UI::TableFlags::SizingStretchProp;
}
int TableFlagsStretchSame() {
    return UI::TableFlags::SizingStretchSame;
}
int TableFBorders() {
    return UI::TableFlags::Borders;
}


void DrawCenteredInTable(const string &in tableId, DrawUiElems@ f) {
    /* cast the function to a ref so we can delcare an anon function that casts it back to a normal function and then calls it. */
    DrawCenteredInTable(tableId, function(ref@ _r){
        DrawUiElems@ r = cast<DrawUiElems@>(_r);
        r();
    }, f);
}

void DrawCenteredInTable(const string &in tableId, DrawUiElemsWRef@ f, ref@ r) {
    // UI::PushStyleColor(UI::Col::TableBorderLight, vec4(1,1,1,1));
    // UI::PushStyleColor(UI::Col::TableBorderStrong, vec4(1,1,1,1));
    // UI::PopStyleColor(2);
    //  | TableFBorders()
    if (UI::BeginTable(tableId, 3, TableFlagsStretch())) {
        /* CENTERING!!! */
        UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("content", UI::TableColumnFlags::WidthFixed);
        UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);
        UI::TableNextColumn();
        UI::TableNextColumn();
        f(r);
        UI::TableNextColumn();
        UI::EndTable();
    }
}


bool BeginCenteredTable(const string &in id, uint columns = 1) {
    if (UI::BeginTable(id, columns + 2, TableFlagsStretch())) {
        UI::TableSetupColumn("left", UI::TableColumnFlags::WidthStretch);
        UI::TableSetupColumn("content", UI::TableColumnFlags::WidthFixed);
        UI::TableSetupColumn("right", UI::TableColumnFlags::WidthStretch);
        UI::TableNextColumn();
        UI::TableNextColumn();
        return true;
    }
    return false;
}

void EndCenteredTable() {
    UI::TableNextColumn();
    UI::EndTable();
}


/* sorta functional way to draw elements dynamically as a list or row or other things. */

funcdef void DrawUiElems();
funcdef void DrawUiElemsWRef(ref@ r);
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

void DrawAs2Cols(DrawUiElems@ f1, DrawUiElems@ f2) {
    UI::TableNextColumn();
    f1();
    UI::TableNextColumn();
    f2();
}

void DrawAs2Cols(DrawUiElemsWRef@ f1, ref@ r1, DrawUiElemsWRef@ f2, ref@ r2) {
    UI::TableNextColumn();
    f1(r1);
    UI::TableNextColumn();
    f2(r2);
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
    uint ix = uint(Math::Round(float((cooldownColors.Length - 1) * Math::Clamp(delta, 0, cooldownMs)) / float(cooldownMs)));
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

string rainbowLoopColorCycle(const string &in text, bool escape = false, float loopSecDuration = 1.5, bool fwds = true, float startIx = -1) {
    float msPerC = 1000. * loopSecDuration / float(nLoopColors);
    if (startIx < 0)
        startIx = uint(Time::Now / msPerC) % nLoopColors;
    string ret = "";
    string c;
    for (int i = 0; i < text.Length; i++) {
        c = loopColors[int(Math::Abs(fwds ? (nLoopColors + startIx + text.Length - i) : startIx + i)) % nLoopColors];
        if (escape) ret += "\\";
        ret += c + text.SubStr(i, 1);
    }
    return ret;
}
