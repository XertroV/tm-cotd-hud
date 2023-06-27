class StorageLocation {
  private string _path;
  private string _dir;

  StorageLocation(const string &in fileName, const string &in subDir = '') {
    string[] dirs = {'Storage', Meta::ExecutingPlugin().ID};
    if (subDir.Length > 0) {
      dirs.InsertLast(subDir);
    }
    _dir = IO::FromDataFolder(string::Join(dirs, '/'));
    dirs.InsertLast(fileName);
    _path = IO::FromDataFolder(string::Join(dirs, '/'));
  }

  const string get_Path() {
    return _path;
  }

  const string get_Dir() {
    return _dir;
  }

  void EnsureDirExists() {
    if (!IO::FolderExists(_dir)) {
      IO::CreateFolder(_dir, true);
    }
  }
}
