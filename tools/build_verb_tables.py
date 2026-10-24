#!/usr/bin/env python3
"""Builds HablaBase/Content/verb-tables.json: the full tables of the verbs the Lab games use.

The tables come from verbecc (pip install verbecc), a conjugator built on hand-made
templates for every known verb. The script refuses any verb verbecc only guesses, and
tools/validate_content.py checks the result with hand-written forms of the hard verbs.

    python3 tools/build_verb_tables.py

Every verb here must also be taught on a vocabulary slide (kind "stem"): the games only use
the verbs of lessons the learner has finished. Verbs that are only used in one person
(llover, doler, gustar…) or only as part of a phrase are left out on purpose.
"""
import json
import logging
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "HablaBase", "Content", "verb-tables.json")

VERBS = """
hablar trabajar estudiar cocinar escuchar comer beber leer aprender vivir escribir
viajar bailar comprar correr abrir ser estar tener limpiar llamar esperar pagar ir
cantar nadar pasear descansar cenar desayunar tomar terminar llegar
querer preferir pensar empezar cerrar entender poder volver ayudar dormir jugar pedir repetir servir
hacer salir poner traer conocer saber conducir decir venir dar ver
levantarse despertarse acostarse ducharse vestirse lavarse relajarse
sacar fregar visitar reservar quedar alquilar quedarse seguir cruzar coger tardar
mirar necesitar buscar devolver cambiar compartir cobrar invitar dejar
contestar preparar probar recibir perder tocar olvidar ahorrar aprobar
nacer crecer mudarse encontrar casarse pasar caerse deber fumar sentirse
llevar entrar oír regalar mandar preguntar vender tirar arreglar contar creer
cancelar celebrar saludar recomendar ganar prometer firmar gritar sentarse cortar añadir
acompañar ordenar disfrutar cuidar decidir subir explicar avisar aceptar bajar apuntar
elegir aparcar construir pintar encender llorar confirmar
""".split()

TENSES = [
    # (key in verb-tables.json, verbecc mood, verbecc tense)
    ("presente", "indicativo", "presente"),
    ("perfecto", "indicativo", "pretérito-perfecto-compuesto"),
    ("indefinido", "indicativo", "pretérito-perfecto-simple"),
    ("imperfecto", "indicativo", "pretérito-imperfecto"),
    ("futuro", "indicativo", "futuro"),
    ("condicional", "condicional", "presente"),
    ("subjuntivo", "subjuntivo", "presente"),
    ("subjuntivoImperfecto", "subjuntivo", "pretérito-imperfecto-1"),
]

# Fully regular verbs verbecc crashes on: their tables are the regular ones.
REGULAR_BY_HAND = {"pasar"}

# verbecc gives the adjective (despierto, nato, electo) where the perfect needs the participle.
PARTICIPLES = {"despertar": "despertado", "nacer": "nacido", "elegir": "elegido"}

# Every participle that isn't stem + ado/ido. Anything else stops the build.
KNOWN_IRREGULAR_PARTICIPLES = {"abierto", "escrito", "vuelto", "devuelto", "hecho", "dicho", "puesto", "visto",
                               "leído", "oído", "traído", "caído", "creído"}

# Hand-written forms of the hard verbs: the build stops if verbecc ever disagrees.
CHECKS = {
    ("ser", "presente"): "soy eres es somos sois son",
    ("ir", "indefinido"): "fui fuiste fue fuimos fuisteis fueron",
    ("tener", "indefinido"): "tuve tuviste tuvo tuvimos tuvisteis tuvieron",
    ("hacer", "indefinido"): "hice hiciste hizo hicimos hicisteis hicieron",
    ("decir", "subjuntivoImperfecto"): "dijera dijeras dijera dijéramos dijerais dijeran",
    ("pedir", "indefinido"): "pedí pediste pidió pedimos pedisteis pidieron",
    ("dormir", "subjuntivo"): "duerma duermas duerma durmamos durmáis duerman",
    ("leer", "indefinido"): "leí leíste leyó leímos leísteis leyeron",
    ("oír", "presente"): "oigo oyes oye oímos oís oyen",
    ("conducir", "indefinido"): "conduje condujiste condujo condujimos condujisteis condujeron",
    ("jugar", "presente"): "juego juegas juega jugamos jugáis juegan",
    ("buscar", "indefinido"): "busqué buscaste buscó buscamos buscasteis buscaron",
    ("poder", "futuro"): "podré podrás podrá podremos podréis podrán",
    ("salir", "condicional"): "saldría saldrías saldría saldríamos saldríais saldrían",
    ("ver", "imperfecto"): "veía veías veía veíamos veíais veían",
    ("dar", "subjuntivo"): "dé des dé demos deis den",
    ("estar", "subjuntivo"): "esté estés esté estemos estéis estén",
    ("saber", "subjuntivo"): "sepa sepas sepa sepamos sepáis sepan",
    ("elegir", "perfecto"): "he elegido|has elegido|ha elegido|hemos elegido|habéis elegido|han elegido",
    ("nacer", "perfecto"): "he nacido|has nacido|ha nacido|hemos nacido|habéis nacido|han nacido",
    ("despertarse", "perfecto"): "me he despertado|te has despertado|se ha despertado|nos hemos despertado|os habéis despertado|se han despertado",
    ("volver", "perfecto"): "he vuelto|has vuelto|ha vuelto|hemos vuelto|habéis vuelto|han vuelto",
    ("sentirse", "indefinido"): "me sentí|te sentiste|se sintió|nos sentimos|os sentisteis|se sintieron",
}

PRONOUNS = ["yo", "tú", "él", "nosotros", "vosotros", "ellos"]
REFLEXIVE = ["me", "te", "se", "nos", "os", "se"]

# The orange brick: endings a form may end in, longest first, per tense and person.
ENDINGS = {
    "presente": [["o"], ["as", "es"], ["a", "e"], ["amos", "emos", "imos"], ["áis", "éis", "ís"], ["an", "en"]],
    "perfecto": [["ado", "ido"]] * 6,
    "indefinido": [["é", "í", "e"], ["aste", "iste"], ["ó", "ió", "o"], ["amos", "imos"], ["asteis", "isteis"], ["aron", "ieron", "eron"]],
    "imperfecto": [["aba", "ía"], ["abas", "ías"], ["aba", "ía"], ["ábamos", "íamos"], ["abais", "íais"], ["aban", "ían"]],
    "futuro": [["é"], ["ás"], ["á"], ["emos"], ["éis"], ["án"]],
    "condicional": [["ía"], ["ías"], ["ía"], ["íamos"], ["íais"], ["ían"]],
    "subjuntivo": [["e", "a"], ["es", "as"], ["e", "a"], ["emos", "amos"], ["éis", "áis"], ["en", "an"]],
    "subjuntivoImperfecto": [["ara", "iera", "era"], ["aras", "ieras", "eras"], ["ara", "iera", "era"],
                             ["áramos", "iéramos", "éramos"], ["arais", "ierais", "erais"], ["aran", "ieran", "eran"]],
}


def regular(infinitive):
    """What a learner would build from the infinitive alone; anything else is irregular."""
    stem, family = infinitive[:-2], infinitive[-2:].replace("í", "i")
    pres = {"ar": ["o", "as", "a", "amos", "áis", "an"], "er": ["o", "es", "e", "emos", "éis", "en"],
            "ir": ["o", "es", "e", "imos", "ís", "en"]}[family]
    pret = (["é", "aste", "ó", "amos", "asteis", "aron"] if family == "ar"
            else ["í", "iste", "ió", "imos", "isteis", "ieron"])
    imp = (["aba", "abas", "aba", "ábamos", "abais", "aban"] if family == "ar"
           else ["ía", "ías", "ía", "íamos", "íais", "ían"])
    subj = (["e", "es", "e", "emos", "éis", "en"] if family == "ar"
            else ["a", "as", "a", "amos", "áis", "an"])
    subj_imp = (["ara", "aras", "ara", "áramos", "arais", "aran"] if family == "ar"
                else ["iera", "ieras", "iera", "iéramos", "ierais", "ieran"])
    participle = stem + ("ado" if family == "ar" else "ido")
    aux = ["he", "has", "ha", "hemos", "habéis", "han"]
    return {
        "presente": [stem + e for e in pres],
        "perfecto": [f"{a} {participle}" for a in aux],
        "indefinido": [stem + e for e in pret],
        "imperfecto": [stem + e for e in imp],
        "futuro": [infinitive + e for e in ["é", "ás", "á", "emos", "éis", "án"]],
        "condicional": [infinitive + e for e in ["ía", "ías", "ía", "íamos", "íais", "ían"]],
        "subjuntivo": [stem + e for e in subj],
        "subjuntivoImperfecto": [stem + e for e in subj_imp],
    }


def split(form, tense, index):
    """'hablamos' -> 'habl|amos', so the app can colour stem and ending."""
    for ending in sorted(ENDINGS[tense][index], key=len, reverse=True):
        if form.endswith(ending) and len(form) > len(ending):
            return form[: -len(ending)] + "|" + ending
    return form


def main():
    logging.disable(logging.CRITICAL)
    from verbecc import CompleteConjugator, LangCodeISO639_1

    conjugator = CompleteConjugator(lang=LangCodeISO639_1.es)
    verbs = []
    for lemma in VERBS:
        reflexive = lemma.endswith("se")
        base = lemma[:-2] if reflexive else lemma
        plain = regular(base)
        if base in REGULAR_BY_HAND:
            forms = {key: [split(w, key, i) for i, w in enumerate(plain[key])] for key, _, _ in TENSES}
            verbs.append({"lemma": lemma, "forms": forms, "irregular": []})
            continue
        try:
            data = conjugator.conjugate(base).get_data()
        except Exception as error:
            sys.exit(f"verbecc fails on {base}: {error!r}")
        if data["verb"]["predicted"]:
            sys.exit(f"verbecc only guesses {base}: check it by hand or leave it out")
        moods = {str(m.value) if hasattr(m, "value") else str(m): {str(t.value) if hasattr(t, "value") else str(t): rows
                 for t, rows in tenses.items()} for m, tenses in data["moods"].items()}
        forms, irregular = {}, []
        for key, mood, tense in TENSES:
            rows = [r for r in moods[mood][tense] if r.get("pr") is not None]
            row_by_pronoun = {}
            for row in rows:
                pronoun = row["pr"].value if hasattr(row["pr"], "value") else str(row["pr"])
                row_by_pronoun.setdefault(pronoun, row["c"][0])
            words = [row_by_pronoun[p].split(" ", 1)[1] for p in PRONOUNS]
            if key == "perfecto":
                participle = PARTICIPLES.get(base, words[0].split(" ")[-1])
                if participle != plain[key][0].split(" ")[-1] and participle not in KNOWN_IRREGULAR_PARTICIPLES:
                    sys.exit(f"unexpected participle for {base}: {participle}; add it to PARTICIPLES or KNOWN_IRREGULAR_PARTICIPLES")
                words = [f"{w.split(' ')[0]} {participle}" for w in words]
            if words != plain[key]:
                irregular.append(key)
            if reflexive:
                words = [f"{REFLEXIVE[i]} {w}" for i, w in enumerate(words)]
            forms[key] = [split(w, key, i) for i, w in enumerate(words)]
        verbs.append({"lemma": lemma, "forms": forms, "irregular": irregular})

    by_lemma = {verb["lemma"]: verb for verb in verbs}
    for (lemma, tense), expected in CHECKS.items():
        got = [form.replace("|", "") for form in by_lemma[lemma]["forms"][tense]]
        want = expected.split("|") if "|" in expected else expected.split(" ")
        if got != want:
            sys.exit(f"{lemma} {tense}: got {got}, expected {want}")

    with open(OUT, "w", encoding="utf-8") as handle:
        # One verb per line keeps the file small and its diffs readable.
        lines = [json.dumps(verb, ensure_ascii=False) for verb in verbs]
        handle.write('{"version": 1, "verbs": [\n' + ",\n".join(lines) + "\n]}\n")
    print(f"{len(verbs)} verbs -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
