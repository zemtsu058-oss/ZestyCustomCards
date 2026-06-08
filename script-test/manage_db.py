#!/usr/bin/env python3
import sqlite3
import argparse
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')
import re
import json
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

def dump_db(db_path: Path):
    project_root = db_path.parent
    json_dir = project_root / "card-data"
    json_dir.mkdir(parents=True, exist_ok=True)

    if not db_path.exists():
        print(f"Error: Database not found at {db_path}", file=sys.stderr)
        return

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Get list of columns for datas
    cursor.execute("PRAGMA table_info(datas)")
    datas_cols = [row[1] for row in cursor.fetchall()]

    # Get all datas
    cursor.execute("SELECT * FROM datas")
    datas_rows = cursor.fetchall()
    datas_map = {row[0]: dict(zip(datas_cols, row)) for row in datas_rows}

    # Get all texts
    cursor.execute("SELECT * FROM texts")
    texts_rows = cursor.fetchall()
    conn.close()

    print(f"Dumping {len(texts_rows)} cards from database to JSON specs...")

    for row in texts_rows:
        cid = row[0]
        name = row[1]
        desc = row[2]
        
        # Get strings (str1 to str16)
        strings = []
        for val in row[3:]:
            strings.append(val or "")
        
        # Trim trailing empty strings
        while strings and strings[-1] == "":
            strings.pop()

        card_data = {}
        # Merge datas statistics if exists
        if cid in datas_map:
            # Remove id from datas map to avoid duplication if needed, but keeping it is fine
            card_data.update(datas_map[cid])
        else:
            # Fallback default values
            card_data.update({
                "id": cid, "ot": 32, "alias": 0, "setcode": 0, "type": 0,
                "atk": 0, "def": 0, "level": 0, "race": 0, "attribute": 0, "category": 0
            })

        card_data["name"] = name or ""
        card_data["desc"] = desc or ""
        card_data["strings"] = strings

        # Write to JSON
        json_file = json_dir / f"c{cid}.json"
        with open(json_file, "w", encoding="utf-8") as f:
            json.dump(card_data, f, ensure_ascii=False, indent=2)

    print(f"Successfully dumped card specs to {json_dir}/")

def compile_db(db_path: Path):
    project_root = db_path.parent
    json_dir = project_root / "card-data"
    
    if not json_dir.is_dir():
        print(f"Error: card-data directory not found at {json_dir}", file=sys.stderr)
        return

    # Create/recreate the CDB file
    if db_path.exists():
        try:
            db_path.unlink()
        except Exception as e:
            print(f"Error removing old CDB: {e}", file=sys.stderr)
            return

    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()

    # Create tables
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS datas (
            id INTEGER PRIMARY KEY,
            ot INTEGER,
            alias INTEGER,
            setcode INTEGER,
            type INTEGER,
            atk INTEGER,
            def INTEGER,
            level INTEGER,
            race INTEGER,
            attribute INTEGER,
            category INTEGER
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS texts (
            id INTEGER PRIMARY KEY,
            name TEXT,
            desc TEXT,
            str1 TEXT, str2 TEXT, str3 TEXT, str4 TEXT,
            str5 TEXT, str6 TEXT, str7 TEXT, str8 TEXT,
            str9 TEXT, str10 TEXT, str11 TEXT, str12 TEXT,
            str13 TEXT, str14 TEXT, str15 TEXT, str16 TEXT
        )
    """)

    count = 0
    for json_file in json_dir.glob("c*.json"):
        try:
            with open(json_file, "r", encoding="utf-8") as f:
                card_data = json.load(f)
            
            cid = int(card_data.get("id"))
            
            # Insert into datas
            cursor.execute("""
                INSERT INTO datas (id, ot, alias, setcode, type, atk, def, level, race, attribute, category)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                cid,
                card_data.get("ot", 32),
                card_data.get("alias", 0),
                card_data.get("setcode", 0),
                card_data.get("type", 0),
                card_data.get("atk", 0),
                card_data.get("def", 0),
                card_data.get("level", 0),
                card_data.get("race", 0),
                card_data.get("attribute", 0),
                card_data.get("category", 0)
            ))

            # Insert into texts
            strings = card_data.get("strings", [])
            # Pad strings to length 16
            padded_strings = [None] * 16
            for i in range(min(len(strings), 16)):
                padded_strings[i] = strings[i]

            cursor.execute("""
                INSERT INTO texts (id, name, desc,
                    str1, str2, str3, str4, str5, str6, str7, str8,
                    str9, str10, str11, str12, str13, str14, str15, str16)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                cid,
                card_data.get("name", ""),
                card_data.get("desc", ""),
                *padded_strings
            ))
            count += 1
        except Exception as e:
            print(f"Error compiling {json_file.name}: {e}", file=sys.stderr)

    conn.commit()
    conn.close()
    print(f"Successfully compiled {count} card specs into database {db_path.name}")

def check_sync(db_path: Path):
    project_root = db_path.parent
    script_dir = project_root / "script"
    json_dir = project_root / "card-data"
    fl_file = project_root / "feature_list.json"
    
    if not script_dir.is_dir():
        print(f"Error: Script folder not found at {script_dir}", file=sys.stderr)
        return

    # 1. Scan script files
    script_passcodes = set()
    for f in script_dir.glob("c*.lua"):
        m = re.match(r"c(\d+)", f.stem)
        if m:
            script_passcodes.add(int(m.group(1)))

    # 2. Scan JSON spec files
    json_passcodes = set()
    if json_dir.is_dir():
        for f in json_dir.glob("c*.json"):
            m = re.match(r"c(\d+)", f.stem)
            if m:
                json_passcodes.add(int(m.group(1)))
    else:
        print(f"Warning: card-data directory not found at {json_dir}", file=sys.stderr)

    # 3. Scan feature_list.json
    fl_passcodes = set()
    fl_names = {}
    if fl_file.exists():
        try:
            with open(fl_file, "r", encoding="utf-8") as f:
                fl_data = json.load(f)
            for arch in fl_data.get("archetypes", {}).values():
                for card in arch.get("cards", []):
                    passcode = card.get("passcode")
                    if passcode:
                        pid = int(passcode)
                        fl_passcodes.add(pid)
                        fl_names[pid] = card.get("name", "Unknown")
        except Exception as e:
            print(f"Error parsing feature_list.json: {e}", file=sys.stderr)

    # 4. Scan SQLite Database (CDB) if it exists
    db_passcodes = set()
    db_names = {}
    if db_path.exists():
        try:
            conn = sqlite3.connect(str(db_path))
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM datas")
            db_passcodes = {row[0] for row in cursor.fetchall()}
            cursor.execute("SELECT id, name FROM texts")
            db_names = {row[0]: row[1] for row in cursor.fetchall()}
            conn.close()
        except Exception as e:
            print(f"Warning: Failed to query database: {e}", file=sys.stderr)

    all_passcodes = script_passcodes.union(json_passcodes).union(fl_passcodes).union(db_passcodes)
    
    mismatches = []
    cdb_out_of_sync = False
    
    for code in sorted(all_passcodes):
        in_script = code in script_passcodes
        in_json = code in json_passcodes
        in_fl = code in fl_passcodes
        in_cdb = code in db_passcodes
        
        # Check source of truth sync (script, JSON, feature_list)
        if not (in_script and in_json and in_fl):
            status = []
            if not in_script: status.append("Missing Lua Script")
            if not in_json: status.append("Missing Card Spec JSON")
            if not in_fl: status.append("Missing from feature_list.json")
            mismatches.append((code, ", ".join(status)))
            
        # Check if local compiled DB matches the source of truth JSON
        if in_json != in_cdb:
            cdb_out_of_sync = True

    # Retrieve card name helper
    def get_card_name(code):
        if code in fl_names: return fl_names[code]
        if code in db_names: return db_names[code]
        # Try loading from JSON
        json_file = json_dir / f"c{code}.json"
        if json_file.exists():
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    return json.load(f).get("name", "Unknown")
            except: pass
        return "Unknown"

    print("=== Database & Script Sync Status ===")
    print(f"Total script files found   : {len(script_passcodes)}")
    print(f"Total card spec JSON files : {len(json_passcodes)}")
    print(f"Total in feature_list.json : {len(fl_passcodes)}")
    print(f"Total compiled DB rows     : {len(db_passcodes)}")
    print("-" * 40)
    
    if not mismatches:
        print("All local card scripts, spec JSON files, and feature_list are in perfect sync! (100% OK)")
    else:
        print(f"Found {len(mismatches)} synchronization issues:")
        for code, issue in mismatches:
            name = get_card_name(code)
            print(f"  - {code:<10} ({name[:20]:<20}) : {issue}")
            
    if cdb_out_of_sync:
        print("-" * 40)
        print("WARNING: Compiled database (CDB) is out of sync with card-data/ JSON files.")
        print("Please run: python .\\script-test\\manage_db.py compile")
    print()

def update_text(db_path: Path, passcode: int, name: str = None, desc: str = None):
    # Update JSON file first as it is the Single Source of Truth
    project_root = db_path.parent
    json_file = project_root / "card-data" / f"c{passcode}.json"
    
    if not json_file.exists():
        print(f"Error: Card spec JSON not found at {json_file}", file=sys.stderr)
        return
        
    with open(json_file, "r", encoding="utf-8") as f:
        card_data = json.load(f)
        
    if name:
        card_data["name"] = name
        print(f"Updated Name for card {passcode} to: '{name}'")
    if desc:
        clean_desc = desc.replace("\\n", "\n")
        card_data["desc"] = clean_desc
        print(f"Updated Description for card {passcode}.")
        
    with open(json_file, "w", encoding="utf-8") as f:
        json.dump(card_data, f, ensure_ascii=False, indent=2)
        
    print("Plaintext JSON spec updated. Compilation required to update CDB.")

def main():
    parser = argparse.ArgumentParser(description="TTF Card Database CLI Manager Utility")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: query
    query_parser = subparsers.add_parser("query", help="Query card statistics and text")
    query_parser.add_argument("search", type=str, help="Card passcode (ID) or partial name to search")

    # Subcommand: check-sync
    subparsers.add_parser("check-sync", help="Check synchronization status between Lua scripts, JSON specs, and feature_list")

    # Subcommand: dump
    subparsers.add_parser("dump", help="Dump card data from CDB SQLite to card-data/*.json specs")

    # Subcommand: compile
    subparsers.add_parser("compile", help="Compile card-data/*.json specs into CDB SQLite database")

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
    elif args.command == "dump":
        dump_db(db_path)
    elif args.command == "compile":
        compile_db(db_path)
    elif args.command == "update-text":
        update_text(db_path, args.passcode, args.name, args.desc)

if __name__ == "__main__":
    main()
