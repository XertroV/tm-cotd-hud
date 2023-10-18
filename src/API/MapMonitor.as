const string MM_API_PROD_ROOT = "https://map-monitor.xk.io";
const string MM_API_DEV_ROOT = "http://localhost:8000";

#if DEV
[Setting category="[DEV] Debug" name="Local Dev Server"]
bool S_LocalDev = true;
#else
bool S_LocalDev = false;
#endif

const string MM_API_ROOT {
    get {
        if (S_LocalDev) return MM_API_DEV_ROOT;
        else return MM_API_PROD_ROOT;
    }
}

namespace MapMonitor {
    Json::Value@ GetNbPlayersForMap(const string &in mapUid) {
        return CallMapMonitorApiPath('/map/' + mapUid + '/nb_players/refresh');
    }

    Json::Value@ GetChallengeRecords(int challengeId, const string &in mapUid, uint length, uint offset) {
        return CallMapMonitorApiPath("/cached/api/challenges/" + challengeId + "/records/maps/" + mapUid + "?" + LengthAndOffset(length, offset));
    }
    Json::Value@ GetChallengeRecordsCutoffs(int challengeId, const string &in mapUid) {
        return CallMapMonitorApiPath("/cached/api/challenges/" + challengeId + "/records/maps/" + mapUid + "?cutoffs");
    }
}
