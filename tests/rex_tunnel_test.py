#!/usr/bin/env python3
import contextlib
import io
from pathlib import Path
import runpy
import unittest
from unittest import mock

MODULE = runpy.run_path(str(Path(__file__).resolve().parents[1] / "bin/rex-devbox-tunnels"))
COMMAND = MODULE["tunnel_command"]


class RexTunnelTests(unittest.TestCase):
    def test_coder_route_stays_on_loopback_and_does_not_wake_workspaces(self):
        with mock.patch("shutil.which", return_value="/usr/local/bin/coder"):
            command = COMMAND("devbox-1", targets())

        self.assertEqual(command[2], "devbox-1.devcontainer")
        self.assertIn("127.0.0.1:17297:7297", command)
        self.assertIn("--disable-autostart=true", command)

    def test_disabled_target_is_rejected(self):
        configured = targets()
        configured["devbox-1"]["enabled"] = False

        with self.assertRaisesRegex(ValueError, "not enabled"):
            COMMAND("devbox-1", configured)

    def test_missing_target_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "not enabled"):
            COMMAND("devbox-1", {})

    def test_unknown_target_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unknown tunnel"):
            COMMAND("other-devbox", targets())

    def test_agent_must_match_the_configured_workspace(self):
        configured = targets()
        configured["devbox-1"]["ssh_target"] = "devcontainer.devbox-2.jsequeira.coder"

        with self.assertRaisesRegex(ValueError, "Cannot identify"):
            COMMAND("devbox-1", configured)

    def test_missing_coder_is_reported(self):
        with mock.patch("shutil.which", return_value=None):
            with self.assertRaisesRegex(ValueError, "coder is not on PATH"):
                COMMAND("devbox-1", targets())

    def test_workmate_failure_stops_tunnel(self):
        with mock.patch("subprocess.check_output", side_effect=OSError("Workmate unavailable")):
            with mock.patch("os.execv") as execute, contextlib.redirect_stderr(io.StringIO()):
                status = MODULE["main"](["run", "devbox-1"])

        self.assertEqual(status, 1)
        execute.assert_not_called()


def targets():
    return {
        "devbox-1": {
            "name": "devbox-1",
            "coder_workspace": "devbox-1",
            "ssh_target": "devcontainer.devbox-1.jsequeira.coder",
            "enabled": True,
        }
    }


if __name__ == "__main__":
    unittest.main()
