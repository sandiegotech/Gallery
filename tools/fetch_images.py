#!/usr/bin/env python3
"""Fetch public-domain artwork images from the Met open-access API.

Each entry is (slug, known_object_id_or_None, search_query, artist_keyword).
Resolves via search when no ID is given, verifies isPublicDomain, downloads
the original image to Gallery/Resources/Media/<slug>.jpg.
"""
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://collectionapi.metmuseum.org/public/collection/v1"
OUT = Path(__file__).resolve().parent.parent / "Gallery/Resources/Media"
OUT.mkdir(parents=True, exist_ok=True)

WORKS = [
    ("wheat-field", 436535, None, "Gogh"),
    ("water-lilies", None, "Bridge over a Pond of Water Lilies", "Monet"),
    ("harvesters", None, "The Harvesters", "Bruegel"),
    ("musicians", None, "The Musicians Caravaggio", "Caravaggio"),
    ("young-woman-pitcher", None, "Young Woman with a Water Pitcher", "Vermeer"),
    ("madame-x", None, "Madame X", "Sargent"),
    ("mada-primavesi", None, "Mada Primavesi", "Klimt"),
    ("divan-japonais", None, "Divan Japonais", "Toulouse-Lautrec"),
    ("chat-noir", None, "Chat Noir", "Steinlen"),
    ("mucha-job", None, "Mucha poster", "Mucha"),
    ("great-wave", 45434, None, "Hokusai"),
    ("plum-garden", None, "Plum Garden Kameido", "Hiroshige"),
]


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "gallery-app-builder"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def obj(object_id):
    return json.loads(get(f"{API}/objects/{object_id}"))


def resolve(slug, object_id, query, artist_kw):
    if object_id:
        o = obj(object_id)
        if o.get("isPublicDomain") and o.get("primaryImage"):
            return o
    q = urllib.parse.quote(query)
    hits = json.loads(get(f"{API}/search?q={q}&hasImages=true")).get("objectIDs") or []
    for oid in hits[:12]:
        try:
            o = obj(oid)
        except Exception:
            continue
        haystack = (o.get("artistDisplayName", "") + " " + o.get("title", "")).lower()
        if artist_kw.lower() not in haystack:
            continue
        if o.get("isPublicDomain") and o.get("primaryImage"):
            return o
    return None


results = {}
for slug, oid, query, artist_kw in WORKS:
    o = resolve(slug, oid, query or slug, artist_kw)
    if not o:
        print(f"MISS {slug}", flush=True)
        continue
    dest = OUT / f"{slug}.jpg"
    if not dest.exists():
        dest.write_bytes(get(o["primaryImage"]))
    results[slug] = {
        "objectID": o["objectID"],
        "title": o["title"],
        "artist": o.get("artistDisplayName"),
        "date": o.get("objectDate"),
        "medium": o.get("medium"),
        "objectURL": o.get("objectURL"),
    }
    print(f"OK   {slug}: {o['title']} — {o.get('artistDisplayName')} ({o.get('objectDate')})", flush=True)

(Path(__file__).parent / "met_results.json").write_text(json.dumps(results, indent=2))
print("done", file=sys.stderr)
