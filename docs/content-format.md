# Lesson file format

Lessons after Unit 1, Lesson 2 live in `HablaBase/Content/lessons-u{n}.json`, one file per unit.
`tools/validate_content.py` checks every file against the rules below; run it after any change:

```
python3 tools/validate_content.py            # all units
python3 tools/validate_content.py u3 u4      # only these units (earlier units still count for vocabulary)
```

Learners' languages: every text for the learner exists in English (`en`), Italian (`it`), Ukrainian (`uk`), German (`de`), French (`fr`) and
Brazilian Portuguese (`pt`) and Simplified Chinese (`zh`). Wherever an object has `en`,
it has every language in `LANGS` (tools/validate_content.py); the validator rejects a missing one. Placeholders:
`{workEn}` / `{workIt}` / `{workUk}` (where the learner works), `{languageEn}` / `{languageIt}` / `{languageUk}`
(their language as in "I speak …"; in Ukrainian the instrumental, "українською"). Writing instructions:
"Write in Spanish: «…»", "Scrivi in spagnolo: «…»", "Напиши іспанською: «…»", "Schreib auf Spanisch: «…»", "Écris en espagnol : «…»", "Escreva em espanhol: «…»", "用西班牙语写：«…»".

## Carla's lesson rules (non-negotiable)

1. **Go slowly. No word is used before it is introduced.** Every Spanish word in an exercise or an
   example must have appeared earlier on a vocabulary slide (`words`) or in an explanation's
   `teaches` list, in this lesson or an earlier one on the path. Names of people and places can
   be listed in `names` on the lesson instead.
2. **Vocabulary first.** A lesson opens with its new words (`words`: slides, then matching each
   word with its translation). Sets of 2 to 6 words; more words means more sets. New words needed
   later in the lesson can get their own small `words` set right before they are used.
3. **Explain, 2 exercises, explain, 2 exercises… then a mix.** One idea per explanation, then 2
   exercises (`beat` "forge" or "fire") on exactly that idea. Close with a `mix` block of 3 to 4
   exercises that combine everything in the lesson.
4. **At most 15 questions per lesson.** Every exercise counts, and so does each `words` set
   (its matching step).
5. **Explanations are in the learner's language** (`en` and `it`), short, concrete, never a wall
   of text: one rule of 1 to 3 sentences, plus 2 or 3 Spanish examples with translations.
   Hints too. Only the Spanish being taught is in Spanish.
6. **Personal when it can be:** `{name}`, `{city}`, `{work}` (e.g. "un hospital", the words after
   "Trabajo en"), `{language}` ("inglés"/"italiano"), and in translations `{workEn}`/`{workIt}`
   ("in a hospital"/"in un ospedale") and `{languageEn}`/`{languageIt}` are replaced with the
   learner's own answers.

## File

```json
{
  "unit": "u2",
  "lessons": [ { lesson }, ... ],     // every lesson of the unit, ids as in curriculum.json
  "boss": { lesson }                  // id "u2boss": the unit's real-life scene, 10 to 15 questions
}
```

The unit test (`u2test`) is generated from the unit's lessons; don't write it.

## Lesson

```json
{
  "id": "u2l1",
  "goal": {"en": "Talk about what you and your friends do.", "it": "..."},
  "target": {"es": "Nosotros hablamos español.", "en": "We speak Spanish.", "it": "Noi parliamo spagnolo."},
  "names": ["Ana", "Madrid"],          // optional
  "items": [ ... ]
}
```

`target` is the sentence shown at the start ("Today you'll learn to say…"). A boss uses `goal`
to set the scene ("You're at Don Paco's market stall. Buy what you need for dinner.").

## Items

Every exercise may carry `"beat"`: `forge` (first practice), `fire` (harder practice), `mix`
(closing block). `hint` is always `{"en": "...", "it": "..."}` and explains *why*, in one line.

**words**: new vocabulary. `kind` colours the word: `stem` (verbs), `ending` (persons, pronouns),
`time` (time words), `rail` (connectors, prepositions), `chunk` (everything else).

```json
{"type": "words", "words": [
  {"es": "nosotros", "en": "we", "it": "noi", "kind": "ending"},
  {"es": "estudiar", "en": "to study", "it": "studiare", "kind": "stem"}
]}
```

**explain**: one rule as a picture. `bricks` snap together (`+` between them); `result` (optional)
shows a coloured verb form. `teaches` lists the new forms the explanation introduces, which
exercises may then use.

```json
{"type": "explain",
 "bricks": [{"text": "habl-", "kind": "stem"}, {"text": "-amos", "kind": "ending"}],
 "result": {"stem": "habl", "ending": "amos"},
 "rule": {"en": "For nosotros (we), AR verbs end in -amos.", "it": "..."},
 "examples": [{"es": "Nosotros hablamos español.", "en": "We speak Spanish.", "it": "Noi parliamo spagnolo."}],
 "teaches": [{"es": "hablamos", "en": "we speak", "it": "parliamo"}]}
```

**snap**: pick a stem and an ending. `person`: yo, tu, el, nosotros, vosotros, ellos.

```json
{"type": "snap", "beat": "forge", "person": "nosotros",
 "prompt": {"en": "we eat", "it": "mangiamo"},
 "stems": ["com", "habl", "viv"], "endings": ["amos", "emos", "imos"],
 "answer": {"stem": "com", "ending": "emos"}}
```

**gap**: type the missing word. `label` is the word shown next to the field (usually the infinitive).

```json
{"type": "gap", "beat": "forge", "before": "Nosotros ", "after": " café.", "label": "beber",
 "accepted": ["bebemos"], "en": "We drink coffee.", "it": "Beviamo caffè.",
 "hint": {"en": "ER verbs: -emos for nosotros.", "it": "..."}}
```

**choose**: pick the word for the gap. 2 to 4 options; best for irregular forms, ser/estar,
articles, gustar…

```json
{"type": "choose", "beat": "fire", "before": "Ellas ", "after": " de Roma.",
 "options": ["es", "son", "están"], "answer": "son",
 "en": "They are from Rome.", "it": "Sono di Roma.",
 "hint": {"en": "Origin uses ser; ellas takes son.", "it": "..."}}
```

**build**: tap tiles into a sentence. The prompt is an intention, not a translation. Include 1
or 2 distractor tiles. `accepted[0]` is the model answer and must be buildable from `tiles`.

```json
{"type": "build", "beat": "fire",
 "intention": {"en": "Say that you two live in Madrid.", "it": "..."},
 "accepted": ["Nosotros vivimos en Madrid.", "Vivimos en Madrid."],
 "tiles": ["Nosotros", "vivimos", "en", "Madrid", "vivo"],
 "en": "We live in Madrid.", "it": "Viviamo a Madrid.",
 "hint": {"en": "viv- + -imos.", "it": "..."}}
```

**write**: write a whole sentence, usually the last mix item. Never an open prompt ("say two
things you do"): people can write anything, so it can't be checked. The instruction gives the exact
meaning to translate, in «…», and `accepted` lists every natural way to say it (with and without
the subject pronoun, other word orders…); the first is the model answer. Accents are forgiven.

```json
{"type": "write", "beat": "mix",
 "instruction": {"en": "Write in Spanish: «We speak Spanish and we eat a lot.»", "it": "Scrivi in spagnolo: «Parliamo spagnolo e mangiamo molto.»", "uk": "Напиши іспанською: «Ми розмовляємо іспанською і багато їмо.»"},
 "accepted": ["Nosotros hablamos español y comemos mucho.", "Hablamos español y comemos mucho.", "Nosotros hablamos español y nosotros comemos mucho."],
 "model": {"es": "Nosotros hablamos español y comemos mucho.", "en": "We speak Spanish and we eat a lot.", "it": "Parliamo spagnolo e mangiamo molto."}}
```
