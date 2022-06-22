# COTD HUD

Shows division info + times histogram during qualifier, and allows browsing of past COTDs along with full results, graphs, and some utilities.

This is a beta release. This might break.

This plugin will use a lot of disk space, relatively speaking. Especially over time. Much of this (260 MB) is *all* of the TOTD thumbnails, which are downloading automatically in the background over a few hours.

## Feature Todo

- [x] COTD Stats parity
- [x] Histogram for live COTD
- [x] BetterChat integration for COTD stats (`/{tell-}cotd`)
- [ ] First-install wizard (configure basic settings and optional stuff)
- [ ] COTD Historical Explorer
    - [x] Sync system/workflow for downloading data from APIs
    - [x] Sync TOTD historical index data | date -> mapUid
    - [x] Sync COTD challenge (qualifiers) data | challengeIds, startDate timestamp
    - [x] Refactor sync stuff to use different DBs (will consume fewer resources and do faster writing to disk)
    - [x] Sync COTD qualifier raw data for times for histogram (ad-hoc)
    - [x] Sync Map data (ad-hoc)
    - [x] UI selection layout / styles
    - [x] Draw Histogram (qualis)
    - [ ] Division browser
    - [ ] Search user in a COTD quali list
    - [ ] Other quali list filters
    - [ ] Search user all COTDs
    - [ ] (optional, default:off) sync all cotd quali times in bg
    - [x] "Play this map" button
    - [ ] TMX link button
    - [x] TM.IO link button
    - [ ] List all TOTD maps
    - [ ] In list: easy favorite-ing + easy click to play
    - [ ] show your own times / records (not totd but global) -- useful for playing all TOTDs
    - [ ] match results (KO rounds)
    - [ ] animated histogram replays
    - [x] replay/snapshot download settings
- [ ] COTD Friends
  - [ ] Show who's playing this COTD and their times
  - [ ] BChat integration (`/track-cotd @XertroV`) (or `/add-cotd-friend`)
  - [ ] Highlight the player in historical/explorer UI
  - [ ] Browse or view players in COTD + one-click add-as-friend
- [x] Cache Player ID data (like name)
- [x] Optimization: check current COTD data and don't re-request times unnecessarily -- should be cached once the COTD qualis are over.
- [x] Optimization -- like above but for division cutoffs
- [x] Migrate color gradient tool to standalone window via COTD explorer
- [x] BetterChat integration for gradients `/rgb 28f f28 hey here's my msg` would apply a gradient from `$28f` to `$f28` over `hey here's my msg`.
- [ ] color alias names for above `/rgb` command. (some done)
- [x] Debug page: nod viewer quick access (but does't work for values??)
- [ ] About Page
- [ ] fix: LAB color gradients to take shortest path to avoid going the 'long way round'
- [x] bug: clear divisions on new cotd
- [x] bug fix: restart on new COTD (halts and doesn't update)
- [ ] export binary data to json files (to make it easy for ppl to use it if they want to).
- [ ] match results
  - [x] sync comps, rounds, matches
  - [ ] check if results were incomplete
  - [ ] store results in individual files (~60 match results loads in ~20ms)
- [ ] bug: long cotds break (b/c nplayers==0 for so long?)


### first release

- [x] ensure downloading COTD snapshot rankings is behind an option
- [ ] wizard v0 -- mostly to warn about alpha grade software. if anything breaks at the start of COTD use Developer > Reload Plugin > COTD HUD (**TODO before v0.1.0**)
