namespace DataToClear {
    Json::Value@[] values;

    void Add(Json::Value@ j) {
        values.InsertLast(j);
    }

    void RemoveCheck() {
        if (values.Length > 0) {
            values.RemoveLast();
        }
    }
}

Json::Value@ ClearJsonSlowly(Json::Value@ j) {
    DataToClear::Add(j);
    return j;
}

void ClearJsonSlowly_Loop() {
    while (true) {
        DataToClear::RemoveCheck();
        // we do multiple yeilds here to avoid under sleeping if there are long frames.
        for (int i = 0; i < 10; i++) yield();
    }
}
