#if DEV
// void RequestAllCOTDPastResults() {
//     while (PersistentData::mapDb is null || !PersistentData::mapDb.Initialized) yield();
//     auto mapDb = PersistentData::mapDb;
//     auto totdDb = mapDb.histDb.totdDb;
//     while (!totdDb.Initialized) yield();
//     auto keys = totdDb.GetKeys();
//     for (uint i = 0; i < keys.Length; i++) {
//         auto key = keys[i];
//         auto parts = key.Split('-');
//         auto totd = totdDb.Get(key);
//         auto challenge = mapDb.GetChallengesForDate(parts[0], parts[1], parts[2]);
//         for (uint c = 0; c < challenge.Length; c++) {
//             auto cid = challenge[c];
//             print("/get_all/challenges/" + cid + "/records/maps/" + totd.mapUid + " ("+key+" #"+(c+1)+")");
//             print("["+Time::Now+"] Progress: " + i + " / " + keys.Length + " (" + Text::Format("%.1f", float(i) / float(keys.Length) * 100.0) + " %)");
//             auto path = "/get_all/challenges/" + cid + "/records/maps/" + totd.mapUid;
//             CallMapMonitorApiPath(path);
//         }
//     }
// }
#endif
