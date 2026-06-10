#!/usr/bin/env python3
import json
import argparse
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')
import os
import re
import shutil
import subprocess
from pathlib import Path

# Mapping of templates to default card types
TEMPLATE_TYPES = {
    "effect_monster": 0x21,       # Monster + Effect
    "normal_spell": 0x2,          # Spell
    "normal_trap": 0x4,           # Trap
    "fusion_monster": 0x41,       # Monster + Fusion
    "synchro_monster": 0x2001,    # Monster + Synchro
    "xyz_monster": 0x801,         # Monster + Xyz
    "link_monster": 0x4000001,    # Monster + Link
    "pendulum_monster": 0x1000021,# Monster + Pendulum + Effect
    "field_spell": 0x80002,       # Spell + Field
    "hand_trap": 0x21             # Monster + Effect (usually)
}

def get_project_paths():
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    return {
        "root": project_root,
        "feature_list": project_root / "feature_list.json",
        "script_dir": project_root / "script",
        "template_dir": project_root / "script-test" / "templates",
        "card_data": project_root / "card-data",
        "queues_dir": project_root / "docs" / "queues"
    }

def find_archetype_by_passcode(fl_data, passcode):
    for name, info in fl_data.get("archetypes", {}).items():
        pr = info.get("passcode_range")
        if pr:
            try:
                start, end = map(int, pr.split("-"))
                if start <= passcode <= end:
                    return name, info
            except:
                pass
    return "Common", fl_data.get("archetypes", {}).get("Common", {})

def locate_queue_image(queues_dir, card_name, archetype):
    # Try searching under the specific archetype folder, then globally
    normalized_name = card_name.lower().replace(" ", "_").replace("'", "").replace("-", "_")
    search_dirs = []
    if queues_dir.joinpath(archetype).is_dir():
        search_dirs.append(queues_dir / archetype)
    search_dirs.append(queues_dir)
    
    # Common extensions
    extensions = ["*.jpg", "*.jpeg", "*.png", "*.gif"]
    
    for s_dir in search_dirs:
        for ext in extensions:
            for p in s_dir.rglob(ext):
                # Match files starting with p_ and containing card name words
                if p.name.startswith("p_"):
                    # Check if normalized name or keywords match the filename
                    cleaned_filename = p.stem.lower()
                    if normalized_name in cleaned_filename or all(word in cleaned_filename for word in normalized_name.split("_") if len(word) > 2):
                        return p
    return None

def start_card(passcode, card_name, template_type):
    paths = get_project_paths()
    
    # 1. Load and check feature_list.json
    if not paths["feature_list"].exists():
        print(f"Error: feature_list.json not found.", file=sys.stderr)
        return
        
    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)
        
    # Check if passcode is already registered
    existing_card = None
    existing_archetype = None
    for arch_name, arch_info in fl_data.get("archetypes", {}).items():
        for card in arch_info.get("cards", []):
            if card.get("passcode") == str(passcode):
                if card.get("status") != "pending":
                    print(f"Error: Passcode {passcode} is already registered under '{arch_name}' (Card: '{card['name']}') with status '{card.get('status')}'.", file=sys.stderr)
                    return
                else:
                    existing_card = card
                    existing_archetype = arch_name

    # Find or guess archetype
    if existing_archetype:
        archetype = existing_archetype
        arch_info = fl_data["archetypes"][archetype]
    else:
        archetype, arch_info = find_archetype_by_passcode(fl_data, passcode)
    print(f"Assigning card to Archetype: {archetype}")

    # Parse setcode
    setcode_str = arch_info.get("setcode", "0")
    try:
        setcode_val = int(setcode_str, 16) if setcode_str.startswith("0x") else int(setcode_str)
    except:
        setcode_val = 0

    # 2. Locate queue file
    queue_file = None
    if existing_card and existing_card.get("queue_file"):
        potential_path = paths["root"] / existing_card["queue_file"]
        if potential_path.exists():
            queue_file = potential_path
            
    if not queue_file:
        queue_file = locate_queue_image(paths["queues_dir"], card_name, archetype)
        
    new_queue_file_path = None
    if queue_file:
        # Rename from p_ to w_ (working)
        new_name = queue_file.name.replace("p_", "w_", 1)
        new_path = queue_file.parent / new_name
        try:
            shutil.move(str(queue_file), str(new_path))
            new_queue_file_path = str(new_path.relative_to(paths["root"]).as_posix())
            print(f"Located queue image: {queue_file.name} -> Renamed to {new_name}")
        except Exception as e:
            print(f"Warning: Failed to rename queue image: {e}", file=sys.stderr)
            new_queue_file_path = str(queue_file.relative_to(paths["root"]).as_posix())
    else:
        print("No pending queue image found matching card name.")

    # 3. Create specs JSON
    paths["card_data"].mkdir(parents=True, exist_ok=True)
    json_path = paths["card_data"] / f"c{passcode}.json"
    
    default_type = TEMPLATE_TYPES.get(template_type.lower(), 0x21)
    
    spec_data = {
        "id": passcode,
        "ot": 32,
        "alias": 0,
        "setcode": setcode_val,
        "type": default_type,
        "atk": 0,
        "def": 0,
        "level": 0,
        "race": 0,
        "attribute": 0,
        "category": 0,
        "name": card_name,
        "desc": "Mô tả hiệu ứng...",
        "strings": []
    }
    
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(spec_data, f, ensure_ascii=False, indent=2)
    print(f"Created specs spec JSON: {json_path.relative_to(paths['root'])}")

    # 4. Copy template Lua script
    template_file = paths["template_dir"] / f"template_{template_type.lower()}.lua"
    script_path = paths["script_dir"] / f"c{passcode}.lua"
    
    if not template_file.exists():
        print(f"Error: Template '{template_type}' not found. Available templates:", file=sys.stderr)
        for t_file in paths["template_dir"].glob("template_*.lua"):
            print(f"  - {t_file.stem.replace('template_', '')}", file=sys.stderr)
        return

    try:
        with open(template_file, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Replace template placeholders
        content = content.replace("<<CARD_NAME>>", card_name)
        content = content.replace("<<PASSCODE>>", str(passcode))
        content = content.replace("<<SETCODE>>", f"{setcode_val:x}" if setcode_val > 0 else "0")
        content = content.replace("<<ARCHETYPE_NAME>>", archetype)
        
        with open(script_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Created Lua script: {script_path.relative_to(paths['root'])}")
    except Exception as e:
        print(f"Error creating Lua script: {e}", file=sys.stderr)
        return

    # 5. Append or update in feature_list.json
    if existing_card:
        existing_card["status"] = "working"
        existing_card["script"] = f"script/c{passcode}.lua"
        if new_queue_file_path:
            existing_card["queue_file"] = new_queue_file_path
        print(f"Updated existing pending card {passcode} to 'working' status.")
    else:
        new_card_entry = {
            "name": card_name,
            "passcode": str(passcode),
            "status": "working",
            "script": f"script/c{passcode}.lua"
        }
        if new_queue_file_path:
            new_card_entry["queue_file"] = new_queue_file_path

        if archetype not in fl_data["archetypes"]:
            fl_data["archetypes"][archetype] = {"cards": []}
            
        fl_data["archetypes"][archetype]["cards"].append(new_card_entry)
    
    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)
    print(f"Added/updated card in feature_list.json under '{archetype}'.")
    print(f"Status set to 'working'. Happy coding!")

def run_command(args, cwd):
    # Helper to run shell commands in powershell or default shell depending on OS
    use_shell = sys.platform == "win32"
    result = subprocess.run(args, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8', shell=use_shell)
    return result.returncode, result.stdout, result.stderr

def verify_card(passcode):
    paths = get_project_paths()
    print(f"Starting verification pipeline for Card passcode: {passcode}...")

    # 1. Compile Database Specs
    print("Step 1: Compiling JSON specs to database...")
    rc, stdout, stderr = run_command(["python", "script-test/manage_db.py", "compile"], paths["root"])
    if rc != 0:
        print("Error: DB Compilation failed!", file=sys.stderr)
        print(stderr, file=sys.stderr)
        return False
    print("Database compiled successfully.")

    # 2. Run validate_scripts.ps1
    print("Step 2: Validating scripts structure and syntax...")
    rc, stdout, stderr = run_command(["powershell", "-ExecutionPolicy", "Bypass", "-File", "script-test/validate_scripts.ps1"], paths["root"])
    
    # Check if this passcode exists and contains FAIL in validation
    # Output matches standard pattern, we can inspect lines
    validation_passed = True
    for line in stdout.splitlines():
        if f"c{passcode}.lua" in line:
            print(f"  Validator output: {line}")
            if "FAIL" in line:
                validation_passed = False
                
    if not validation_passed:
        print("Error: Script validation failed for this passcode. Please fix errors before declaring success.", file=sys.stderr)
        return False
    print("Script validation checked out.")

    # 3. Run basic style check (Linter)
    print("Step 3: Checking style linter...")
    rc, stdout, stderr = run_command(["powershell", "-ExecutionPolicy", "Bypass", "-File", "script-test/lint_scripts.ps1", "-Path", f"script/c{passcode}.lua"], paths["root"])
    print(stdout.strip())
    # If stdout contains errors we still let it pass, but notify
    if "Total files with issues" in stdout:
        print("Warning: Linter reported code style issues in your script. Highly recommended to fix them.")

    # 4. Check sync status
    print("Step 4: Running system sync check...")
    rc, stdout, stderr = run_command(["python", "script-test/manage_db.py", "check-sync"], paths["root"])
    print(stdout.strip())
    if "Found" in stdout and "synchronization issues" in stdout:
        print("Error: System synchronization has mismatches. Cannot declare passing.", file=sys.stderr)
        return False
    print("System sync verified successfully.")

    # 5. Update status to done and finalize queue file name
    print("Step 5: Updating state to done...")
    if not paths["feature_list"].exists():
        print("Error: feature_list.json not found.", file=sys.stderr)
        return False
        
    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)
        
    card_found = False
    for arch_name, arch_info in fl_data.get("archetypes", {}).items():
        for card in arch_info.get("cards", []):
            if card.get("passcode") == str(passcode):
                card_found = True
                card["status"] = "done"
                
                # Check and rename queue image from w_ to d_
                queue_path_str = card.get("queue_file")
                if queue_path_str:
                    q_path = paths["root"] / queue_path_str
                    if q_path.exists() and q_path.name.startswith("w_"):
                        new_name = q_path.name.replace("w_", "d_", 1)
                        new_path = q_path.parent / new_name
                        try:
                            shutil.move(str(q_path), str(new_path))
                            card["queue_file"] = str(new_path.relative_to(paths["root"]).as_posix())
                            print(f"Renamed queue image to done state: {new_name}")
                        except Exception as e:
                            print(f"Warning: Failed to rename queue image: {e}", file=sys.stderr)
                break
        if card_found:
            break
            
    if not card_found:
        print(f"Warning: Card {passcode} not found in feature_list.json. Cannot update status.")
        return False

    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)
        
    print(f"\nSUCCESS: Card {passcode} is now fully verified and marked as 'done'!")
    
    # Run automatic session log archiver (max 25 sessions)
    print("Step 6: Running automatic session log archiver...")
    rc, stdout, stderr = run_command(["python", "script-test/archive_progress.py"], paths["root"])
    if rc == 0:
        print(stdout.strip())
    else:
        print(f"Warning: Session log archiver failed: {stderr.strip()}", file=sys.stderr)
        
    return True

def scan_pending_cards():
    from datetime import datetime
    paths = get_project_paths()
    if not paths["feature_list"].exists():
        print(f"Error: feature_list.json not found.", file=sys.stderr)
        return

    with open(paths["feature_list"], "r", encoding="utf-8") as f:
        fl_data = json.load(f)

    # Gather all registered stems and passcodes to prevent duplicates
    registered_stems = set()
    registered_passcodes = set()
    for arch_name, arch_info in fl_data.get("archetypes", {}).items():
        for card in arch_info.get("cards", []):
            if "queue_file" in card:
                stem = Path(card["queue_file"]).stem
                # strip prefixes: p_, w_, d_
                if stem.startswith("p_") or stem.startswith("w_") or stem.startswith("d_"):
                    stem = stem[2:]
                registered_stems.add(stem.lower())
            if "passcode" in card:
                registered_passcodes.add(card["passcode"])

    # Locate all p_ files in queues
    queues_dir = paths["queues_dir"]
    extensions = ["*.jpg", "*.jpeg", "*.png", "*.gif"]
    found_pending = []
    
    for ext in extensions:
        for p in queues_dir.rglob(ext):
            if p.name.startswith("p_"):
                stem = p.stem
                if stem.startswith("p_"):
                    stem = stem[2:]
                if stem.lower() not in registered_stems:
                    found_pending.append(p)

    if not found_pending:
        print("No new pending cards found in the queue directory.")
        return

    print(f"Found {len(found_pending)} new pending queue files. Registering...")

    # For each found pending file:
    added_count = 0
    for p_path in found_pending:
        # Determine archetype from parent folder name
        # If parent folder is queues_dir, default to Common
        arch_dir = p_path.parent
        if arch_dir == queues_dir:
            archetype = "Common"
        else:
            archetype = arch_dir.name
            
        # Normalize/Clean archetype name to match feature_list.json keys
        actual_arch_name = "Common"
        for name in fl_data.get("archetypes", {}).keys():
            if name.lower().replace("_", "") == archetype.lower().replace("_", ""):
                actual_arch_name = name
                break

        if actual_arch_name not in fl_data["archetypes"]:
            actual_arch_name = "Common"

        arch_info = fl_data["archetypes"][actual_arch_name]

        # Generate name from filename
        stem = p_path.stem
        if stem.startswith("p_"):
            stem = stem[2:]
        words = stem.split("_")
        formatted_words = []
        for word in words:
            if word.lower() == "and":
                formatted_words.append("&")
            elif word.lower() == "the" and formatted_words:
                formatted_words.append("the")
            elif word.lower() in ("in", "of", "to", "for", "with", "by", "at", "from"):
                formatted_words.append(word.lower())
            else:
                formatted_words.append(word.capitalize())
        card_name = " ".join(formatted_words)

        # Generate passcode
        passcode = None
        pr = arch_info.get("passcode_range")
        if pr:
            try:
                start_range, end_range = map(int, pr.split("-"))
                candidate = start_range
                while str(candidate) in registered_passcodes:
                    candidate += 1
                if candidate <= end_range:
                    passcode = str(candidate)
            except Exception as e:
                print(f"Error calculating passcode range for {actual_arch_name}: {e}")
                
        if not passcode:
            common_candidates = [int(code) for code in registered_passcodes if code.startswith("799000")]
            if common_candidates:
                passcode = str(max(common_candidates) + 1)
            else:
                passcode = "79900001"
                while passcode in registered_passcodes:
                    passcode = str(int(passcode) + 1)

        registered_passcodes.add(passcode)

        # Build card entry
        rel_path = str(p_path.relative_to(paths["root"]).as_posix())
        new_card_entry = {
            "name": card_name,
            "passcode": passcode,
            "status": "pending",
            "queue_file": rel_path
        }

        arch_info["cards"].append(new_card_entry)
        print(f"  [+] Registered: {card_name} (Passcode: {passcode}) under '{actual_arch_name}'")
        added_count += 1

    fl_data["last_updated"] = datetime.now().strftime("%Y-%m-%d")

    with open(paths["feature_list"], "w", encoding="utf-8") as f:
        json.dump(fl_data, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully registered {added_count} new pending cards in feature_list.json!")

def main():
    parser = argparse.ArgumentParser(description="TTF Custom Cards Harness Management CLI Tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: start
    start_parser = subparsers.add_parser("start", help="Initialize a new custom card development")
    start_parser.add_argument("passcode", type=int, help="Card passcode (9 digits)")
    start_parser.add_argument("name", type=str, help="Card name")
    start_parser.add_argument("template", type=str, choices=list(TEMPLATE_TYPES.keys()), help="Template type to copy")

    # Subcommand: verify
    verify_parser = subparsers.add_parser("verify", help="Run full check-sync & syntax tests and mark card as done")
    verify_parser.add_argument("passcode", type=int, help="Card passcode to verify")

    # Subcommand: scan
    subparsers.add_parser("scan", help="Scan queues directory for new pending cards and register them in feature_list.json")

    args = parser.parse_args()

    if args.command == "start":
        start_card(args.passcode, args.name, args.template)
    elif args.command == "verify":
        verify_card(args.passcode)
    elif args.command == "scan":
        scan_pending_cards()

if __name__ == "__main__":
    main()
