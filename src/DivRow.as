const int MAX_DIV_TIME = 9999999;
// MAX_DIV_TIME of 9999999 is 10k seconds.
// We can safely `>> 3` is roughly division by 8 (which is still 1k+ seconds).
// Since COTD is at most ~120s, we can safely assume values for .time that are greater than (MAX_DIV_TIME >> 3) are dummy times.
// So we use `MAX_DIV_TIME >> 3` as a comparison value.


enum RowTy {
    Cutoff,
    Player,
}


class DivRow {
    uint div;
    uint timeMs;
    uint lastUpdateStart = 0;
    uint lastUpdateDone = 0;
    bool _visible = false;
    Json::Value lastJson;
    RowTy ty;

    DivRow(uint div = 0, uint timeMs = MAX_DIV_TIME, RowTy ty = RowTy::Cutoff) {
        this.div = div;
        this.timeMs = timeMs;
        this.ty = ty;
    }

    bool get_visible() {
        return this._visible && this.timeMs < MAX_DIV_TIME;
    }

    void set_visible(const bool _v) {
        this._visible = _v;
    }

    string FmtDiv() {
        return (div > 0) ? Text::Format("%2d", div) : "--";
    }

    string FmtTime() {
        return ((this.timeMs > 0) && (this.timeMs < MAX_DIV_TIME >> 3)) ? Time::Format(this.timeMs) : "-:--.---";
    }

    string FmtDivAndTime() {
        return this.FmtDiv() + " (" + this.FmtTime() + ")";
    }

    int opCmp(DivRow@ other) {
        return this.timeMs == other.timeMs ? 0 : (this.timeMs > other.timeMs ? 1 : -1);
    }

    string ToString() {
        return "DivRow("
            + "div=" + this.div + ", "
            + "timeMs=" + this.timeMs + ", "
            + "lastUpdateStart=" + this.lastUpdateStart + ", "
            + "lastUpdateDone=" + this.lastUpdateDone + ", "
            + "Δ=" + (this.lastUpdateDone - this.lastUpdateStart) + ", "
            + "visible=" + this.visible + ", "
            + "ty=" + tostring(this.ty)
            + ")";

    }
}
