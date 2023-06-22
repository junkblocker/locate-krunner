#!/usr/bin/python3
"""A Plasma runner."""
import re
import subprocess
from contextlib import suppress
from pathlib import Path

import dbus.service
# import q
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)

OBJPATH = "/%{APPNAMELC}"
IFACE = "org.kde.krunner1"
SERVICE = "org.kde.%{APPNAMELC}"


class Runner(dbus.service.Object):
    def __init__(self):
        dbus.service.Object.__init__(
            self,
            dbus.service.BusName(SERVICE, dbus.SessionBus()),
            OBJPATH,
        )

    @dbus.service.method(IFACE, in_signature="s", out_signature="a(sssida{sv})")
    def Match(self, query: str):
        """This method is used to get the matches and it returns a list of tuples"""
        # TODO: NoMatch = 0, CompletionMatch = 10, PossibleMatch = 30, InformationalMatch = 50, HelperMatch = 70, ExactMatch = 100

        # q(query)
        # Tried to use results as a dict itself but the {'subtext': line} portion is not hashable :/
        results: list[tuple[str, str, str, int, float, dict[str, str]]] = []

        if len(query) < 3:
            return results

        words = re.split(r'\s+', query)

        self.locate = '/usr/bin/locate'
        locate_config = Path("~/.config/locate-krunner").expanduser()
        if locate_config.exists():
            with locate_config.open() as conf:
                for line in conf:
                    self.locate = str(Path(line.rstrip()).expanduser())
        find_cmd = [self.locate, "-l", "100"]
        find_cmd += re.split(r'\s+', query)
        # q(find_cmd)
        find_cmd_result = subprocess.run(find_cmd, capture_output=True, check=False)
        for file in str.split(find_cmd_result.stdout.decode("UTF-8"), "\n"):
            # q(file)
            if file == '':
                continue
            fp = Path(file)
            relevance = 1.0
            if '.cache' in fp.as_posix():
                relevance -= 0.01
            for word in words:
                if not word.startswith("-"):
                    if word not in fp.name:
                        relevance -= 0.02
                else:
                    if word != fp.name:
                        relevance -= 0.01
            results += [(
                file,
                file,
                "document-open",
                100,
                relevance,
                {
                    "subtext":
                        file.rsplit('.', 1)[-1]  # extension
                },
            )]

        results.sort(key=lambda x: x[4], reverse=True)
        return results[:10]

    @dbus.service.method(IFACE, out_signature="a(sss)")
    def Actions(self) -> list[tuple[str, str, str]]:
        # pylint: enable=
        # id, text, icon
        return [("id", "Tooltip", "planetkde")]

    @dbus.service.method(IFACE, in_signature="ss")
    def Run(self, data: str, action_id: str) -> None:
        with suppress(Exception):
            _ = subprocess.Popen(["/usr/bin/xdg-open", data]).pid


# print(data, action_id)

runner = Runner()
loop = GLib.MainLoop()
loop.run()
