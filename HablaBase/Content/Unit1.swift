import Foundation

/// Unit 1: the present tense and action basics (yo, tú, él/ella; y, pero, también, porque).
enum Unit1 {
    static let verbs: [Verb] = [
        Verb(lemma: "hablar", meaning: Gloss(en: "to speak", it: "parlare"), yoMeaning: Gloss(en: "I speak", it: "parlo"), chunk: "hablo español"),
        Verb(lemma: "trabajar", meaning: Gloss(en: "to work", it: "lavorare"), yoMeaning: Gloss(en: "I work", it: "lavoro"), chunk: "trabajo en..."),
        Verb(lemma: "estudiar", meaning: Gloss(en: "to study", it: "studiare"), yoMeaning: Gloss(en: "I study", it: "studio"), chunk: "estudio por la noche"),
        Verb(lemma: "cocinar", meaning: Gloss(en: "to cook", it: "cucinare"), yoMeaning: Gloss(en: "I cook", it: "cucino"), chunk: "cocino pasta"),
        Verb(lemma: "escuchar", meaning: Gloss(en: "to listen", it: "ascoltare"), yoMeaning: Gloss(en: "I listen", it: "ascolto"), chunk: "escucho música"),
        Verb(lemma: "caminar", meaning: Gloss(en: "to walk", it: "camminare"), yoMeaning: Gloss(en: "I walk", it: "cammino"), chunk: "camino al trabajo"),
        Verb(lemma: "comer", meaning: Gloss(en: "to eat", it: "mangiare"), yoMeaning: Gloss(en: "I eat", it: "mangio"), chunk: "como en casa"),
        Verb(lemma: "beber", meaning: Gloss(en: "to drink", it: "bere"), yoMeaning: Gloss(en: "I drink", it: "bevo"), chunk: "bebo café"),
        Verb(lemma: "leer", meaning: Gloss(en: "to read", it: "leggere"), yoMeaning: Gloss(en: "I read", it: "leggo"), chunk: "leo libros"),
        Verb(lemma: "aprender", meaning: Gloss(en: "to learn", it: "imparare"), yoMeaning: Gloss(en: "I learn", it: "imparo"), chunk: "aprendo español"),
        Verb(lemma: "vivir", meaning: Gloss(en: "to live", it: "vivere"), yoMeaning: Gloss(en: "I live", it: "vivo"), chunk: "vivo en..."),
        Verb(lemma: "escribir", meaning: Gloss(en: "to write", it: "scrivere"), yoMeaning: Gloss(en: "I write", it: "scrivo"), chunk: "escribo mensajes"),
    ]

    static func verb(_ lemma: String) -> Verb {
        verbs.first { $0.lemma == lemma }!
    }

    /// Persons unlocked by each lesson; the Lab rack lights up accordingly.
    static func unlockedPersons(completed: Set<String>) -> [Person] {
        var persons: [Person] = [.yo]
        if completed.contains("u1l2") { persons.append(.tu) }
        if completed.contains("u1l4") { persons.append(.el) }
        return persons
    }

    /// Lessons whose exercises exist in the app. The rest of the curriculum shows as "coming soon".
    static func lesson(id: String, profile: Profile) -> Lesson? {
        switch id {
        case "u1l1": return lesson1(profile: profile)
        default: return nil
        }
    }

    // MARK: - Lesson 1: Me presento

    static func lesson1(profile: Profile) -> Lesson {
        func key(_ lemma: String) -> FormKey { Conjugator.key(verb(lemma), .presente, .yo) }

        // Frame (30 s): habl- + -o = hablo.
        let frame = LessonItem(
            id: "u1l1-frame",
            beat: .frame,
            kind: .frame(FrameCard(
                stem: "habl",
                ending: "o",
                rule: Gloss(en: "In Spanish, the ending tells who. -o = I.", it: "In spagnolo, la desinenza dice chi. -o = io."),
                examples: [
                    Example(es: "Hablo español.", gloss: Gloss(en: "I speak Spanish.", it: "Parlo spagnolo.")),
                    Example(es: "Trabajo en casa.", gloss: Gloss(en: "I work from home.", it: "Lavoro a casa.")),
                    Example(es: "Vivo en Madrid.", gloss: Gloss(en: "I live in Madrid.", it: "Vivo a Madrid.")),
                ]
            )),
            heartsAtRisk: false,
            formKeys: []
        )

        // Forge: Lego Snap x 6. Only -o is available, so success is guaranteed and fast;
        // the learner's job is to pick the stem that carries the meaning.
        let snapLemmas = ["trabajar", "vivir", "hablar", "estudiar", "comer", "escuchar"]
        let snaps: [LessonItem] = snapLemmas.enumerated().map { index, lemma in
            let target = verb(lemma)
            let others = snapLemmas.filter { $0 != lemma }
            let distractors = (0..<3).map { others[(index + $0) % others.count] }
            let stems = ([lemma] + distractors).map { verb($0).stem }.sorted()
            return LessonItem(
                id: "u1l1-snap-\(lemma)",
                beat: .forge,
                kind: .legoSnap(LegoSnap(
                    person: .yo,
                    prompt: target.yoMeaning,
                    stems: stems,
                    endings: ["o"],
                    answer: Conjugator.conjugate(target, .presente, .yo)
                )),
                heartsAtRisk: false,
                formKeys: [key(lemma)]
            )
        }

        // Fire: five contexts, built from the learner's own data.
        let native = profile.nativeLanguage.spanishName
        let fire: [LessonItem] = [
            builder(
                id: "u1l1-work",
                intention: Gloss(en: "Say where you work.", it: "Di dove lavori."),
                sentence: "Trabajo en \(profile.workplace.spanish).",
                tiles: ["Trabajo", "en"] + profile.workplace.spanish.split(separator: " ").map(String.init) + ["Vivo", "de"],
                gloss: Gloss(en: "I work \(profile.workplace.gloss.en).", it: "Lavoro \(profile.workplace.gloss.it)."),
                hint: Gloss(en: "Start with the action: trabaj- + -o.", it: "Inizia con l'azione: trabaj- + -o."),
                formKeys: [key("trabajar")]
            ),
            builder(
                id: "u1l1-home",
                intention: Gloss(en: "Say where you live.", it: "Di dove vivi."),
                sentence: "Vivo en \(profile.city).",
                tiles: ["Vivo", "en", profile.city, "Trabajo", "de"],
                gloss: Gloss(en: "I live in \(profile.city).", it: "Vivo a \(profile.city)."),
                hint: Gloss(en: "Places take en: Vivo en...", it: "I luoghi vogliono en: Vivo en..."),
                formKeys: [key("vivir")]
            ),
            builder(
                id: "u1l1-language",
                intention: Gloss(en: "Say which language you speak, and that you speak a little Spanish.", it: "Di che lingua parli, e che parli un po' di spagnolo."),
                sentence: "Hablo \(native) y un poco de español.",
                tiles: ["Hablo", native, "y", "un", "poco", "de", "español", "Estudio"],
                gloss: Gloss(en: "I speak \(profile.nativeLanguage == .english ? "English" : "Italian") and a little Spanish.",
                             it: "Parlo \(profile.nativeLanguage == .english ? "inglese" : "italiano") e un po' di spagnolo."),
                hint: Gloss(en: "y joins the two parts: Hablo ... y un poco de español.", it: "y unisce le due parti: Hablo ... y un poco de español."),
                formKeys: [key("hablar")]
            ),
            builder(
                id: "u1l1-study",
                intention: Gloss(en: "Say that you study Spanish at night.", it: "Di che studi spagnolo la sera."),
                sentence: "Estudio español por la noche.",
                tiles: ["Estudio", "español", "por", "la", "noche", "Hablo", "el"],
                gloss: Gloss(en: "I study Spanish at night.", it: "Studio spagnolo la sera."),
                hint: Gloss(en: "Time chunk: por la noche.", it: "Blocco di tempo: por la noche."),
                formKeys: [key("estudiar")]
            ),
            builder(
                id: "u1l1-name",
                intention: Gloss(en: "Say your name.", it: "Di come ti chiami."),
                sentence: "Me llamo \(profile.name).",
                tiles: ["Me", "llamo", profile.name, "Vivo"],
                gloss: Gloss(en: "My name is \(profile.name).", it: "Mi chiamo \(profile.name)."),
                hint: Gloss(en: "Learn it as one block: Me llamo...", it: "Imparalo come un blocco: Me llamo..."),
                formKeys: []
            ),
        ]

        // Fix + output: all three sentences joined with y.
        let workplace = profile.workplace.spanish
        let output = LessonItem(
            id: "u1l1-output",
            beat: .fix,
            kind: .freeWrite(FreeWrite(
                instruction: Gloss(en: "Now all together: your name, where you live and where you work, joined with y.",
                                   it: "Ora tutto insieme: il tuo nome, dove vivi e dove lavori, uniti con y."),
                requiredChunks: ["me llamo \(profile.name)", "vivo en \(profile.city)", "trabajo en \(workplace)", "y"],
                model: Example(
                    es: "Me llamo \(profile.name), vivo en \(profile.city) y trabajo en \(workplace).",
                    gloss: Gloss(en: "My name is \(profile.name), I live in \(profile.city) and I work \(profile.workplace.gloss.en).",
                                 it: "Mi chiamo \(profile.name), vivo a \(profile.city) e lavoro \(profile.workplace.gloss.it).")
                )
            )),
            heartsAtRisk: true,
            formKeys: [key("vivir"), key("trabajar")]
        )

        return Lesson(
            id: "u1l1",
            number: 1,
            title: "Me presento",
            titleGloss: Gloss(en: "I introduce myself", it: "Mi presento"),
            goal: Gloss(en: "Say 3 true sentences about yourself with yo forms.", it: "Di 3 frasi vere su di te con le forme di yo."),
            items: [frame] + snaps + fire + [output]
        )
    }

    private static func builder(id: String, intention: Gloss, sentence: String, tiles: [String], gloss: Gloss, hint: Gloss, formKeys: [FormKey]) -> LessonItem {
        LessonItem(
            id: id,
            beat: .fire,
            kind: .builder(SentenceBuilder(
                intention: intention,
                tiles: tiles.shuffled(),
                accepted: [sentence],
                model: Example(es: sentence, gloss: gloss),
                hint: hint
            )),
            heartsAtRisk: true,
            formKeys: formKeys
        )
    }
}
