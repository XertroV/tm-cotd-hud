
namespace BcCommands {
    /* by COTD HUD on OpenPlanet */
    const string byLineA = "$c7fb$c8fy$b8f $b8fC$a8fO$98fT$99fD$89f $79fH$79fU$69fD$5af $3afo$3afn$4ae $4bdO$5bcp$5bce$5cbn$5caP$4d9l$4d8a$3e7n$2e6e$0f5t";
    /* by COTD HUD */
    const string byLineB = "$c7fb$b8fy$a8f $89fC$69fO$3afT$3afD$5bd $5caH$4d8U$0f5D";

#if DEPENDENCY_BETTERCHAT
    void _SendMsg(const string &in text) {
        BetterChat::SendChatMessage(text);
    }

    void _LocalMsg(const string &in text) {
        BetterChat::AddSystemLine(text);
    }

    class TellCotdCommand : BetterChat::ICommand {
        bool send;
        private Color@ c1 = Color(vec3(0.980, 0.980, 0.431), ColorTy::RGB);  // #fafa6e
        private Color@ c2 = Color(vec3(0.941, 0.465, 0.162), ColorTy::RGB);  // #F05D15

        private Color@ cSpruik1 = Color(vec3());
        private Color@ cSpruik2 = Color(vec3());

        TellCotdCommand(bool send) {
            this.send = send;
            c1.AsHSL();
            c2.AsHSL();
        }

        string Icon() {
            return "\\$eb1" + Icons::Trophy;
        }

        string Description() {
            auto _action = send ? "Tells chat" : "Prints";
            return _action + " which division this is and COTD cutoff stats.";
        }

        void Run(const string &in text) {
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

            msg += "$fff | $f42" + "CUTOFFS:";

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

            msg += "$fff | ";
            msg += "$fad" + "Last div ($6f3" + DataManager::GetCotdTotalDivs() + "$fad): $cef" + DataManager::GetCotdLastDivPop() + "$fad ppl";

            msg += "$fff | ";
            msg += "$fad" + "N=" + c1.ManiaColor + DataManager::GetCotdTotalPlayers();

            // @c1 = Color(vec3(0.906, 0.906, 0.043));  // #e7e70b
            // @c2 = Color(vec3(0.082, 0.961, 0.208));  // #15f535
            // c1.AsHSL(); c2.AsHSL();

            // if (send) {
            //     msg += "\n$fff | " + TextGradient("Generated by the COTD HUD plugin: ", c1, c2);
            //     msg += "$<$lhttps://openplanet.nl/plugin/206$>";
            // }

            msg += " $fff(" + byLineB + "$fff)";

            if (this.send) {
                _SendMsg(msg);
            } else {
                _LocalMsg(msg);
            }
            // print(c_green + "[TellCotdCommand.Run] (" + text + ") | Msg: " + msg);
        }
    }


    Color@ InputToColor(const string &in str) {
        vec3 rgb;
        if (str.Length == 3) {
            try {
                rgb = hexTriToRgb(str);
                return Color(rgb);
            } catch {
                // bad hextri
            }
        }
        // otherwise let's scan known colors
        if (NAMED_COLORS.Exists(str)) {
            return Color(vec3(NAMED_COLORS[str]));
        }
        throw("Unknown color");
        return Color(vec3(1,1,1));
    }


    class SayRgbToChatCommand : BetterChat::ICommand {
        string Icon() {
            return '\\$94d' + Icons::PaintBrush;
            // return "\\$f19I\\$74bI\\$08dI\\$08dI\\$0a7I\\$0c1I";
        }

        string Description() {
            // auto _action = send ? "Tells chat" : "Prints";
            return "Args: [color1] [color2] [message...]. Apply a gradient to a chat message.";
        }

        void Run(const string &in text) {
            auto parts = text.Split(' ', 4);
            print("Got msg parts: " + string::Join(parts, " | "));
            if (parts.Length < 4) {
                _LocalMsg("To use " + parts[0] + " you must provide these arguments:\n"
                + '$s$9d1' + ">  $s" + parts[0] + " [color1] [color2] [your message ...]\n"
                + "$fff  Colors can be a 3-letter hex value (e.g., f19 or 7f0 or ff2), or specified by name.\n"
                + "  To list available colors by name, run /list-colors.\n");
                return;
            }
            string _c1 = parts[1];
            string _c2 = parts[2];
            string msg = parts[3];
            try {
                Color@ c1 = InputToColor(_c1);
                Color@ c2 = InputToColor(_c2);
                _SendMsg(TextGradient(msg, c1, c2));
            } catch {
                string exInfo = getExceptionInfo();
                string errMsg = "Exception parsing colors ("+_c1+","+_c2+"): " + exInfo;
                warn(errMsg);
                _LocalMsg(errMsg);
            }
        }
    }

    class ListColorsCommand :BetterChat::ICommand {
        string Icon() {
            return c_timeOrange + Icons::List;
        }

        string Description() {
            return "Lists available named colors for use with /rgb";
        }

        void Run(const string &in text) {
            _LocalMsg("$fa4Todo: list colors.");
            string colors = "";
            Color@ c;
            vec3 cv;
            string name;
            for (uint i = 0; i < COLOR_NAMES.Length; i++) {
                name = COLOR_NAMES[i];
                cv = vec3(NAMED_COLORS[name]);
                @c = Color(cv);
                colors += "$z" + c.ManiaColor + name + "$z\n";
            }
            _LocalMsg("Available colors: \n" + colors);
        }
    }


    void Main() {
        /* run once on start, set up commands */
        RegisterBcCommands();
    }

    void RegisterBcCommands() {
        BetterChat::RegisterCommand("cotd", @TellCotdCommand(false));
        BetterChat::RegisterCommand("tell-cotd", @TellCotdCommand(true));
        BetterChat::RegisterCommand("rgb", @SayRgbToChatCommand());
        BetterChat::RegisterCommand("list-colors", @ListColorsCommand());
        print(c_green + "[RegisterBcCommands] Done.");
    }
#endif
}
