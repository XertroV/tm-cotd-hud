/* Migrated to CSV instead of json.
   Should be much faster.
*/

class JsonDictDb {
    /* acts like a dictionary.
       stores entries in in-memory dictionary.
       backed by a csv file that is persisted.
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
            IO::File file(csvPath, IO::FileMode::Read);
            string[] line;
            float lastBreak = Time::Now;
            while (!file.EOF()) {
                if(Time::Now - lastBreak < 4) {
                    lastBreak = Time::Now;
                    yield();
                }
                line = file.ReadLine().Split(",");
                d[line[0]] = line[1];
            }
        }
    }

    string Get(const string &in key) {
        string r = string(d[key]);
        return r;
    }

    void Set(const string &in key, const string &in value) {
        d[key] = value;
        CsvWrite(key, value);
    }

    void SetMany(const string[] &in keys, const string[] &in vals) {
        string toWrite = "";
        for (uint i = 0; i < keys.Length; i++) {
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
