class WindowState {
    BoolWP@ visible = BoolWP(false);
    string title;
    WindowState(const string &in title, bool startVisible = false) {
        visible.v = startVisible;
        this.title = title;
    }

    void SetTitle(const string &in newTitle) {
        title = newTitle;
    }

    bool IsVisible() {
        return visible.v;
    }

    void Show() {
        visible.v = true;
    }

    void Hide() {
        visible.v = false;
    }

    void Toggle() {
        visible.v = !visible.v;
    }

    bool IsAppearing() {
        return visible.ChangedToTrue();
    }

    bool IsDisappearing() {
        return visible.ChangedToFalse();
    }

    /* this avoids IsAppearing/IsDisappearing from triggering multiple times */
    void Done() {
        visible.v = visible.v;
    }
}
