Meta::PluginSetting@ GetOtherPluginSettingVar(string pluginId, string varName) {
    auto plugin = Meta::GetPluginFromID(pluginId);
    if (plugin is null) {
        warn("GetOtherPluginSettingVar -- cannot find a plugin with ID '"+pluginId+"'.");
        return null;
    }

    auto _settings = plugin.GetSettings();
    for (uint i = 0; i < _settings.Length; i++) {
        if (_settings[i].VarName == varName) {
            return _settings[i];
        }
    }
    warn("GetOtherPluginSettingVar -- cannot find a setting with variable name '"+varName+"' for plugin '"+pluginId+"'.");
    return null;
}
