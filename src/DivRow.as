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
    bool visible = true;
    RowTy ty;

    DivRow(uint div = 0, uint timeMs = MAX_DIV_TIME, RowTy ty = RowTy::Cutoff) {
        this.div = div;
        this.timeMs = timeMs;
        this.ty = ty;
    }

    string FmtDiv() {
        return (div > 0) ? "" + div : "--";
    }

    string FmtTime() {
        return ((this.timeMs > 0) && (this.timeMs < MAX_DIV_TIME >> 3)) ? Time::Format(this.timeMs) : "-:--.---";
    }

    int opCmp(DivRow@ other) {
        return this.timeMs == other.timeMs ? 0 : (this.timeMs > other.timeMs ? 1 : -1);
    }
}
