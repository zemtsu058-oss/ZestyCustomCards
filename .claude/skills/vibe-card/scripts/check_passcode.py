"""Check passcode availability and find next free one in a range."""
import sqlite3
import re
import sys
from pathlib import Path

def find_project_root() -> Path:
    curr = Path(__file__).resolve().parent
    for parent in [curr] + list(curr.parents):
        if (parent / "custom_cards_zesty.cdb").exists() or (parent / "script").is_dir():
            return parent
    return Path(__file__).resolve().parents[4]

PROJECT_ROOT = find_project_root()
SCRIPT_DIR = PROJECT_ROOT / "script"
CDB_PATH = PROJECT_ROOT / "custom_cards_zesty.cdb"


def get_used_passcodes() -> set[int]:
    used: set[int] = set()
    for f in SCRIPT_DIR.glob("c*.lua"):
        m = re.match(r"c(\d+)", f.stem)
        if m:
            used.add(int(m.group(1)))
    if CDB_PATH.exists():
        conn = sqlite3.connect(str(CDB_PATH))
        cur = conn.cursor()
        cur.execute("SELECT id FROM datas")
        for row in cur:
            used.add(row[0])
        conn.close()
    return used


def next_passcode(prefix: int, used: set[int] | None = None) -> int:
    if used is None:
        used = get_used_passcodes()
    for seq in range(1, 100000):
        code = prefix * 100000 + seq
        if code not in used:
            return code
    raise ValueError(f"No free passcode in {prefix}00001-{prefix}99999")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python check_passcode.py <prefix> [specific_code]")
        sys.exit(1)
    prefix = int(sys.argv[1])
    used = get_used_passcodes()
    if len(sys.argv) > 2:
        specific = int(sys.argv[2])
        print("FREE" if specific not in used else "TAKEN")
        sys.exit(0 if specific not in used else 1)
    print(next_passcode(prefix, used))
