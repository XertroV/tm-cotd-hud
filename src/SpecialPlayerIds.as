dictionary@ SPECIAL_PLAYER_IDS = {
    { "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9", true }, // xertrov
    { "2740dfa4-dd5f-4696-b010-c1fca43a791c", true }, // Chips
    { "7398eeb6-9b4e-44b8-a7a1-a2149955ac70", true }, // Miss
    { "d320a237-1b0a-4069-af83-f2c09fbf042e", true }, // AR_Mudda -- for 3x COTD wins on the same TOTD
#if DEV
    { "bd45204c-80f1-4809-b983-38b3f0ffc1ef", true }, // wirtual, useful for testing
    { "d46fb45d-d422-47c9-9785-67270a311e25", true }, // elconn
    { "55a6453a-8fd8-47da-831b-d4c90ecc7506", true }, // dexter.771
    { "955b28c6-cd59-4796-8060-128c66128b9f", true }, // thomas_jean
    { "9a126fe8-c35d-44f6-8593-7fe0b3ca7016", true }, // chickenrunnn
    { "794a286c-44d9-4276-83ce-431cba7bab74", true }, // F9.Marius89
    { "05477e79-25fd-48c2-84c7-e1621aa46517", true }, // GranaDy
    { "da4642f9-6acf-43fe-88b6-b120ff1308ba", true }, // Scrapie98
    { "fb678553-f730-442a-a035-dfc50f4a5b7b", true }, // Mime
    { "0c857beb-fd95-4449-a669-21fb310cacae", true }, // Carl Jr
    { "e3ff2309-bc24-414a-b9f1-81954236c34b", true }, // Lars
    { "bfcf62ff-0f9e-40aa-b924-11b9c70b8a09", true }, // Majijej
    { "65341b56-1625-4df2-8fb4-ad7145c03c34", true }, // Micka
    { "d7c02452-7333-49df-8a31-4cf932475007", true }, // Sophie
    { "3bb0d130-637d-46a6-9c19-87fe4bda3c52", true }, // Spammiej
    { "24b09acf-f745-408e-80fc-b1141054504c", true }, // Simplynick
    { "07ff9d3a-849e-496e-aca9-6ac41ed23e75", true }, // MEDICINE9268
    { "af30b7a1-fc37-485f-94bf-f00e39805d8c", true }, // Ixxonn
    { "de590c4e-f98c-4783-afa8-a01efb069ceb", true }, // LinkTM
    { "b05db0f8-d845-47d2-b0e5-795717038ac6", true }, // Massa
    { "961d1145-8c7b-48c3-9191-0d1d91e44a4a", true }, // Dog..
    { "1336b019-0d7d-43f7-b227-ff336f8b7140", true }, // Mawi__
#endif
    {"asdf", true}
};

DictOfBool_WriteLog@ specialPlayerIds;

void InitSpecialPlayers() {
    @specialPlayerIds = DictOfBool_WriteLog(PersistentData::dataFolder, "specialPlayers.bin");
    specialPlayerIds.AwaitInitialized();
    if (specialPlayerIds.GetSize() == 0) {
        auto pids = SPECIAL_PLAYER_IDS.GetKeys();
        for (uint i = 0; i < pids.Length; i++) {
            if (pids[i] == "asdf") continue;
            specialPlayerIds.Set(pids[i], true);
        }
    }
    auto pid = GI::PlayersId();
    if (!specialPlayerIds.Exists(pid)) {
        specialPlayerIds.Set(pid, true);
    }
}

bool IsSpecialPlayerId(const string &in pid) {
    return specialPlayerIds.Exists(pid) && specialPlayerIds.Get(pid);
}

void AddSpecialPlayer(const string &in pid) {
    specialPlayerIds.Set(pid, true);
}
void RemoveSpecialPlayer(const string &in pid) {
    specialPlayerIds.Set(pid, false);
}
