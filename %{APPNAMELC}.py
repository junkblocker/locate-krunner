#!/usr/bin/python3
"""A Plasma runner."""
import re
import subprocess
from contextlib import suppress
from typing import Any, List

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
        results: List[Any] = []

        if len(query) < 3:
            return results

        find_cmd = ["/usr/bin/locate", "-l", "10"]
        find_cmd += re.split(r'\s+', query)
        # q(find_cmd)
        find_cmd_result = subprocess.run(find_cmd, capture_output=True, check=False)
        for file in str.split(find_cmd_result.stdout.decode("UTF-8"), "\n"):
            # q(file)
            if file == '':
                continue
            results += [(
                file,
                file,
                "document-open",
                100,
                1,
                {
                    "subtext":
                        file.rsplit('.', 1)[-1]  # extension
                },
            )]

        return results

    @dbus.service.method(IFACE, out_signature="a(sss)")
    def Actions(self):
        # pylint: enable=
        # id, text, icon
        return [("id", "Tooltip", "planetkde")]

    @dbus.service.method(IFACE, in_signature="ss")
    def Run(self, data: str, action_id: str):
        with suppress(Exception):
            _ = subprocess.Popen(["/usr/bin/xdg-open", data]).pid


# print(data, action_id)

runner = Runner()
loop = GLib.MainLoop()
loop.run()
