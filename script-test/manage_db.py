#!/usr/bin/env python3
import sqlite3
import argparse
import sys
import re
from pathlib import Path

# Common constants mapping for display
TYPES = {
    0x1: "Monster", 0x2: "Spell", 0x4: "Trap", 0x10: "Normal", 0x20: "Effect",
    0x40: "Fusion", 0x80: "Ritual", 0x200: "Spirit", 0x400: "Union",
    0x800: "Dual (Gemini)", 0x1000: "Tuner", 0x2000: "Synchro", 0x4000: "Token",
    0x10000: "Quick-Play", 0x20000: "Continuous", 0x40000: "Equip", 0x80000: "Field",
    0x100000: "Counter", 0x200000: "Flip", 0x400000: "Toon", 0x800000: "Xyz",
    0x1000000: "Pendulum", 0x2000000: "Special Summon", 0x4000000: "Link"
}

ATTRIBUTES = {
    0x1: "EARTH", 0x2: "WATER", 0x4: "FIRE", 0x8: "WIND", 0x10: "LIGHT", 0x20: "DARK", 0x40: "DIVINE"
}

RACES = {
    0x1: "Warrior", 0x2: "Spellcaster", 0x4: "Fairy", 0x8: "Fiend", 0x10: "Zombie",
    0x20: "Machine", 0x40: "Aqua", 0x80: "Pyro", 0x100: "Rock", 0x200: "Winged Beast",
    0x400: "Plant", 0x800: "Insect", 0x1000: "Thunder", 0x2000: "Dragon",
    0x4000: "Beast", 0x8000: "Beast-Warrior", 0x10000: "Dinosaur", 0x20000: "Fish",
    0x40000: "Sea Serpent", 0x80000: "Reptile", 0x100000: "Psychic",
    0x200000: "Divine-Beast", 0x400000: "Creator God", 0x800000: "Wyrm",
    0x1000000: "Cyberse", 0x2000000: "Illusion"
}

def get_db_path() -> Path:
    script_dir = Path(__file__).resolve().parent
    # Check parent and current directories for custom_cards_zesty.cdb
    for path in [script_dir.parent / "custom_cards_zesty.cdb", script_dir / "custom_cards_zesty.cdb"]:
        if path.exists():
            return path
    # Default fallback
    return script_dir.parent / "custom_cards_zesty.cdb"

def format_type(type_val: int) -> str:
    parts = []
    for k, v in TYPES.items():
        if type_val & k:
            parts.append(v)
    return " / ".join(parts) if parts else f"Unknown ({hex(type_val)})"

def format_atk_def(val: int) -> str:
    return "?" if val == -2 else str(val)

def format_level(level_val: int, type_val: int) -> str:
    # Scale is stored in upper bits (bits 16-23: scale, bits 24-31: scale)
    lscale = (level_val >> 24) & 0xff
    rscale = (level_val >> 16) & 0xff
    level = level_val & 0xffff
    
    label = "Level"
    if type_val & 0x800000: # Xyz
        label = "Rank"
    elif type_val & 0x4000000: # Link
        label = "Link"
        
    parts = [f"{label} {level}"]
    if type_val & 0x1000000: # Pendulum
        parts.append(f"Scale {lscale}/{rscale}")
    return ", ".join(parts)

def query_card(db_path: Path, search: str):
    if not db_path.exists():
        print(f"Error: Database not found at {db_path}", file=sys.stderr)
        return

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Determine if searching by ID or name
    if search.isdigit():
        cursor.execute("""
            SELECT d.id, t.name, d.type, d.atk, d.def, d.level, d.race, d.attribute, t.desc, d.ot
            FROM datas d
            LEFT JOIN texts t ON d.id = t.id
            WHERE d.id = ?
        """, (int(search),))
    else:
        cursor.execute("""
            SELECT d.id, t.name, d.type, d.atk, d.def, d.level, d.race, d.attribute, t.desc, d.ot
            FROM datas d
            JOIN texts t ON d.id = t.id
            WHERE t.name LIKE ?
        """, (f"%{search}%",))

    rows = cursor.fetchall()
    conn.close()

    if not rows:
        print(f"No cards found matching '{search}'.")
        return

    for row in rows:
        cid, name, ctype, atk, cdef, level, race, attribute, desc, ot = row
        print("=" * 60)
        print(f"Card Name : {name or 'N/A'}")
        print(f"Passcode  : {cid}")
        print(f"Format (ot): {ot} (Custom = 32)")
        print(f"Card Type : {format_type(ctype)}")
        
        # Only show stats if it's a Monster card
        if ctype & 0x1:
            attr_str = ATTRIBUTES.get(attribute, f"Unknown ({hex(attribute)})")
            race_str = RACES.get(race, f"Unknown ({hex(race)})")
            print(f"Attribute : {attr_str} | Race: {race_str}")
            print(f"Level/Rank: {format_level(level, ctype)}")
            print(f"ATK / DEF : {format_atk_def(atk)} / {format_atk_def(cdef)}")
            
        print("-" * 60)
        print("Effect Description:")
        print(desc or "No description available.")
        print("=" * 60)
        print()

def check_sync(db_path: Path):
    project_root = db_path.parent
    script_dir = project_root / "script"
    
    if not script_dir.is_dir():
        print(f"Error: Script folder not found at {script_dir}", file=sys.stderr)
        return

    # 1. Scan script files
    script_passcodes = set()
    for f in script_dir.glob("c*.lua"):
        m = re.match(r"c(\d+)", f.stem)
        if m:
            script_passcodes.add(int(m.group(1)))

    # 2. Scan database
    db_datas = set()
    db_texts = set()
    
    if db_path.exists():
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM datas")
        db_datas = {row[0] for row in cursor.fetchall()}
        cursor.execute("SELECT id FROM texts")
        db_texts = {row[0] for row in cursor.fetchall()}
        conn.close()
    else:
        print(f"Warning: Database file {db_path} does not exist. Cannot compare with database.", file=sys.stderr)

    all_passcodes = script_passcodes.union(db_datas).union(db_texts)
    
    mismatches = []
    
    for code in sorted(all_passcodes):
        in_script = code in script_passcodes
        in_datas = code in db_datas
        in_texts = code in db_texts
        
        if not (in_script and in_datas and in_texts):
            status = []
            if not in_script: status.append("Missing Lua Script")
            if not in_datas: status.append("Missing datas entry in CDB")
            if not in_texts: status.append("Missing texts entry in CDB")
            mismatches.append((code, ", ".join(status)))
            
    print("=== Database & Script Sync Status ===")
    print(f"Total script files found  : {len(script_passcodes)}")
    print(f"Total database data rows  : {len(db_datas)}")
    print(f"Total database text rows  : {len(db_texts)}")
    print("-" * 40)
    
    if not mismatches:
        print("All local card scripts and database entries are in perfect sync! (100% OK)")
    else:
        print(f"Found {len(mismatches)} synchronization issues:")
        for code, issue in mismatches:
            # Try to get the name if it is in texts
            name = "Unknown"
            if code in db_texts:
                try:
                    conn = sqlite3.connect(str(db_path))
                    c = conn.cursor()
                    c.execute("SELECT name FROM texts WHERE id = ?", (code,))
                    r = c.fetchone()
                    if r: name = r[0]
                    conn.close()
                except:
                    pass
            print(f"  - {code:<10} ({name[:20]:<20}) : {issue}")
    print()

def update_text(db_path: Path, passcode: int, name: str = None, desc: str = None):
    if not db_path.exists():
        print(f"Error: Database not found at {db_path}", file=sys.stderr)
        return

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Check if entry exists in texts
    cursor.execute("SELECT id FROM texts WHERE id = ?", (passcode,))
    exists = cursor.fetchone()

    if not exists:
        print(f"Error: Passcode {passcode} does not exist in 'texts' table.", file=sys.stderr)
        conn.close()
        return

    if name:
        cursor.execute("UPDATE texts SET name = ? WHERE id = ?", (name, passcode))
        print(f"Updated Name for card {passcode} to: '{name}'")
    if desc:
        # Standardize newlines
        clean_desc = desc.replace("\\n", "\n")
        cursor.execute("UPDATE texts SET desc = ? WHERE id = ?", (clean_desc, passcode))
        print(f"Updated Description for card {passcode}.")

    conn.commit()
    conn.close()
    print("Database changes saved successfully.")

def main():
    parser = argparse.ArgumentParser(description="TTF Card Database CLI Manager Utility")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: query
    query_parser = subparsers.add_parser("query", help="Query card statistics and text")
    query_parser.add_argument("search", type=str, help="Card passcode (ID) or partial name to search")

    # Subcommand: check-sync
    subparsers.add_parser("check-sync", help="Check synchronization status between Lua scripts and SQLite database")

    # Subcommand: update-text
    update_parser = subparsers.add_parser("update-text", help="Update card name or description")
    update_parser.add_argument("passcode", type=int, help="Passcode of the card to update")
    update_parser.add_argument("--name", type=str, help="New name for the card")
    update_parser.add_argument("--desc", type=str, help="New description/effect text for the card (use \\n for newline)")

    args = parser.parse_args()
    db_path = get_db_path()

    if args.command == "query":
        query_card(db_path, args.search)
    elif args.command == "check-sync":
        check_sync(db_path)
    elif args.command == "update-text":
        update_text(db_path, args.passcode, args.name, args.desc)

if __name__ == "__main__":
    main()
