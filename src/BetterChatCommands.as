#if DEPENDENCY_BETTERCHAT

namespace BcCommands {
    void _SendMsg(const string &in text) {
        BetterChat::SendChatMessage(text);
    }

    void _LocalMsg(const string &in text) {
        BetterChat::AddSystemLine(text);
    }

    // enum CotdCommandTy {
    //     Local,
    //     Send
    // }

    class TellCotdCommand : BetterChat::ICommand {
        bool send;

        TellCotdCommand(bool send) {
            this.send = send;
        }

        string Icon() {
            return "\\$eb1" + Icons::Trophy;
        }

        string Description() {
            return "Tells chat which division this is and some COTD stats.";
        }

        void Run(const string &in text) {
            auto c1 = Color(vec3(0.980, 0.980, 0.431), ColorTy::RGB);  // #fafa6e
            c1.AsLAB();
            auto c2 = Color(vec3(0.941, 0.465, 0.162), ColorTy::RGB);  // #F05D15
            c2.AsLAB();
            string msg = TextGradient(DataManager::GetChallengeTitle(), c1, c2);

            auto playerDiv = DataManager::playerDivRow.div;

            // Generates {I/We} {was/are/am}
            string pronounTense =
                DataManager::gi.IsCotdKO()
                    ? "We are"
                    : (DataManager::gi.IsCotdQuali() ? "I am" : "I was");

            if (playerDiv > 0) {
                msg += "$fff | ";
                msg += CGreen.ManiaColor + pronounTense + " in Div " + playerDiv + " of " + DataManager::GetCotdTotalDivs() + "$fff |";
            }

            if (playerDiv > 2) {
                msg += "\n$fff | ";
                msg += "$fad" + "Div 1 Cutoff: " + "$aaf" + DataManager::divRows[0].FmtTime();
            }

            if (playerDiv > 1) {
                msg += "\n$fff | ";
                msg += "$fad" + "Div " + (playerDiv - 1) + " Cutoff: " + "$aaf" + DataManager::divRows[playerDiv - 2].FmtTime();
            }

            if (playerDiv > 0) {
                msg += "\n$fff | ";
                msg += "$fad" + "Div " + (playerDiv) + " Cutoff: " + "$aaf" + DataManager::divRows[playerDiv - 1].FmtTime();
            }

            if (playerDiv > 0 && playerDiv * 64 <= DataManager::GetCotdTotalPlayers()) {
                msg += "\n$fff | ";
                msg += "$fad" + "Div " + (playerDiv + 1) + " Cutoff: " + "$aaf" + DataManager::divRows[playerDiv].FmtTime();
            }

            msg += "\n$fff | ";
            msg += "$fad" + "Last div (" + DataManager::GetCotdTotalDivs() + "): $aaf" + DataManager::GetCotdLastDivPop() + "$fad players.";

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
