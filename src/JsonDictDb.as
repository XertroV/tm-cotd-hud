/* Migrated to CSV instead of json.
   Should be much faster.
*/

class JsonDictDb {
    /* acts like a dictionary.
       stores entries in in-memory dictionary.
       backed by a csv file that is persisted.

       WARNING: won't support lines over 128 charts atm due to initialpopulation
    */

    private dictionary@ d = dictionary();
    private string csvPath;

    JsonDictDb(const string &in _path, const string &in _dbId) {
        // super(_path, _dbId);
        csvPath = _path.Replace(".json", ".csv");
        if (!csvPath.EndsWith(".csv")) {
            csvPath += '.csv';
        }
        startnew(CoroutineFunc(_InitialPopulation));
    }

    void _InitialPopulation() {
        if (IO::FileExists(csvPath)) {
            uint start = Time::Now;
            IO::File file(csvPath, IO::FileMode::Read);
            // string[] line;
            string pid, pname;
            float lastBreak = Time::Now;
            uint consumed = 0;
            uint fileSize = file.Size();
            while (!file.EOF()) {
                // if(Time::Now - lastBreak < 4) {
                //     lastBreak = Time::Now;
                //     yield();
                // }
                // line = file.ReadLine().Split(","); -- this doubled the loading time...
                auto b = file.Read(36);
                pid = b.ReadString(36);
                file.Read(1); // should be ,
                pname = file.ReadLine();
                d[pid] = pname;
                // log_trace("player name: " + Get(pid));
            }
            uint end = Time::Now;
            trace_benchmark('DictDb._InitialPopulation ' + csvPath, end - start);
        }
    }

    string Get(const string &in key) {
        string r = string(d[key]);
        return r;
    }

    string[]@ GetKeys() const {
        return d.GetKeys();
    }

    void Set(const string &in key, const string &in value) {
        if (d.Exists(key) && string(d[key]) == value) return;
        d[key] = value;
        CsvWrite(key, value);
    }

    void SetMany(const string[] &in keys, const string[] &in vals) {
        string toWrite = "";
        for (uint i = 0; i < keys.Length; i++) {
            if (d.Exists(keys[i]) && string(d[keys[i]]) == vals[i]) continue;
            toWrite += keys[i] + "," + vals[i] + "\n";
            d[keys[i]] = vals[i];
        }
        CsvAppendRaw(toWrite);
    }

    bool Exists(const string &in key) {
        return d.Exists(key);
    }

    private void CsvPersist() {
        IO::File f(csvPath, IO::FileMode::Write);
        string[] keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            f.WriteLine(keys[i] + "," + string(d[keys[i]]));
        }
        f.Close();
    }

    private void CsvWrite(const string &in key, const string &in value) {
        IO::File f(csvPath, IO::FileMode::Append);
        f.WriteLine(key + "," + value);
        f.Close();
    }

    private void CsvAppendRaw(const string &in toApp) {
        IO::File f(csvPath, IO::FileMode::Append);
        f.Write(toApp);
        f.Close();
    }
}
