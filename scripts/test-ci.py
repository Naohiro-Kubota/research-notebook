"""Check the built iPad app without launching a Simulator."""

import plistlib
import unittest
from pathlib import Path


APP_INFO = (
    Path(__file__).resolve().parent.parent
    / "DerivedData/Build/Products/Debug-iphonesimulator/ResearchNotebook.app/Info.plist"
)


class BuiltAppSettingsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with APP_INFO.open("rb") as source:
            cls.info = plistlib.load(source)

    def test_bundle_identifier(self):
        self.assertEqual(self.info["CFBundleIdentifier"], "com.tabfav")

    def test_minimum_ipados_version(self):
        self.assertEqual(self.info["MinimumOSVersion"], "17.0")

    def test_ipad_only(self):
        self.assertEqual(self.info["UIDeviceFamily"], [2])


if __name__ == "__main__":
    unittest.main()
