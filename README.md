# COTD HUD

I *think* the plugin should work if you just copy the whole repo folder into Openplanet/Plugins/cotd-hud-dev/. (I use `./build.sh` normally on WSL.)

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
    - [ ] TM.IO link button
    - [ ] List all TOTD maps
    - [ ] In list: easy favorite-ing + easy click to play
    - [ ] show your own times / records (not totd but global) -- useful for playing all TOTDs
    - [ ] match results (KO rounds)
    - [ ] animated histogram replays
    - [ ] replay download settings
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
- [ ] bug: clear divisions on new cotd
- [ ] bug fix: restart on new COTD (halts and doesn't update)
- [ ] add total players to betterchat commands


### first release

- [ ] ensure downloading COTD snapshot rankings is behind an option
- [ ] wizard v0 -- mostly to warn about alpha grade software. if anything breaks at the start of COTD use Developer > Reload Plugin > COTD HUD

### benchmarks

#### openplanet v1.23.7

- historical db
    - worst persist: 196ms, 97ms (initial sync)
    - load time: 70ms
- player name db
    - load time 156ms (32k rows)

#### openplanet v1.23.8

- historical db
    - worst persist: 219ms, 117ms, 94ms (initial sync)
    - worst persist: 280ms, 193ms, 144ms (initial sync; repeated) -- final persists only 112ms tho
    - load time: 45ms, 40ms, 35ms sometimes
    - typical persist: 106ms mb, 113, 170
- player name db
    - load time 164ms (32k rows)
    - improved algorithm (avoids `.Split`): 75-80ms

## openplanet docs stuff

- no description on nvg::TextBounds -- should probably say what it returns or something.
  - and set nvg::FontFace and nvg::FontSize first.

- nvg::LoadFont params
