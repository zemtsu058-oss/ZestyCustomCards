"""Insert a custom card into the EDOPro CDB database."""
import sqlite3
import sys
from pathlib import Path

def find_project_root() -> Path:
    curr = Path(__file__).resolve().parent
    for parent in [curr] + list(curr.parents):
        if (parent / "custom_cards_zesty.cdb").exists() or (parent / "script").is_dir():
            return parent
    return Path(__file__).resolve().parents[4]

PROJECT_ROOT = find_project_root()
CDB_PATH = PROJECT_ROOT / "custom_cards_zesty.cdb"


def encode_setcode(hex_value: int) -> int:
    """Encode setcode decimal value to CDB storage format.

    Converts decimal integer to ASCII bytes, then interprets as big-endian int.
    Example: 426 -> "426" -> b'\x34\x32\x36' -> 3420726
    """
    decimal_str = str(hex_value)
    return int.from_bytes(decimal_str.encode("ascii"), "big", signed=False)


def insert_card(
    passcode: int,
    name: str,
    card_type: int,
    setcode_decimal: int,
    desc: str,
    effect_strs: list[str] | None = None,
    atk: int = 0,
    defense: int = 0,
    level: int = 0,
    race: int = 0,
    attribute: int = 0,
    ot: int = 1,
    alias: int = 0,
    category: int = 0,
    overwrite: bool = False,
) -> bool:
    if not CDB_PATH.exists():
        print(f"ERROR: CDB not found at {CDB_PATH}")
        return False

    conn = sqlite3.connect(str(CDB_PATH))
    cur = conn.cursor()

    cur.execute("SELECT id FROM datas WHERE id = ?", (passcode,))
    exists = cur.fetchone() is not None
    if exists:
        if not overwrite:
            print(f"ERROR: Passcode {passcode} already exists in CDB. Use --overwrite to update.")
            conn.close()
            return False
        else:
            print(f"OVERWRITING: Card {passcode} already exists. Deleting existing entries...")
            cur.execute("DELETE FROM datas WHERE id = ?", (passcode,))
            cur.execute("DELETE FROM texts WHERE id = ?", (passcode,))

    encoded_setcode = encode_setcode(setcode_decimal)

    cur.execute(
        "INSERT INTO datas(id, ot, alias, setcode, type, atk, def, level, race, attribute, category) "
        "VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (passcode, ot, alias, encoded_setcode, card_type, atk, defense, level, race, attribute, category),
    )

    strs = (effect_strs or [])[:16]
    strs += [""] * (16 - len(strs))

    cols = ", ".join(f"str{i}" for i in range(1, 17))
    cur.execute(
        f"INSERT INTO texts(id, name, desc, {cols}) VALUES(?, ?, ?, {', '.join('?' * 16)})",
        (passcode, name, desc, *strs),
    )

    conn.commit()
    print(f"INSERTED: {passcode} — {name}")
    conn.close()
    return True


if __name__ == "__main__":
    import argparse
    import json

    parser = argparse.ArgumentParser(description="Insert a custom card into the EDOPro CDB database.")
    parser.add_argument("--passcode", type=int, help="Card passcode")
    parser.add_argument("--name", type=str, help="Card name")
    parser.add_argument("--type", type=str, help="Card type bitmask (hex string e.g. 0x21 or integer)")
    parser.add_argument("--setcode", type=int, help="Setcode decimal value (e.g. 426)")
    parser.add_argument("--desc", type=str, help="Card description/effect text")
    parser.add_argument("--effect-strs", type=str, nargs="*", help="Optional effect descriptions (aux.Stringid strings)")
    parser.add_argument("--atk", type=int, default=0, help="ATK value")
    parser.add_argument("--def", type=int, default=0, dest="defense", help="DEF value")
    parser.add_argument("--level", type=int, default=0, help="Level/Rank/Link rating")
    parser.add_argument("--lscale", type=int, help="Left Pendulum scale")
    parser.add_argument("--rscale", type=int, help="Right Pendulum scale")
    parser.add_argument("--race", type=str, default="0", help="Monster race bitmask (hex string or integer)")
    parser.add_argument("--attribute", type=str, default="0", help="Monster attribute bitmask (hex string or integer)")
    parser.add_argument("--category", type=str, default="0", help="Effect category bitmask (hex string or integer)")
    parser.add_argument("--ot", type=int, default=1, help="OT (1=OCG, 2=TCG, 3=Anime, 4=Custom)")
    parser.add_argument("--alias", type=int, default=0, help="Alias card ID")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing card with same passcode")
    parser.add_argument("--json-file", type=str, help="Path to a JSON file containing the card details")

    args = parser.parse_args()

    def parse_int(val) -> int:
        if val is None:
            return 0
        if isinstance(val, int):
            return val
        val_str = str(val).strip()
        if val_str.startswith("0x") or val_str.startswith("0X"):
            return int(val_str, 16)
        return int(val_str)

    if args.json_file:
        json_path = Path(args.json_file)
        if not json_path.exists():
            print(f"ERROR: JSON file not found at {json_path}")
            sys.exit(1)
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        passcode = data.get("passcode")
        name = data.get("name")
        card_type = parse_int(data.get("type"))
        setcode_decimal = data.get("setcode")
        desc = data.get("desc")
        effect_strs = data.get("effect_strs") or data.get("effect_strings")
        atk = data.get("atk", 0)
        defense = data.get("def", 0)
        level = data.get("level", 0)
        lscale = data.get("lscale")
        rscale = data.get("rscale")
        race = parse_int(data.get("race"))
        attribute = parse_int(data.get("attribute"))
        category = parse_int(data.get("category"))
        ot = data.get("ot", 1)
        alias = data.get("alias", 0)
        overwrite = data.get("overwrite", args.overwrite)
    else:
        passcode = args.passcode
        name = args.name
        card_type = parse_int(args.type)
        setcode_decimal = args.setcode
        desc = args.desc
        effect_strs = args.effect_strs
        atk = args.atk
        defense = args.defense
        level = args.level
        lscale = args.lscale
        rscale = args.rscale
        race = parse_int(args.race)
        attribute = parse_int(args.attribute)
        category = parse_int(args.category)
        ot = args.ot
        alias = args.alias
        overwrite = args.overwrite

    if not passcode or not name or not card_type or setcode_decimal is None or not desc:
        print("ERROR: Missing required fields (passcode, name, type, setcode, desc).")
        print("Provide them via CLI arguments or --json-file.")
        sys.exit(1)

    # Encode Pendulum scales if present
    if lscale is not None or rscale is not None:
        lv = level & 0xff
        ls = lscale if lscale is not None else (rscale if rscale is not None else 0)
        rs = rscale if rscale is not None else ls
        level = lv + (ls << 24) + (rs << 16)

    success = insert_card(
        passcode=passcode,
        name=name,
        card_type=card_type,
        setcode_decimal=setcode_decimal,
        desc=desc,
        effect_strs=effect_strs,
        atk=atk,
        defense=defense,
        level=level,
        race=race,
        attribute=attribute,
        ot=ot,
        alias=alias,
        category=category,
        overwrite=overwrite,
    )
    sys.exit(0 if success else 1)
