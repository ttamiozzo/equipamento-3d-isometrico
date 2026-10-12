#!/usr/bin/env python3
"""Monta um dashboard iso3d (HTML único) a partir de um JSON de dashboard.

Uso:
  python build.py pop.json pop.html [--models ./models ...]

- Equipamentos cujo modelo não está em "models" são procurados como <id>.json nas
  pastas de --models (relativas à pasta atual ou à do dashboard), em <pasta do
  dashboard>/models e, por último, em assets/models da skill.
- Se faltar algum modelo, sai com erro e não grava o HTML.
- O JSON final é injetado em assets/template.html no lugar de __ISO3D_DATA__.
"""
import argparse
import html
import json
import sys
from pathlib import Path

SKILL = Path(__file__).resolve().parent.parent


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("dashboard")
    ap.add_argument("out")
    ap.add_argument("--models", action="append", default=[])
    a = ap.parse_args()

    dash = Path(a.dashboard).resolve()
    data = json.loads(dash.read_text(encoding="utf-8"))
    models = data.setdefault("models", {})
    dirs = []
    for d in a.models:
        p = Path(d)
        dirs += [p] if p.is_absolute() else [Path.cwd() / p, dash.parent / p]
    dirs += [dash.parent / "models", SKILL / "assets" / "models"]
    missing = set()
    for dev in data.get("devices", []):
        mid = dev.get("model")
        if not mid or mid in models:
            continue
        for d in dirs:
            f = d / f"{mid}.json"
            if f.exists():
                models[mid] = json.loads(f.read_text(encoding="utf-8"))
                print(f"modelo embutido: {mid} <- {f}")
                break
        else:
            missing.add(mid)
    if missing:
        print("ERRO: modelos não encontrados: " + ", ".join(sorted(missing)), file=sys.stderr)
        print("procurado em: " + " | ".join(str(d) for d in dirs), file=sys.stderr)
        return 1

    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    tpl = (SKILL / "assets" / "template.html").read_text(encoding="utf-8")
    title = html.escape(str(data.get("title") or "Mapa de Equipamentos"))
    out = tpl.replace("__ISO3D_DATA__", payload).replace(
        "<title>Mapa de Equipamentos</title>", f"<title>{title}</title>")
    Path(a.out).write_text(out, encoding="utf-8")
    print(f"gerado: {Path(a.out).resolve()} ({len(out) // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
