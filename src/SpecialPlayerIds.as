const string[] SPECIAL_PLAYER_IDS = {
    "0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9", // xertrov
    "d320a237-1b0a-4069-af83-f2c09fbf042e", // AR_Mudda
    "7398eeb6-9b4e-44b8-a7a1-a2149955ac70", // Miss
    "2740dfa4-dd5f-4696-b010-c1fca43a791c", // Chips
#if DEV
    "bd45204c-80f1-4809-b983-38b3f0ffc1ef", // wirtual, useful for testing
    "d46fb45d-d422-47c9-9785-67270a311e25", // elconn
    "55a6453a-8fd8-47da-831b-d4c90ecc7506", // dexter.771
    "955b28c6-cd59-4796-8060-128c66128b9f", // thomas_jean
    "9a126fe8-c35d-44f6-8593-7fe0b3ca7016", // chickenrunnn
    "794a286c-44d9-4276-83ce-431cba7bab74", // F9.Marius89
    "05477e79-25fd-48c2-84c7-e1621aa46517", // GranaDy
    "da4642f9-6acf-43fe-88b6-b120ff1308ba", // Scrapie98
    "fb678553-f730-442a-a035-dfc50f4a5b7b", // Mime
    "0c857beb-fd95-4449-a669-21fb310cacae", // Carl Jr
    "e3ff2309-bc24-414a-b9f1-81954236c34b", // Lars
    "bfcf62ff-0f9e-40aa-b924-11b9c70b8a09", // Majijej
    "65341b56-1625-4df2-8fb4-ad7145c03c34", // Micka
    "d7c02452-7333-49df-8a31-4cf932475007", // Sophie
    "3bb0d130-637d-46a6-9c19-87fe4bda3c52", // Spammiej
    "24b09acf-f745-408e-80fc-b1141054504c", // Simplynick
    "07ff9d3a-849e-496e-aca9-6ac41ed23e75", // MEDICINE9268
    "af30b7a1-fc37-485f-94bf-f00e39805d8c", // Ixxonn
#endif
    "asdf"
};

bool IsSpecialPlayerId(const string &in pid) {
    return SPECIAL_PLAYER_IDS.Find(pid) >= 0;
}
