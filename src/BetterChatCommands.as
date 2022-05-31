#if DEPENDENCY_BETTERCHAT

namespace BcCommands {
    void _SendMsg(const string &in text) {
        BetterChat::SendChatMessage(text);
    }

    void _LocalMsg(const string &in text) {
        BetterChat::AddSystemLine(text);
    }

    class TellCotdCommand : BetterChat::ICommand {
        bool send;

        TellCotdCommand(bool send) {
            this.send = send;
        }

        string Icon() {
            return "\\$eb1" + Icons::Trophy;
        }

        string Description() {
            auto _action = send ? "Tells chat" : "Prints";
            return _action + " which division this is and COTD cutoff stats.";
        }

        void Run(const string &in text) {
            auto c1 = Color(vec3(0.980, 0.980, 0.431), ColorTy::RGB);  // #fafa6e
            c1.AsHSL();
            auto c2 = Color(vec3(0.941, 0.465, 0.162), ColorTy::RGB);  // #F05D15
            c2.AsHSL();
            string msg = TextGradient(DataManager::GetChallengeTitle(), c1, c2);

            auto playerDiv = DataManager::playerDivRow.div;

            // Generates {I/We} {was/are/am}
            string pronounTense =
                DataManager::gi.IsCotdKO()
                    ? "We are"
                    : (DataManager::gi.IsCotdQuali() ? "I am" : "I was");

            /* Only add this in the KO round -- no need otherwise */
            if (DataManager::gi.IsCotdKO() && playerDiv > 0) {
                msg += "$fff | ";
                msg += "$1e3" + pronounTense + " in Div " + playerDiv + " of " + DataManager::GetCotdTotalDivs();
            }

            if (!DataManager::gi.IsCotdKO() && DataManager::GetCotdTotalDivs() >= 4) {
                /* if we're not in the KO round, set the player div to 4
                 * so that the chat msg will show divs 1-5
                 */
                playerDiv = 2;
            }

            msg += "$fff | $f21" + "CUTOFFS:";

            if (playerDiv > 2) {
                msg += "$fff > ";
                msg += "$fad" + "D1: " + "$cef" + DataManager::divRows[0].FmtTime();
            }

            if (playerDiv > 3) {
                msg += "$fff > ";
                msg += "$fad" + "D2: " + "$cef" + DataManager::divRows[1].FmtTime();
            }

            if (playerDiv > 1) {
                msg += "$fff > ";
                msg += "$fad" + "D" + (playerDiv - 1) + ": " + "$cef" + DataManager::divRows[playerDiv - 2].FmtTime();
            }

            if (playerDiv > 0) {
                msg += "$fff > ";
                msg += "$fad" + "D" + (playerDiv) + ": " + "$cef" + DataManager::divRows[playerDiv - 1].FmtTime();
            }

            if (playerDiv > 0 && playerDiv * 64 <= DataManager::GetCotdTotalPlayers()) {
                msg += "$fff > ";
                msg += "$fad" + "D" + (playerDiv + 1) + ": " + "$cef" + DataManager::divRows[playerDiv].FmtTime();
            }

            msg += "$fff > ";
            msg += "$fad" + "Last div ($9e2" + DataManager::GetCotdTotalDivs() + "$fad): $cef" + DataManager::GetCotdLastDivPop() + "$fad players.";

            @c1 = Color(vec3(0.906, 0.906, 0.043));  // #e7e70b
            @c2 = Color(vec3(0.082, 0.961, 0.208));  // #15f535
            c1.AsHSL(); c2.AsHSL();

            // if (send) {
            //     msg += "\n$fff | " + TextGradient("Generated by the COTD HUD plugin: ", c1, c2);
            //     msg += "$<$lhttps://openplanet.nl/plugin/206$>";
            // }

            if (this.send)
                _SendMsg(msg);
            else
                _LocalMsg(msg);
            // print(c_green + "[TellCotdCommand.Run] (" + text + ") | Msg: " + msg);
        }
    }


    void Main() {
        /* run once on start, set up commands */
        RegisterBcCommands();
    }

    void RegisterBcCommands() {
        BetterChat::RegisterCommand("cotd", @TellCotdCommand(false));
        BetterChat::RegisterCommand("tell-cotd", @TellCotdCommand(true));
        print(c_green + "[RegisterBcCommands] Done.");
    }
}

#endif
