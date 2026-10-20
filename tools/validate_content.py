#!/usr/bin/env python3
"""Checks the lesson files against docs/content-format.md.

Usage: python3 tools/validate_content.py [u2 u3 ...] [--langs en,it]

--langs checks only those learner languages: for a unit whose other translations aren't written yet.

Walks the path in order, so the vocabulary check knows every word introduced by earlier
lessons. Lessons not written yet count with the words and forms planned for them in docs/vocab-plan.json.
Exit code 1 if any error is found.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "HablaBase" / "Content"
PLAN = ROOT / "docs" / "vocab-plan.json"

PUNCT = re.compile(r"[¿?¡!.,;:\"'()«»…]")
# The learner's languages: every explanation and translation exists in each.
LANGS = ("en", "it", "uk", "de", "fr", "pt", "zh")
PERSONS = {"yo", "tu", "el", "nosotros", "vosotros", "ellos"}
KINDS = {"stem", "ending", "time", "rail", "chunk"}
BEATS = {"forge", "fire", "mix"}
TYPES = {"words", "explain", "snap", "gap", "choose", "build", "write"}
QUESTION_TYPES = TYPES - {"explain"}
PLACEHOLDERS = ["{name}", "{city}", "{work}", "{language}"]

# Words Unit 1, Lessons 1 and 2 (written in Swift) introduce.
BASE_KNOWN = set("""
yo tú él ella hablar trabajar comer beber vivir escribir
hablo hablas habla trabajo trabajas trabaja como comes come bebo bebes bebe
vivo vives vive escribo escribes escribe español café mucho aquí
me llamo en y un poco de
""".split())


def words(text):
    for placeholder in PLACEHOLDERS:
        text = text.replace(placeholder, " ")
    return [w for w in PUNCT.sub(" ", text.lower()).split() if not w.isdigit()]


def normalize(text):
    return " ".join(PUNCT.sub(" ", text.lower()).split())


def can_build(target, tiles):
    if not target:
        return True
    for i, tile in enumerate(tiles):
        t = normalize(tile)
        if t and (target == t or target.startswith(t + " ")):
            if can_build(target[len(t):].strip(), tiles[:i] + tiles[i + 1:]):
                return True
    return False


class Checker:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.known = set(BASE_KNOWN)

    def error(self, where, message):
        self.errors.append(f"{where}: {message}")

    def warn(self, where, message):
        self.warnings.append(f"{where}: {message}")

    def gloss(self, where, value, name):
        if not isinstance(value, dict) or not all((value.get(lang) or "").strip() for lang in LANGS):
            self.error(where, f"{name} needs non-empty en, it and uk")

    def uses(self, where, text, known):
        for word in words(text):
            if word not in known:
                self.error(where, f'uses "{word}" before it is introduced')

    def lesson(self, spec, expected_id, is_boss=False):
        lid = spec.get("id")
        if lid != expected_id:
            self.error(expected_id, f"id is {lid!r}, expected {expected_id!r}")
        self.gloss(lid, spec.get("goal"), "goal")
        target = spec.get("target")
        if target is not None:
            if not all(target.get(k) for k in ("es",) + LANGS):
                self.error(lid, "target needs es, en, it and uk")
        known = self.known | {w for n in spec.get("names", []) for w in words(n)}
        items = spec.get("items", [])
        if not items:
            self.error(lid, "no items")
            return
        if not is_boss and items[0].get("type") != "words":
            self.error(lid, "a lesson starts with its new words")

        questions = 0
        since_explain = None
        mix = 0
        for index, item in enumerate(items):
            where = f"{lid} item {index} ({item.get('type')})"
            kind = item.get("type")
            if kind not in TYPES:
                self.error(where, "unknown type")
                continue
            if kind in QUESTION_TYPES:
                questions += 1
            beat = item.get("beat")
            if beat is not None and beat not in BEATS:
                self.error(where, f"beat must be one of {sorted(BEATS)}")
            if beat == "mix":
                mix += 1
            if kind not in ("words", "explain") and since_explain is not None:
                since_explain += 1
            if "hint" in item:
                self.gloss(where, item["hint"], "hint")

            if kind == "words":
                ws = item.get("words", [])
                if not 2 <= len(ws) <= 6:
                    self.error(where, f"{len(ws)} words; a set has 2 to 6")
                for w in ws:
                    if not all(w.get(k) for k in ("es",) + LANGS):
                        self.error(where, f"word {w} needs es, en, it and uk")
                    if w.get("kind", "chunk") not in KINDS:
                        self.error(where, f"kind {w.get('kind')} not in {sorted(KINDS)}")
                    known.update(words(w.get("es", "")))
            elif kind == "explain":
                if since_explain is not None and since_explain < 1 and not is_boss:
                    self.warn(where, "explanation right after another one, with no exercise in between")
                since_explain = 0
                self.gloss(where, item.get("rule"), "rule")
                for t in item.get("teaches", []):
                    if not all(t.get(k) for k in ("es",) + LANGS):
                        self.error(where, f"teaches entry {t} needs es, en, it and uk")
                    known.update(words(t.get("es", "")))
                examples = item.get("examples", [])
                if not examples:
                    self.error(where, "an explanation needs at least one example")
                for ex in examples:
                    if not all(ex.get(k) for k in LANGS):
                        self.error(where, f"example {ex.get('es')} needs en, it and uk")
                    self.uses(where, ex.get("es", ""), known)
                for b in item.get("bricks", []):
                    if b.get("kind") not in KINDS:
                        self.error(where, f"brick kind {b.get('kind')} not in {sorted(KINDS)}")
            elif kind == "snap":
                ans = item.get("answer", {})
                if item.get("person") not in PERSONS:
                    self.error(where, f"person must be one of {sorted(PERSONS)}")
                stems, endings = item.get("stems", []), item.get("endings", [])
                if not isinstance(ans, dict) or ans.get("stem") not in stems or ans.get("ending") not in endings:
                    self.error(where, "the answer's stem and ending must be in the trays")
                if len(set(stems)) != len(stems) or len(set(endings)) != len(endings):
                    self.error(where, "duplicate bricks in a tray")
                self.gloss(where, item.get("prompt"), "prompt")
                if isinstance(ans, dict):
                    self.uses(where, ans.get("stem", "") + ans.get("ending", ""), known)
            elif kind == "gap":
                accepted = item.get("accepted", [])
                if not accepted or not item.get("label"):
                    self.error(where, "needs accepted answers and a label")
                    continue
                self.gloss(where, {lang: item.get(lang) for lang in LANGS}, "translation")
                self.uses(where, item.get("before", "") + accepted[0] + item.get("after", ""), known)
            elif kind == "choose":
                options, answer = item.get("options", []), item.get("answer")
                if answer not in options:
                    self.error(where, "the answer must be one of the options")
                if not 2 <= len(options) <= 4 or len(set(options)) != len(options):
                    self.error(where, "2 to 4 different options")
                self.gloss(where, {lang: item.get(lang) for lang in LANGS}, "translation")
                self.uses(where, item.get("before", "") + " " + item.get("after", "") + " " + " ".join(options), known)
            elif kind == "build":
                accepted, tiles = item.get("accepted", []), item.get("tiles", [])
                if not accepted:
                    self.error(where, "needs accepted sentences")
                    continue
                self.gloss(where, item.get("intention"), "intention")
                self.gloss(where, {lang: item.get(lang) for lang in LANGS}, "translation")
                if not can_build(normalize(accepted[0]), tiles):
                    self.error(where, f'tiles can\'t build "{accepted[0]}"')
                if len(tiles) <= len(normalize(accepted[0]).split()) - 0 and len(tiles) < 3:
                    self.warn(where, "very few tiles")
                for text in accepted + tiles:
                    self.uses(where, text, known)
            elif kind == "write":
                model = item.get("model", {})
                self.gloss(where, item.get("instruction"), "instruction")
                if not all(model.get(k) for k in ("es",) + LANGS):
                    self.error(where, "model needs es, en, it and uk")
                # Carla: an open prompt ("say two things you do") can't be checked. Every write
                # gives the exact meaning to translate, in quotes, and the sentences it accepts.
                accepted = item.get("accepted", [])
                if not accepted or normalize(accepted[0]) != normalize(model.get("es", "")):
                    self.error(where, "a write needs accepted sentences, the first one being the model")
                for lang in LANGS:
                    if "«" not in (item.get("instruction") or {}).get(lang, ""):
                        self.error(where, f"instruction ({lang}) must give the exact sentence to translate in «…»")
                for text in accepted:
                    self.uses(where, text, known)
                padded = f" {normalize(model.get('es', ''))} "
                for chunk in item.get("required", []):
                    c = normalize(chunk)
                    for placeholder in PLACEHOLDERS:
                        padded = padded.replace(normalize(placeholder), "")
                    if f" {c} " not in padded and not any(p in chunk for p in PLACEHOLDERS):
                        self.error(where, f'required "{chunk}" is not in the model answer')
                self.uses(where, model.get("es", ""), known)

        if questions > 15:
            self.error(lid, f"{questions} questions; the maximum is 15")
        if not is_boss and mix < 2:
            self.error(lid, f"{mix} mix items; close the lesson with 3 to 4")
        if is_boss and questions < 8:
            self.warn(lid, f"boss has only {questions} questions")
        # Words learned here stay known for the rest of the path (names don't).
        names = {w for n in spec.get("names", []) for w in words(n)}
        self.known |= known - names


def main(selected):
    curriculum = json.loads((CONTENT / "curriculum.json").read_text())
    plan = json.loads(PLAN.read_text()) if PLAN.exists() else {}
    checker = Checker()
    units = [u for level in curriculum["levels"] for u in level["units"]]
    for unit in units:
        uid = unit["id"]
        path = CONTENT / f"lessons-{uid}.json"
        data = None
        if path.exists():
            try:
                data = json.loads(path.read_text())
            except json.JSONDecodeError as e:
                checker.error(path.name, f"invalid JSON: {e}")
        specs = {s.get("id"): s for s in (data or {}).get("lessons", [])}
        check = not selected or uid in selected
        for lesson in unit["lessons"]:
            lid = lesson["id"]
            if lid in ("u1l1", "u1l2"):
                continue
            if lid in specs:
                before = len(checker.errors)
                checker.lesson(specs[lid], lid)
                if not check:
                    del checker.errors[before:]
            else:
                planned = plan.get(lid, {})
                for w in planned.get("words", []) + planned.get("teaches", []):
                    checker.known.update(words(w["es"]))
                if check and data is not None:
                    checker.error(lid, "missing from " + path.name)
        if data is None or data.get("boss") is None:
            planned = plan.get(f"{uid}boss", {})
            for w in planned.get("words", []) + planned.get("teaches", []):
                checker.known.update(words(w["es"]))
        if data is not None:
            boss = data.get("boss")
            if boss is None:
                if check:
                    checker.error(uid, "no boss")
            else:
                before = len(checker.errors)
                checker.lesson(boss, f"{uid}boss", is_boss=True)
                if not check:
                    del checker.errors[before:]
            extra = set(specs) - {l["id"] for l in unit["lessons"]}
            if extra and check:
                checker.error(uid, f"lessons not in the curriculum: {sorted(extra)}")

    for w in checker.warnings:
        if not selected or any(w.startswith(u + "l") or w.startswith(u + "b") for u in selected):
            print("warning:", w)
    for e in checker.errors:
        print("ERROR:", e)
    print(f"{len(checker.errors)} errors")
    return 1 if checker.errors else 0


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--langs" in args:
        i = args.index("--langs")
        LANGS = tuple(args[i + 1].split(","))
        del args[i:i + 2]
    sys.exit(main(set(args)))
