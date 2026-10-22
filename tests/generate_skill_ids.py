"""Generate the fallback spellbook ID index from local 1.12 WDBC files.

Usage: py tests/generate_skill_ids.py Spell.dbc SkillLineAbility.dbc AutoSkillIDs.lua
"""
import struct
import sys
import hashlib
from collections import defaultdict
from pathlib import Path


def read_dbc(path, expected_fields):
    data = Path(path).read_bytes()
    if data[:4] != b"WDBC":
        raise ValueError(f"Not a WDBC file: {path}")
    count, fields, size, string_size = struct.unpack_from("<4I", data, 4)
    if fields != expected_fields or size != fields * 4:
        raise ValueError(f"Unexpected 1.12 DBC layout: {path}")
    string_start = 20 + count * size
    if string_start + string_size != len(data):
        raise ValueError(f"Invalid string block: {path}")

    def text(offset):
        if not offset or offset >= string_size:
            return ""
        start = string_start + offset
        end = data.find(b"\0", start)
        return data[start:end].decode("utf-8") if end >= start else ""

    rows = (struct.unpack_from(f"<{fields}I", data, 20 + i * size) for i in range(count))
    return rows, text


def lua_string(value):
    return ('"' + value.replace("\\", "\\\\").replace('"', '\\"')
            .replace("\001", "\\001").replace("\n", "\\n") + '"')


def main(spell_path, ability_path, output_path):
    spell_rows, text = read_dbc(spell_path, 173)
    spells = {row[0]: (text(row[124]), text(row[133])) for row in spell_rows}
    ability_rows, _ = read_dbc(ability_path, 15)
    spellbook_ids = {row[2] for row in ability_rows}

    candidates = defaultdict(set)
    by_name = defaultdict(set)
    for spell_id in spellbook_ids:
        name, rank = spells.get(spell_id, ("", ""))
        if name:
            candidates[name + "\001" + rank].add(spell_id)
            by_name[name].add(spell_id)

    index = {key: next(iter(ids)) if len(ids) == 1 else False
             for key, ids in candidates.items()}
    for name, ids in by_name.items():
        key = name + "\001"
        if key not in index and len(ids) == 1:
            index[key] = next(iter(ids))

    if index.get("邪恶攻击\001等级 1") != 1752:
        raise ValueError("Unexpected Sinister Strike rank 1 ID")

    spell_hash = hashlib.sha256(Path(spell_path).read_bytes()).hexdigest()
    ability_hash = hashlib.sha256(Path(ability_path).read_bytes()).hexdigest()
    lines = ["-- Generated from local 1.12 Spell.dbc and SkillLineAbility.dbc.",
             "-- Spell.dbc SHA-256: " + spell_hash,
             "-- SkillLineAbility.dbc SHA-256: " + ability_hash,
             "-- false means the name and rank identify more than one spell.",
             "AutoSkillIDs = {"]
    for key, spell_id in sorted(index.items()):
        lines.append(f"    [{lua_string(key)}] = {str(spell_id).lower()},")
    lines.append("}")
    Path(output_path).write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {len(index)} spellbook lookup keys in {output_path}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    main(*sys.argv[1:])
