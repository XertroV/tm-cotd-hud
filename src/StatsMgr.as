// class DivUpdateParams {
//     DivRow@ dr;

//     DivUpdateParams(DivRow@ dr) {
//         @this.dr = dr;
//     }
// }



// namespace CotdData {
//     string cotdName = "<COTD Name>";
//     array<DivRow@> divRows = {};
//     DivRow@ playerRow;
//     float timeSinceLastUpdate = 0;
//     uint[] visibleDivs = {1, 2};
//     BoolWP@ isCotd = BoolWP(false);
//     GameInfo@ gi;
//     CotdApi@ api;
//     string currMapId;
//     string cotdMapId;
//     uint nDivs = 0;
//     uint nPlayers = 0;
//     uint compId;

//     void Update(float dt) {
//         timeSinceLastUpdate += dt;
//         CheckMapChange();
//     }

//     void CheckMapChange() {
//         auto mid = gi.MapId();
//         if (mid != currMapId) { OnMapChange(); }
//         currMapId = mid;
//         if (gi.IsCotd()) { cotdMapId = mid; }
//     }

//     void UpdateData() {
//         timeSinceLastUpdate = 0;
//         startnew(_UpdateDataCoro);
//     }

//     void _UpdateDataCoro() {

//     }

//     void _UpdateGlobalData() {
//         // update nPlayers, nDivs
//     }

//     void _UpdateDivData() {
//         // update each division
//         auto _d = 1;
//         if (divRows[_d] is null) {
//             @divRows[_d] = DivRow(_d);
//         }
//         auto p = cast<ref>(DivUpdateParams(divRows[_d]));
//         startnew(_UpdateDivisionData, p);
//     }

//     void _UpdateDivisionData(ref@ _p) {
//         auto p = cast<DivUpdateParams>(_p);
//         p.dr.lastUpdateStart = Time::get_Now();
//         if (p.dr.div * 64 < nPlayers) {
//             auto res = api.GetCutoffForDiv(compId, cotdMapId, p.dr.div);
//             p.dr.timeMs = (res.Length > 0) ? res[0]["time"] : MAX_DIV_TIME;
//         } else {
//             p.dr.timeMs = MAX_DIV_TIME;
//         }
//         p.dr.lastUpdateDone = Time::get_Now();
//     }

//     float GetSinceUpdateSecs() {
//         return timeSinceLastUpdate / 1000;
//     }

//     void OnNewPB() {
//         if (gi.IsCotdQuali()) {
//             UpdateData();
//         }
//     }

//     void OnMapChange() {}

//     void OnNewCOTD() {
//         // wipe stats
//         // init COTD data
//         // check if first time posted
//     }

//     // main loop that runs during COTD
//     void COTDMain() {
//         bool _skip = false;
//         float loopMs = 15000;
//         while (true) {
//             _skip = Permissions::PlayOnlineCompetition();           // skip if user can't play COTD
//             _skip = _skip || !gi.IsCotd();                          // skip if we're not in COTD
//             _skip = _skip || (loopMs > timeSinceLastUpdate);        // skip if we updated too recently
//             if (_skip) {
//                 sleep(100);
//                 continue;
//             }

//             // if we haven't skipped then we should update data
//             UpdateData();
//             sleep(50);
//         }
//     }
// }


class Debouncer {
    dictionary@ lastCall = dictionary();
    Debouncer() {}

    bool CanProceed(const string &in callId, uint debounceMs) {
        auto now = Time::get_Now();
        uint lc = now;
        if (lastCall.Get(callId, lc)) {
            bool ret = now - lc > debounceMs;
            if (ret) { lastCall.Set(callId, now); }
            return ret;
        } else {
            lastCall[callId] = now;
            return true;
        }
    }
}
