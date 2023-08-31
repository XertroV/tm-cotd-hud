bool warned = false;

Meta::PluginSetting@ GetOtherPluginSettingVar(const string &in pluginId, const string &in varName) {
    auto plugin = Meta::GetPluginFromID(pluginId);
    if (plugin is null) {
        if (!warned)
            log_warn("GetOtherPluginSettingVar -- cannot find a plugin with ID '"+pluginId+"'.");
        warned = true;
        return null;
    }

    auto _settings = plugin.GetSettings();
    for (uint i = 0; i < _settings.Length; i++) {
        if (_settings[i].VarName == varName) {
            return _settings[i];
        }
    }
    if (!warned)
        log_warn("GetOtherPluginSettingVar -- cannot find a setting with variable name '"+varName+"' for plugin '"+pluginId+"'.");
    warned = true;
    return null;
}
