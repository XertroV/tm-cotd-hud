# COTD HUD

## Feature Todo

- [x] COTD Stats parity
- [x] Histogram for live COTD
- [x] BetterChat integration for COTD stats (`/{tell-}cotd`)
- [ ] COTD Historical Explorer
    - [x] Sync system/workflow for downloading data from APIs
    - [x] Sync TOTD historical index data | date -> mapUid
    - [x] Sync COTD challenge (qualifiers) data | challengeIds, startDate timestamp
    - [x] Refactor sync stuff to use different DBs (will consume fewer resources and do faster writing to disk)
    - [x] Sync COTD qualifier raw data for times for histogram (ad-hoc)
    - [x] Sync Map data (ad-hoc)
    - [x] UI selection layout / styles
    - [ ] Draw Histogram
- [ ] COTD Friends
  - [ ] Show who's playing this COTD and their times
  - [ ] BChat integration (`/track-cotd @XertroV`) (or `/add-cotd-friend`)
  - [ ] Highlight the player in historical/explorer UI
  - [ ] Browse or view players in COTD + one-click add-as-friend
- [ ] Cache Player ID data (like name)
- [ ] Optimization: check current COTD data and don't re-request times unnecessarily -- should be cached once the COTD qualis are over.
- [ ] About Page
