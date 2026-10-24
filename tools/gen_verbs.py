"""Builds HablaBase/Content/verbs.json: every verb the course teaches, the lesson that
introduces it, its meaning in every native language and its six present-tense forms.

The Lab's verb tables read this file, so a verb appears there once its lesson is done.
Run it again after adding units:  python3 tools/gen_verbs.py
Only units already translated into every language are included.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "HablaBase" / "Content"
LANGS = ["en", "it", "uk", "de", "fr", "pt", "zh"]
PERSONS = ["yo", "tu", "el", "nosotros", "vosotros", "ellos"]
PRONOUNS = ["me", "te", "se", "nos", "os", "se"]
ENDINGS = {
    "ar": ["o", "as", "a", "amos", "áis", "an"],
    "er": ["o", "es", "e", "emos", "éis", "en"],
    "ir": ["o", "es", "e", "imos", "ís", "en"],
}

# Whole present paradigms that no rule produces.
FULL = {
    "ser": ["soy", "eres", "es", "somos", "sois", "son"],
    "estar": ["estoy", "estás", "está", "estamos", "estáis", "están"],
    "ir": ["voy", "vas", "va", "vamos", "vais", "van"],
    "haber": ["he", "has", "ha", "hemos", "habéis", "han"],
    "oír": ["oigo", "oyes", "oye", "oímos", "oís", "oyen"],
    "freír": ["frío", "fríes", "fríe", "freímos", "freís", "fríen"],
    "dar": ["doy", "das", "da", "damos", "dais", "dan"],
    "ver": ["veo", "ves", "ve", "vemos", "veis", "ven"],
    "construir": ["construyo", "construyes", "construye", "construimos", "construís", "construyen"],
}

# Stem changes in the stressed forms (yo, tú, él, ellos).
STEM_CHANGE = {
    "ie": "querer preferir pensar empezar cerrar entender fregar perder sentir nevar recomendar "
          "sentar encender despertar tener venir detener".split(),
    "ue": "jugar poder volver costar dormir devolver probar aprobar encontrar doler soler sonar contar acostar llover".split(),
    "i": "pedir repetir servir vestir seguir decir elegir".split(),
}

# Irregular yo forms.
YO = {
    "hacer": "hago", "salir": "salgo", "poner": "pongo", "traer": "traigo", "conocer": "conozco",
    "saber": "sé", "conducir": "conduzco", "decir": "digo", "venir": "vengo", "coger": "cojo",
    "seguir": "sigo", "nacer": "nazco", "crecer": "crezco", "caer": "caigo", "parecer": "parezco",
    "proponer": "propongo", "tener": "tengo", "detener": "detengo", "elegir": "elijo",
}

# Infinitives whose gloss does not start with "to" (can, should).
MODALS = {"poder", "deber"}

# Verbs met first as "me gusta" / "me encanta": they enter the tables with that lesson.
LIKE = {
    "me gusta": ("gustar", {"en": "to like (it pleases me)", "it": "piacere", "uk": "подобатися", "de": "gefallen",
                            "fr": "plaire", "pt": "gostar", "zh": "喜欢"}),
    "me encanta": ("encantar", {"en": "to love (it delights me)", "it": "piacere molto", "uk": "дуже подобатися",
                                "de": "sehr gefallen", "fr": "adorer", "pt": "adorar", "zh": "非常喜欢"}),
}

# Verbs used only in some persons (weather, "me duele", "se acaba").
ONLY = {
    "llover": ["el"], "nevar": ["el"], "gustar": ["el", "ellos"], "encantar": ["el", "ellos"],
    "doler": ["el", "ellos"], "importar": ["el", "ellos"], "acabarse": ["el", "ellos"],
}


def change_stem(stem, change):
    vowel = "u" if change == "ue" and "o" not in stem else ("o" if change == "ue" else "e")
    i = stem.rfind(vowel)
    return stem[:i] + change + stem[i + 1:]


def present(lemma):
    """Six forms, each split into [stem, ending] for the coloured bricks."""
    reflexive = lemma.endswith("se") and lemma not in FULL
    base = lemma[:-2] if reflexive else lemma
    family = "ir" if base.endswith("ír") else base[-2:]
    endings = ENDINGS[family]
    if base in FULL:
        forms = FULL[base]
    else:
        stem = base[:-2]
        change = next((c for c, verbs in STEM_CHANGE.items() if base in verbs), None)
        forms = []
        for p, ending in enumerate(endings):
            s = change_stem(stem, change) if change and p in (0, 1, 2, 5) else stem
            forms.append(s + ending)
        if base in YO:
            forms[0] = YO[base]
    split = []
    for p, form in enumerate(forms):
        ending = endings[p]
        if form.endswith(ending) and len(form) > len(ending):
            pair = [form[: -len(ending)], ending]
        else:
            pair = [form, ""]
        if reflexive:
            pair[0] = PRONOUNS[p] + " " + pair[0]
        split.append(pair)
    return split


def unit1_core():
    """The six verbs of lesson u1l1 live in Unit1.swift."""
    text = (CONTENT / "Unit1.swift").read_text()
    core = re.search(r'coreLemmas = \[(.*?)\]', text).group(1)
    lemmas = re.findall(r'"(\w+)"', core)
    verbs = []
    for lemma in lemmas:
        m = re.search(r'Verb\(lemma: "%s", meaning: Gloss\((.*?)\)' % lemma, text)
        gloss = dict(re.findall(r'(\w+): "([^"]*)"', m.group(1)))
        verbs.append((lemma, "u1l1", {k: gloss[k] for k in LANGS}))
    return verbs


def taught_verbs():
    found = {lemma: (lesson, gloss) for lemma, lesson, gloss in unit1_core()}
    files = sorted(CONTENT.glob("lessons-u*.json"), key=lambda p: int(re.search(r"u(\d+)", p.name).group(1)))
    for path in files:
        data = json.loads(path.read_text())
        if not complete(data):
            continue
        for spec in data["lessons"] + ([data["boss"]] if data.get("boss") else []):
            for word in glossed(spec):
                es = word["es"]
                if (re.fullmatch(r"[a-záéíóúñ]*(ar|er|ir|ír)(se)?", es) and es not in found
                        and (word["en"].startswith("to ") or ", to " in word["en"] or es in MODALS)
                        and all(word.get(k) for k in LANGS)):
                    found[es] = (spec["id"], {k: word[k] for k in LANGS})
                for es, (lemma, gloss) in LIKE.items():
                    if word["es"] == es and lemma not in found:
                        found[lemma] = (spec["id"], gloss)
    return found


def glossed(node):
    """Every Spanish word with its glosses, from word slides and explanations' teaches lists alike."""
    if isinstance(node, dict):
        if isinstance(node.get("es"), str) and isinstance(node.get("en"), str):
            yield node
        for value in node.values():
            yield from glossed(value)
    elif isinstance(node, list):
        for value in node:
            yield from glossed(value)


def complete(data):
    """True when the unit is translated into every language (new units start in en + it)."""
    return all(k in data["lessons"][0].get("goal", {}) for k in LANGS)


def main():
    verbs = []
    for lemma, (lesson, gloss) in taught_verbs().items():
        entry = {"lemma": lemma, "lesson": lesson, "meaning": gloss, "present": present(lemma)}
        if lemma in ONLY:
            entry["persons"] = ONLY[lemma]
        verbs.append(entry)
    out = CONTENT / "verbs.json"
    out.write_text("[\n" + ",\n".join(json.dumps(v, ensure_ascii=False) for v in verbs) + "\n]\n")
    print(len(verbs), "verbs ->", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
