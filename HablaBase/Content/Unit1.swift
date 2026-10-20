import Foundation

/// Unit 1: the present tense and action basics (yo, tú, él/ella; y, pero, también, porque).
enum Unit1 {
    static let verbs: [Verb] = [
        Verb(lemma: "hablar", meaning: Gloss(en: "to speak", it: "parlare"),
             present: [Gloss(en: "I speak", it: "parlo"), Gloss(en: "you speak", it: "parli"), Gloss(en: "she speaks", it: "parla")],
             complement: "español", complementGloss: Gloss(en: "Spanish", it: "spagnolo")),
        Verb(lemma: "trabajar", meaning: Gloss(en: "to work", it: "lavorare"),
             present: [Gloss(en: "I work", it: "lavoro"), Gloss(en: "you work", it: "lavori"), Gloss(en: "she works", it: "lavora")],
             complement: "en una oficina", complementGloss: Gloss(en: "in an office", it: "in un ufficio")),
        Verb(lemma: "estudiar", meaning: Gloss(en: "to study", it: "studiare"),
             present: [Gloss(en: "I study", it: "studio"), Gloss(en: "you study", it: "studi"), Gloss(en: "she studies", it: "studia")],
             complement: "por la noche", complementGloss: Gloss(en: "at night", it: "la sera")),
        Verb(lemma: "cocinar", meaning: Gloss(en: "to cook", it: "cucinare"),
             present: [Gloss(en: "I cook", it: "cucino"), Gloss(en: "you cook", it: "cucini"), Gloss(en: "she cooks", it: "cucina")],
             complement: "pasta", complementGloss: Gloss(en: "pasta", it: "la pasta")),
        Verb(lemma: "escuchar", meaning: Gloss(en: "to listen", it: "ascoltare"),
             present: [Gloss(en: "I listen to", it: "ascolto"), Gloss(en: "you listen to", it: "ascolti"), Gloss(en: "she listens to", it: "ascolta")],
             complement: "música", complementGloss: Gloss(en: "music", it: "musica")),
        Verb(lemma: "caminar", meaning: Gloss(en: "to walk", it: "camminare"),
             present: [Gloss(en: "I walk", it: "cammino"), Gloss(en: "you walk", it: "cammini"), Gloss(en: "she walks", it: "cammina")],
             complement: "al trabajo", complementGloss: Gloss(en: "to work", it: "al lavoro")),
        Verb(lemma: "comer", meaning: Gloss(en: "to eat", it: "mangiare"),
             present: [Gloss(en: "I eat", it: "mangio"), Gloss(en: "you eat", it: "mangi"), Gloss(en: "she eats", it: "mangia")],
             complement: "en casa", complementGloss: Gloss(en: "at home", it: "a casa")),
        Verb(lemma: "beber", meaning: Gloss(en: "to drink", it: "bere"),
             present: [Gloss(en: "I drink", it: "bevo"), Gloss(en: "you drink", it: "bevi"), Gloss(en: "she drinks", it: "beve")],
             complement: "café", complementGloss: Gloss(en: "coffee", it: "caffè")),
        Verb(lemma: "leer", meaning: Gloss(en: "to read", it: "leggere"),
             present: [Gloss(en: "I read", it: "leggo"), Gloss(en: "you read", it: "leggi"), Gloss(en: "she reads", it: "legge")],
             complement: "libros", complementGloss: Gloss(en: "books", it: "libri")),
        Verb(lemma: "aprender", meaning: Gloss(en: "to learn", it: "imparare"),
             present: [Gloss(en: "I learn", it: "imparo"), Gloss(en: "you learn", it: "impari"), Gloss(en: "she learns", it: "impara")],
             complement: "español", complementGloss: Gloss(en: "Spanish", it: "lo spagnolo")),
        Verb(lemma: "vivir", meaning: Gloss(en: "to live", it: "vivere"),
             present: [Gloss(en: "I live", it: "vivo"), Gloss(en: "you live", it: "vivi"), Gloss(en: "she lives", it: "vive")],
             complement: "en Madrid", complementGloss: Gloss(en: "in Madrid", it: "a Madrid")),
        Verb(lemma: "escribir", meaning: Gloss(en: "to write", it: "scrivere"),
             present: [Gloss(en: "I write", it: "scrivo"), Gloss(en: "you write", it: "scrivi"), Gloss(en: "she writes", it: "scrive")],
             complement: "mensajes", complementGloss: Gloss(en: "messages", it: "messaggi")),
    ]

    /// The persons Unit 1 teaches; nosotros, vosotros and ellos arrive in Unit 2.
    static let persons: [Person] = [.yo, .tu, .el]

    static func verb(_ lemma: String) -> Verb {
        verbs.first { $0.lemma == lemma }!
    }

    /// Persons unlocked so far; the Lab rack lights up accordingly. Lesson 1 teaches all three.
    static func unlockedPersons(completed: Set<String>) -> [Person] {
        completed.contains("u1l1") ? persons : [.yo]
    }

    /// Lessons and tests whose exercises exist in the app. The rest of the curriculum shows as "coming soon".
    static func lesson(id: String, profile: Profile) -> Lesson? {
        switch id {
        case "u1l1": return lesson1()
        case "u1l2": return lesson2(profile: profile)
        case "u1test": return unitTest()
        default: return nil
        }
    }

    // MARK: - Lesson 1: Yo, tú, él
    // Explain one person, practise it twice, move to the next person, then mix them all.

    static func lesson1() -> Lesson {
        let items: [LessonItem] = [
            explain("u1l1-yo", .form("habl", "o",
                rule: Gloss(en: "In Spanish, the ending tells who. Talking about yourself (yo)? End with -o.",
                            it: "In spagnolo la desinenza dice chi. Parli di te (yo)? Finisci con -o."),
                examples: [
                    Example(es: "Hablo español.", gloss: Gloss(en: "I speak Spanish.", it: "Parlo spagnolo.")),
                    Example(es: "Como en casa.", gloss: Gloss(en: "I eat at home.", it: "Mangio a casa.")),
                    Example(es: "Vivo en Madrid.", gloss: Gloss(en: "I live in Madrid.", it: "Vivo a Madrid.")),
                ])),
            snap("u1l1-yo-1", .forge, "trabajar", .yo, stemsFrom: ["trabajar", "vivir", "hablar", "comer"], endings: ["o"]),
            gap("u1l1-yo-2", .forge, "estudiar", .yo),

            explain("u1l1-tu", .form("habl", "as",
                rule: Gloss(en: "Talking to someone (tú)? Add -s: AR verbs end in -as, ER and IR verbs in -es.",
                            it: "Parli con qualcuno (tú)? Aggiungi -s: i verbi in AR finiscono in -as, quelli in ER e IR in -es."),
                examples: [
                    Example(es: "¿Hablas inglés?", gloss: Gloss(en: "Do you speak English?", it: "Parli inglese?")),
                    Example(es: "¿Comes carne?", gloss: Gloss(en: "Do you eat meat?", it: "Mangi carne?")),
                    Example(es: "¿Dónde vives?", gloss: Gloss(en: "Where do you live?", it: "Dove vivi?")),
                ])),
            snap("u1l1-tu-1", .forge, "comer", .tu, stemsFrom: ["comer", "cocinar", "leer", "escuchar"], endings: ["o", "as", "es"]),
            gap("u1l1-tu-2", .forge, "hablar", .tu),

            explain("u1l1-el", .form("habl", "a",
                rule: Gloss(en: "Talking about someone else (él, ella)? Take the tú form and drop the -s: -a for AR, -e for ER and IR.",
                            it: "Parli di qualcun altro (él, ella)? Prendi la forma di tú e togli la -s: -a per AR, -e per ER e IR."),
                examples: [
                    Example(es: "Mi amiga habla tres idiomas.", gloss: Gloss(en: "My friend speaks three languages.", it: "La mia amica parla tre lingue.")),
                    Example(es: "Mi padre lee el periódico.", gloss: Gloss(en: "My father reads the newspaper.", it: "Mio padre legge il giornale.")),
                    Example(es: "Mi madre vive en Nápoles.", gloss: Gloss(en: "My mother lives in Naples.", it: "Mia madre vive a Napoli.")),
                ])),
            snap("u1l1-el-1", .forge, "escribir", .el, stemsFrom: ["escribir", "beber", "caminar", "aprender"], endings: ["o", "es", "e", "a"]),
            gap("u1l1-el-2", .forge, "trabajar", .el),

            // Mix: all three persons, all three families.
            gap("u1l1-mix-1", .mix, "vivir", .tu),
            snap("u1l1-mix-2", .mix, "escuchar", .yo, stemsFrom: ["escuchar", "estudiar", "leer", "vivir"], endings: ["o", "as", "a"]),
            gap("u1l1-mix-3", .mix, "beber", .el),
            gap("u1l1-mix-4", .mix, "cocinar", .yo),
            snap("u1l1-mix-5", .mix, "leer", .tu, stemsFrom: ["leer", "hablar", "comer", "escribir"], endings: ["es", "as", "e", "a"]),
            builder("u1l1-mix-6", .mix,
                    intention: Gloss(en: "Ask someone if they live in Madrid.", it: "Chiedi a qualcuno se vive a Madrid."),
                    sentence: "¿Vives en Madrid?", tiles: ["Vives", "en", "Madrid", "Vivo", "Vive"],
                    gloss: Gloss(en: "Do you live in Madrid?", it: "Vivi a Madrid?"),
                    hint: Gloss(en: "Talking to someone: viv- + -es.", it: "Parli con qualcuno: viv- + -es."),
                    formKeys: [Conjugator.key(verb("vivir"), .presente, .tu)]),
        ]

        return Lesson(
            id: "u1l1",
            title: "Yo, tú, él",
            titleGloss: Gloss(en: "I, you, he", it: "Io, tu, lui"),
            goal: Gloss(en: "Build present-tense forms for yo, tú and él/ella in all three verb families.",
                        it: "Costruisci il presente per yo, tú ed él/ella nelle tre famiglie di verbi."),
            mode: .lesson,
            items: items
        )
    }

    // MARK: - Lesson 2: Me presento
    // Say three true sentences about yourself, built from the onboarding answers.

    static func lesson2(profile: Profile) -> Lesson {
        func key(_ lemma: String) -> FormKey { Conjugator.key(verb(lemma), .presente, .yo) }
        let native = profile.nativeLanguage.spanishName
        let workplace = profile.workplace.spanish

        let items: [LessonItem] = [
            explain("u1l2-frame", FrameCard(
                bricks: [FrameBrick(text: "Trabajo", kind: .stem), FrameBrick(text: "en", kind: .rail), FrameBrick(text: "una oficina", kind: .chunk)],
                result: nil,
                rule: Gloss(en: "A sentence is action + place. You don't need yo: the -o already says it's you.",
                            it: "Una frase è azione + luogo. Non serve yo: la -o dice già che sei tu."),
                examples: [
                    Example(es: "Trabajo en una oficina.", gloss: Gloss(en: "I work in an office.", it: "Lavoro in un ufficio.")),
                    Example(es: "Vivo en Roma.", gloss: Gloss(en: "I live in Rome.", it: "Vivo a Roma.")),
                ])),
            builder("u1l2-work", .fire,
                    intention: Gloss(en: "Say where you work.", it: "Di dove lavori."),
                    sentence: "Trabajo en \(workplace).",
                    tiles: ["Trabajo", "en"] + workplace.split(separator: " ").map(String.init) + ["Vivo", "de"],
                    gloss: Gloss(en: "I work \(profile.workplace.gloss.en).", it: "Lavoro \(profile.workplace.gloss.it)."),
                    hint: Gloss(en: "Start with the action: trabaj- + -o.", it: "Inizia con l'azione: trabaj- + -o."),
                    formKeys: [key("trabajar")]),
            builder("u1l2-home", .fire,
                    intention: Gloss(en: "Say where you live.", it: "Di dove vivi."),
                    sentence: "Vivo en \(profile.city).",
                    tiles: ["Vivo", "en", profile.city, "Trabajo", "de"],
                    gloss: Gloss(en: "I live in \(profile.city).", it: "Vivo a \(profile.city)."),
                    hint: Gloss(en: "Places take en: Vivo en...", it: "I luoghi vogliono en: Vivo en..."),
                    formKeys: [key("vivir")]),

            explain("u1l2-y", FrameCard(
                bricks: [FrameBrick(text: "Hablo italiano", kind: .chunk), FrameBrick(text: "y", kind: .rail), FrameBrick(text: "estudio español", kind: .chunk)],
                result: nil,
                rule: Gloss(en: "y (and) joins two sentences into one. It is your first rail.",
                            it: "y (e) unisce due frasi in una. È il tuo primo binario."),
                examples: [
                    Example(es: "Como en casa y bebo agua.", gloss: Gloss(en: "I eat at home and drink water.", it: "Mangio a casa e bevo acqua.")),
                ])),
            builder("u1l2-language", .fire,
                    intention: Gloss(en: "Say which language you speak, and that you speak a little Spanish.", it: "Di che lingua parli, e che parli un po' di spagnolo."),
                    sentence: "Hablo \(native) y un poco de español.",
                    tiles: ["Hablo", native, "y", "un", "poco", "de", "español", "Estudio"],
                    gloss: Gloss(en: "I speak \(profile.nativeLanguage == .english ? "English" : "Italian") and a little Spanish.",
                                 it: "Parlo \(profile.nativeLanguage == .english ? "inglese" : "italiano") e un po' di spagnolo."),
                    hint: Gloss(en: "y joins the two parts: Hablo ... y un poco de español.", it: "y unisce le due parti: Hablo ... y un poco de español."),
                    formKeys: [key("hablar")]),
            builder("u1l2-study", .fire,
                    intention: Gloss(en: "Say that you study Spanish at night.", it: "Di che studi spagnolo la sera."),
                    sentence: "Estudio español por la noche.",
                    tiles: ["Estudio", "español", "por", "la", "noche", "Hablo", "el"],
                    gloss: Gloss(en: "I study Spanish at night.", it: "Studio spagnolo la sera."),
                    hint: Gloss(en: "Time chunk: por la noche.", it: "Blocco di tempo: por la noche."),
                    formKeys: [key("estudiar")]),
            builder("u1l2-name", .fire,
                    intention: Gloss(en: "Say your name.", it: "Di come ti chiami."),
                    sentence: "Me llamo \(profile.name).",
                    tiles: ["Me", "llamo", profile.name, "Vivo"],
                    gloss: Gloss(en: "My name is \(profile.name).", it: "Mi chiamo \(profile.name)."),
                    hint: Gloss(en: "Learn it as one block: Me llamo...", it: "Imparalo come un blocco: Me llamo..."),
                    formKeys: []),

            LessonItem(
                id: "u1l2-output",
                beat: .mix,
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
            ),
        ]

        return Lesson(
            id: "u1l2",
            title: "Me presento",
            titleGloss: Gloss(en: "I introduce myself", it: "Mi presento"),
            goal: Gloss(en: "Say 3 true sentences about yourself.", it: "Di 3 frasi vere su di te."),
            mode: .lesson,
            items: items
        )
    }

    // MARK: - Unit test
    // 10 mixed questions, no explanations. 8 right skips the unit.

    static func unitTest() -> Lesson {
        var rng = SystemRandomNumberGenerator()
        let picks = verbs.shuffled(using: &rng)
        var items: [LessonItem] = []

        for (index, verb) in picks.prefix(4).enumerated() {
            let person = persons.randomElement(using: &rng)!
            let others = verbs.filter { $0.lemma != verb.lemma }.shuffled(using: &rng).prefix(3).map(\.lemma)
            items.append(snap("u1test-snap-\(index)", .test, verb.lemma, person,
                              stemsFrom: [verb.lemma] + others, endings: ["o", "as", "es", "a", "e"]))
        }
        for (index, verb) in picks.dropFirst(4).prefix(5).enumerated() {
            items.append(gap("u1test-gap-\(index)", .test, verb.lemma, persons.randomElement(using: &rng)!))
        }
        let questions: [(String, [String], Gloss, Gloss)] = [
            ("¿Comes carne?", ["Comes", "carne", "Como", "Come"], Gloss(en: "Ask someone if they eat meat.", it: "Chiedi a qualcuno se mangia carne."), Gloss(en: "Do you eat meat?", it: "Mangi carne?")),
            ("¿Hablas inglés?", ["Hablas", "inglés", "Hablo", "Habla"], Gloss(en: "Ask someone if they speak English.", it: "Chiedi a qualcuno se parla inglese."), Gloss(en: "Do you speak English?", it: "Parli inglese?")),
            ("¿Trabajas hoy?", ["Trabajas", "hoy", "Trabajo", "Trabaja"], Gloss(en: "Ask someone if they are working today.", it: "Chiedi a qualcuno se lavora oggi."), Gloss(en: "Are you working today?", it: "Lavori oggi?")),
        ]
        let question = questions.randomElement(using: &rng)!
        items.append(builder("u1test-builder", .test, intention: question.2, sentence: question.0, tiles: question.1,
                             gloss: question.3, hint: Gloss(en: "Talking to someone: -as or -es.", it: "Parli con qualcuno: -as o -es."),
                             formKeys: []))

        return Lesson(
            id: "u1test",
            title: "Test: El presente",
            titleGloss: Gloss(en: "Unit 1 test", it: "Test dell'unità 1"),
            goal: Gloss(en: "Get 8 out of 10 right to skip the unit.", it: "Rispondi bene a 8 domande su 10 per saltare l'unità."),
            mode: .unitTest(unitId: "u1"),
            items: items.shuffled(using: &rng)
        )
    }

    // MARK: - Item builders

    private static func explain(_ id: String, _ card: FrameCard) -> LessonItem {
        LessonItem(id: id, beat: .frame, kind: .frame(card), heartsAtRisk: false, formKeys: [])
    }

    private static func snap(_ id: String, _ beat: Beat, _ lemma: String, _ person: Person,
                             stemsFrom lemmas: [String], endings: [String]) -> LessonItem {
        let target = verb(lemma)
        return LessonItem(
            id: id,
            beat: beat,
            kind: .legoSnap(LegoSnap(
                person: person,
                prompt: target.gloss(person),
                stems: lemmas.map { verb($0).stem }.sorted(),
                endings: endings,
                answer: Conjugator.conjugate(target, .presente, person)
            )),
            heartsAtRisk: false,
            formKeys: [Conjugator.key(target, .presente, person)]
        )
    }

    /// "Yo ___ por la noche." with the verb's own context chunk.
    private static func gap(_ id: String, _ beat: Beat, _ lemma: String, _ person: Person) -> LessonItem {
        let target = verb(lemma)
        let subject: String
        switch person {
        case .yo: subject = "Yo"
        case .tu: subject = "Tú"
        default: subject = "Ella"
        }
        let personGloss = target.gloss(person)
        let sentenceGloss = Gloss(en: capitalized("\(personGloss.en) \(target.complementGloss.en)."),
                                  it: capitalized("(\(subject.lowercased())) \(personGloss.it) \(target.complementGloss.it)."))
        return LessonItem(
            id: id,
            beat: beat,
            kind: .gapFill(GapFill(
                before: "\(subject) ",
                after: " \(target.complement).",
                lemma: lemma,
                accepted: [Conjugator.conjugate(target, .presente, person).text],
                gloss: sentenceGloss,
                hint: endingHint(person, target.family)
            )),
            heartsAtRisk: true,
            formKeys: [Conjugator.key(target, .presente, person)]
        )
    }

    private static func builder(_ id: String, _ beat: Beat, intention: Gloss, sentence: String, tiles: [String],
                                gloss: Gloss, hint: Gloss, formKeys: [FormKey]) -> LessonItem {
        LessonItem(
            id: id,
            beat: beat,
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

    static func endingHint(_ person: Person, _ family: Family) -> Gloss {
        let ending = Conjugator.presentEndings[family]?[person] ?? ""
        let family = family.rawValue.uppercased()
        return Gloss(en: "With \(person.label), \(family) verbs end in -\(ending).",
                     it: "Con \(person.label), i verbi in \(family) finiscono in -\(ending).")
    }

    private static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
