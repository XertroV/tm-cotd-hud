const string[] SPECIAL_PLAYER_IDS = {
    "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9", // xertrov
#if DEV
    "bd45204c-80f1-4809-b983-38b3f0ffc1ef", // wirtual, useful for testing
    "d46fb45d-d422-47c9-9785-67270a311e25", // elconn
    "55a6453a-8fd8-47da-831b-d4c90ecc7506", // dexter.771
    "955b28c6-cd59-4796-8060-128c66128b9f", // thomas_jean
    "9a126fe8-c35d-44f6-8593-7fe0b3ca7016", // chickenrunnn
    "794a286c-44d9-4276-83ce-431cba7bab74", // F9.Marius89
#endif
    "asdf"
};

bool IsSpecialPlayerId(const string &in pid) {
    return SPECIAL_PLAYER_IDS.Find(pid) >= 0;
}
