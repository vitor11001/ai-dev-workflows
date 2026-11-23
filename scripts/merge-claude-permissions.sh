#!/usr/bin/env bash
set -euo pipefail

# Acrescenta ao `permissions.allow` de ~/.claude/settings.json as regras de
# .claude/permissions.json deste repositório. Só adiciona: regras já presentes, outras
# chaves do settings.json e regras do usuário são preservadas. Faz backup antes de alterar
# e imprime apenas quando houve mudança. Regras retiradas do repositório não são removidas
# do settings.json; remova-as à mão.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERMISSIONS_SOURCE="$REPO_DIR/.claude/permissions.json"
SETTINGS_FILE="$HOME/.claude/settings.json"

if [[ ! -f "$PERMISSIONS_SOURCE" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$SETTINGS_FILE")"

python3 -I - "$PERMISSIONS_SOURCE" "$SETTINGS_FILE" <<'PY'
import json
import os
import shutil
import sys
import time

source_path, settings_path = sys.argv[1], sys.argv[2]

with open(source_path, encoding="utf-8") as fh:
    wanted = json.load(fh).get("allow", [])

if os.path.exists(settings_path):
    with open(settings_path, encoding="utf-8") as fh:
        settings = json.load(fh)
else:
    settings = {}

allow = settings.setdefault("permissions", {}).setdefault("allow", [])
added = [rule for rule in wanted if rule not in allow]

if not added:
    sys.exit(0)

if os.path.exists(settings_path):
    shutil.copy2(settings_path, f"{settings_path}.bak.{time.strftime('%Y%m%d-%H%M%S')}")

allow.extend(added)

tmp_path = f"{settings_path}.tmp"
with open(tmp_path, "w", encoding="utf-8") as fh:
    json.dump(settings, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
os.replace(tmp_path, settings_path)

for rule in added:
    print(f"[claude] permissao adicionada: {rule}")
PY
