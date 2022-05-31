/* histDb structure:

{
    "lastUpdated": ts,
    "past_totd": {
        [year]: {
            [month]: {
                lastDay: int,
                days: TotdDay[]
            }
        }
    },
    "challenges": {
        maxId: int,
        items: {[id]: {...}}
    }
}

-- From TM.IO API:
TotdDay {
    campaignId: int,
    map: { mapUid, ... },
    weekday: int,
    monthday: int,
    ...
}

*/


namespace ExplorerManager {
    HistoryDb@ histDb;

    /* Coro to manage historical TOTD data + upkeep */
    void ManageHistoricalTotdData() {
        while (histDb is null) { yield(); }
        /* check current TOTD DB status */

        /* if null / needs sync:
           - begin sync algorithm
           else:
           - begin upkeep algorithm
        */
    }
}
