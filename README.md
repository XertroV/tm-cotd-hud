# COTD HUD

Shows division cutoffs + favorited players' times + histogram during qualifier, and allows browsing of past COTD qualifier and division results, along with some utilities.
You can also 'favorite' other players to see their current qualifying time, *live*, during the qualifying round.

This is a beta release. Things might break. (You can reload the plugin from the developer menu if need be.)

This plugin will use a lot of disk space, relatively speaking. Especially over time. Much of this (260 MB) is *all* of the TOTD thumbnails, which are downloading automatically in the background over a few hours.

## Feature Todo

- ✅ Feature parity w/ COTD Stats
- ✅ Histogram for live COTD
- ✅ BetterChat integration for COTD stats (`/{tell-}cotd`)
- 🟦 First-install wizard (configure basic settings and optional stuff)
- 🟦 COTD Historical Explorer
    - ✅ Sync system/workflow for downloading data from APIs
    - ✅ Sync TOTD historical index data | date -> mapUid
    - ✅ Sync COTD challenge (qualifiers) data | challengeIds, startDate timestamp
    - ✅ Refactor sync stuff to use different DBs (will consume fewer resources and do faster writing to disk)
    - ✅ Sync COTD qualifier raw data for times for histogram (ad-hoc)
    - ✅ Sync Map data (ad-hoc)
    - ✅ UI selection layout / styles
    - ✅ Draw Histogram (qualis)
    - ✅ Division browser
    - ✅ Search user in a COTD quali list
    - ✅ Other quali list filters
    - 🟦 Search user all COTDs
    - ✅ (optional, default:off) sync all cotd quali times in bg
    - ✅ "Play this map" button
    - 🟦 TMX link button
    - ✅ TM.IO link button
    - 🟦 List all TOTD maps
    - 🟦 In list: easy favorite-ing + easy click to play
    - 🟦 show your own times / records (not totd but global) -- useful for playing all TOTDs
    - ✅ match results (KO rounds)
    - 🟦 animated histogram replays
    - ✅ replay/snapshot download settings
- 🟦 COTD Friends
  - ✅ Show who's playing this COTD and their times
  - 🟦 BChat integration (`/track-cotd @XertroV`) (or `/add-cotd-friend`)
  - ✅ Highlight the player in historical/explorer UI
  - 🟦 (live) Browse or view players in COTD + one-click add-as-friend
- ✅ Cache Player ID data (like name)
- ✅ Optimization: check current COTD data and don't re-request times unnecessarily -- should be cached once the COTD qualis are over.
- ✅ Optimization -- like above but for division cutoffs
- ✅ Migrate color gradient tool to standalone window via COTD explorer
- ✅ BetterChat integration for gradients `/rgb 28f f28 hey here's my msg` would apply a gradient from `$28f` to `$f28` over `hey here's my msg`.
- 🟦 color alias names for above `/rgb` command. (some done)
- ✅ Debug page: nod viewer quick access (but does't work for values??)
- 🟦 About Page
- 🟦 fix: LAB color gradients to take shortest path to avoid going the 'long way round'
- ✅ bug: clear divisions on new cotd
- ✅ bug fix: restart on new COTD (halts and doesn't update)
- 🟦 export binary data to json files (to make it easy for ppl to use it if they want to).
- ✅ match results
  - ✅ sync comps, rounds, matches
  - ✅ check if results were incomplete
  - ✅ store results in individual files (~60 match results loads in ~20ms)
- ✅ bug: long cotds break (b/c nplayers==0 for so long?)
- ✅ bug: when loading cotd hud data and times are queued to be cached: the hud does not reload after they have been cached.
- ✅ quali rank vs div rank delta (a value of +-64 for each player showing improvement or not in ranking)
- 🟦 Browse players / favorites

### updating external generated code

- remove info.toml
- remove log_trace from codegensupport.as
- sed: `/shared //`

### wizard stuff

* log level
* hud preferences
* histogram
* bg downloads



-----------


todo:

* Add expander thing to hide/show div times
