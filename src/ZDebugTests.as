void DebugTest_JsonWritePrecision() {
    auto j = Json::Object();
    j['test1'] = 1;
    j['test5'] = 5;
    j['test10'] = 10;
    j['test50'] = 50;
    j['test100'] = 100;
    j['test500'] = 500;
    j['test1000'] = 1000;
    j['test5000'] = 5000;
    j['test10000'] = 10000;
    j['test50000'] = 50000;
    j['test100000'] = 100000;
    j['test500000'] = 500000;
    j['test1000000'] = 1000000;
    j['test5000000'] = 5000000;
    j['test10000000'] = 10000000;
    j['test50000000'] = 50000000;
    print(Json::Write(j));
}
