

void Main() {
    startnew(DataManager::Main);
}

void Update(float dt) {
    DataManager::Update(dt);
}

void Render() {}
void RenderInterface() {}
void RenderMenu() {}
void RenderMainMenu() {}
// void RenderSettings() {}
void OnSettingsChanged() {}

/* Plan:

UI Components:
- (Use same backend data)
- Div Summary During COTD (like COTDStats)
  - 'friends list' times (favorites via better-chat)
- COTD Explorer

Data Mgmt:
- Namespaced
- Call update with coroutine
- Macro update parameters stored in global vars
- (WRT per-route coros, figure out refs to pass args, or use hacky tmp global vars workaround)
  - like: set var, call global coro, yeild, that coro sets var to null, back to main loop, go again

Watchers:
- change of IsCotd -- joined COTD server
- COTD map -- update when joining new COTD server; init from TMIO
