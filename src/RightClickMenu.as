bool RightClicked(const string &in id, bool inTable = false) {
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(2, 2));
    UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
    // the item we want to check right click for
    vec4 rect = UI::GetItemRect();
    // original position of the cursor so we can return it here later
    vec2 origPos = UI::GetCursorPos();
    // draw an invisible button to check for right click
    // set pos of button
    vec2 pos = vec2(rect.x, rect.y) - UI::GetWindowPos();
    UI::SetCursorPos(pos);
    // draw
    vec2 btnSize = vec2(rect.z, rect.w);
    bool ret = UI::InvisibleButton(id, btnSize, UI::ButtonFlags::MouseButtonRight);
    // bool ret = UI::Button(id, btnSize);
    // return cursor to original pos
    // float yOffset = UI::GetFrameHeightWithSpacing()
    //     - (inTable ? 0 : (UI::GetTextLineHeightWithSpacing() - UI::GetTextLineHeight()));
    float yOffset = inTable ? UI::GetFrameHeightWithSpacing() : 0;
    UI::SetCursorPos(origPos - vec2(0, yOffset));
    UI::PopStyleVar(2);
    return ret;
}

// draw a right click menu where the inner parts are drawn by `f`
void RightClickMenu(const string &in id, DrawUiElems@ f) {
    if (RightClicked(id)) {
        UI::OpenPopup(id);
    }
    if (UI::BeginPopup(id)) {
        f();
        UI::EndPopup();
    }
}
