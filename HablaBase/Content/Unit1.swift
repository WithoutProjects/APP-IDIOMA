import Foundation

/// Unit 1: the present tense and action basics (yo, tú, él/ella; y, pero, también, porque).
enum Unit1 {
    static let verbs: [Verb] = [
        Verb(lemma: "hablar", meaning: Gloss(en: "to speak", it: "parlare", uk: "розмовляти", de: "sprechen", fr: "parler"),
             present: [Gloss(en: "I speak", it: "parlo", uk: "я розмовляю", de: "ich spreche", fr: "je parle"), Gloss(en: "you speak", it: "parli", uk: "ти розмовляєш", de: "du sprichst", fr: "tu parles"), Gloss(en: "she speaks", it: "parla", uk: "вона розмовляє", de: "sie spricht", fr: "elle parle")],
             complement: "español", complementGloss: Gloss(en: "Spanish", it: "spagnolo", uk: "іспанською", de: "Spanisch", fr: "espagnol")),
        Verb(lemma: "trabajar", meaning: Gloss(en: "to work", it: "lavorare", uk: "працювати", de: "arbeiten", fr: "travailler"),
             present: [Gloss(en: "I work", it: "lavoro", uk: "я працюю", de: "ich arbeite", fr: "je travaille"), Gloss(en: "you work", it: "lavori", uk: "ти працюєш", de: "du arbeitest", fr: "tu travailles"), Gloss(en: "she works", it: "lavora", uk: "вона працює", de: "sie arbeitet", fr: "elle travaille")],
             complement: "mucho", complementGloss: Gloss(en: "a lot", it: "molto", uk: "багато", de: "viel", fr: "beaucoup")),
        Verb(lemma: "estudiar", meaning: Gloss(en: "to study", it: "studiare", uk: "вчитися", de: "lernen", fr: "étudier"),
             present: [Gloss(en: "I study", it: "studio", uk: "я вчуся", de: "ich lerne", fr: "j'étudie"), Gloss(en: "you study", it: "studi", uk: "ти вчишся", de: "du lernst", fr: "tu étudies"), Gloss(en: "she studies", it: "studia", uk: "вона вчиться", de: "sie lernt", fr: "elle étudie")],
             complement: "por la noche", complementGloss: Gloss(en: "at night", it: "la sera", uk: "ввечері", de: "abends", fr: "le soir")),
        Verb(lemma: "cocinar", meaning: Gloss(en: "to cook", it: "cucinare", uk: "готувати", de: "kochen", fr: "cuisiner"),
             present: [Gloss(en: "I cook", it: "cucino", uk: "я готую", de: "ich koche", fr: "je cuisine"), Gloss(en: "you cook", it: "cucini", uk: "ти готуєш", de: "du kochst", fr: "tu cuisines"), Gloss(en: "she cooks", it: "cucina", uk: "вона готує", de: "sie kocht", fr: "elle cuisine")],
             complement: "pasta", complementGloss: Gloss(en: "pasta", it: "la pasta", uk: "пасту", de: "Pasta", fr: "des pâtes")),
        Verb(lemma: "escuchar", meaning: Gloss(en: "to listen", it: "ascoltare", uk: "слухати", de: "hören", fr: "écouter"),
             present: [Gloss(en: "I listen to", it: "ascolto", uk: "я слухаю", de: "ich höre", fr: "j'écoute"), Gloss(en: "you listen to", it: "ascolti", uk: "ти слухаєш", de: "du hörst", fr: "tu écoutes"), Gloss(en: "she listens to", it: "ascolta", uk: "вона слухає", de: "sie hört", fr: "elle écoute")],
             complement: "música", complementGloss: Gloss(en: "music", it: "musica", uk: "музику", de: "Musik", fr: "de la musique")),
        Verb(lemma: "caminar", meaning: Gloss(en: "to walk", it: "camminare", uk: "ходити пішки", de: "zu Fuß gehen", fr: "marcher"),
             present: [Gloss(en: "I walk", it: "cammino", uk: "я ходжу пішки", de: "ich gehe zu Fuß", fr: "je marche"), Gloss(en: "you walk", it: "cammini", uk: "ти ходиш пішки", de: "du gehst zu Fuß", fr: "tu marches"), Gloss(en: "she walks", it: "cammina", uk: "вона ходить пішки", de: "sie geht zu Fuß", fr: "elle marche")],
             complement: "al trabajo", complementGloss: Gloss(en: "to work", it: "al lavoro", uk: "працювати", de: "zur Arbeit", fr: "jusqu'au travail")),
        Verb(lemma: "comer", meaning: Gloss(en: "to eat", it: "mangiare", uk: "їсти", de: "essen", fr: "manger"),
             present: [Gloss(en: "I eat", it: "mangio", uk: "я їм", de: "ich esse", fr: "je mange"), Gloss(en: "you eat", it: "mangi", uk: "ти їси", de: "du isst", fr: "tu manges"), Gloss(en: "she eats", it: "mangia", uk: "вона їсть", de: "sie isst", fr: "elle mange")],
             complement: "mucho", complementGloss: Gloss(en: "a lot", it: "molto", uk: "багато", de: "viel", fr: "beaucoup")),
        Verb(lemma: "beber", meaning: Gloss(en: "to drink", it: "bere", uk: "пити", de: "trinken", fr: "boire"),
             present: [Gloss(en: "I drink", it: "bevo", uk: "я п'ю", de: "ich trinke", fr: "je bois"), Gloss(en: "you drink", it: "bevi", uk: "ти п'єш", de: "du trinkst", fr: "tu bois"), Gloss(en: "she drinks", it: "beve", uk: "вона п'є", de: "sie trinkt", fr: "elle boit")],
             complement: "café", complementGloss: Gloss(en: "coffee", it: "caffè", uk: "каву", de: "Kaffee", fr: "du café")),
        Verb(lemma: "leer", meaning: Gloss(en: "to read", it: "leggere", uk: "читати", de: "lesen", fr: "lire"),
             present: [Gloss(en: "I read", it: "leggo", uk: "я читаю", de: "ich lese", fr: "je lis"), Gloss(en: "you read", it: "leggi", uk: "ти читаєш", de: "du liest", fr: "tu lis"), Gloss(en: "she reads", it: "legge", uk: "вона читає", de: "sie liest", fr: "elle lit")],
             complement: "libros", complementGloss: Gloss(en: "books", it: "libri", uk: "книжки", de: "Bücher", fr: "des livres")),
        Verb(lemma: "aprender", meaning: Gloss(en: "to learn", it: "imparare", uk: "вивчати", de: "lernen", fr: "apprendre"),
             present: [Gloss(en: "I learn", it: "imparo", uk: "я вивчаю", de: "ich lerne", fr: "j'apprends"), Gloss(en: "you learn", it: "impari", uk: "ти вивчаєш", de: "du lernst", fr: "tu apprends"), Gloss(en: "she learns", it: "impara", uk: "вона вивчає", de: "sie lernt", fr: "elle apprend")],
             complement: "español", complementGloss: Gloss(en: "Spanish", it: "lo spagnolo", uk: "іспанську", de: "Spanisch", fr: "l'espagnol")),
        Verb(lemma: "vivir", meaning: Gloss(en: "to live", it: "vivere", uk: "жити", de: "wohnen", fr: "vivre"),
             present: [Gloss(en: "I live", it: "vivo", uk: "я живу", de: "ich wohne", fr: "je vis"), Gloss(en: "you live", it: "vivi", uk: "ти живеш", de: "du wohnst", fr: "tu vis"), Gloss(en: "she lives", it: "vive", uk: "вона живе", de: "sie wohnt", fr: "elle vit")],
             complement: "aquí", complementGloss: Gloss(en: "here", it: "qui", uk: "тут", de: "hier", fr: "ici")),
        Verb(lemma: "escribir", meaning: Gloss(en: "to write", it: "scrivere", uk: "писати", de: "schreiben", fr: "écrire"),
             present: [Gloss(en: "I write", it: "scrivo", uk: "я пишу", de: "ich schreibe", fr: "j'écris"), Gloss(en: "you write", it: "scrivi", uk: "ти пишеш", de: "du schreibst", fr: "tu écris"), Gloss(en: "she writes", it: "scrive", uk: "вона пише", de: "sie schreibt", fr: "elle écrit")],
             complement: "mucho", complementGloss: Gloss(en: "a lot", it: "molto", uk: "багато", de: "viel", fr: "beaucoup")),
    ]

    /// The persons Unit 1 teaches; nosotros, vosotros and ellos arrive in Unit 2.
    static let persons: [Person] = [.yo, .tu, .el]

    /// The six verbs Lesson 1 introduces: two per family. Exercises and games use only these
    /// until later lessons introduce more.
    static let coreLemmas = ["hablar", "trabajar", "comer", "beber", "vivir", "escribir"]
    static var coreVerbs: [Verb] { coreLemmas.map(verb) }

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
    // New words first (slides, then matching). Then explain one person, practise it twice,
    // move to the next person, and mix them all. Every word used was introduced first.

    static let personWords = VocabSet(words: [
        VocabWord(es: "yo", gloss: Gloss(en: "I", it: "io", uk: "я", de: "ich", fr: "je"), kind: .ending),
        VocabWord(es: "tú", gloss: Gloss(en: "you", it: "tu", uk: "ти", de: "du", fr: "tu"), kind: .ending),
        VocabWord(es: "él", gloss: Gloss(en: "he", it: "lui", uk: "він", de: "er", fr: "il"), kind: .ending),
        VocabWord(es: "ella", gloss: Gloss(en: "she", it: "lei", uk: "вона", de: "sie", fr: "elle"), kind: .ending),
    ])

    static var verbWords: VocabSet {
        VocabSet(words: coreVerbs.map { VocabWord(es: $0.lemma, gloss: $0.meaning, kind: .stem) })
    }

    static let extraWords = VocabSet(words: [
        VocabWord(es: "español", gloss: Gloss(en: "Spanish", it: "spagnolo", uk: "іспанською", de: "Spanisch", fr: "espagnol"), kind: .chunk),
        VocabWord(es: "café", gloss: Gloss(en: "coffee", it: "caffè", uk: "каву", de: "Kaffee", fr: "du café"), kind: .chunk),
        VocabWord(es: "mucho", gloss: Gloss(en: "a lot", it: "molto", uk: "багато", de: "viel", fr: "beaucoup"), kind: .chunk),
        VocabWord(es: "aquí", gloss: Gloss(en: "here", it: "qui", uk: "тут", de: "hier", fr: "ici"), kind: .chunk),
    ])

    static func lesson1() -> Lesson {
        let items: [LessonItem] = [
            slides("u1l1-words-persons", personWords),
            match("u1l1-match-persons", personWords),
            slides("u1l1-words-verbs", verbWords),
            match("u1l1-match-verbs", verbWords),
            slides("u1l1-words-extra", extraWords),
            match("u1l1-match-extra", extraWords),

            explain("u1l1-yo", .form("habl", "o",
                rule: Gloss(en: "A verb has two parts: the stem (blue) says the action, the ending (orange) says who. To talk about yourself (yo), take away -ar, -er or -ir and add -o.",
                            it: "Un verbo ha due parti: la radice (blu) dice l'azione, la desinenza (arancione) dice chi. Per parlare di te (yo), togli -ar, -er o -ir e aggiungi -o.",
                            uk: "Дієслово має дві частини: основа (синя) каже, що відбувається, закінчення (помаранчеве) каже хто. Щоб говорити про себе (yo), прибери -ar, -er або -ir і додай -o.",
                            de: "Ein Verb hat zwei Teile: Der Stamm (blau) sagt, was passiert, die Endung (orange) sagt, wer es tut. Wenn du über dich sprichst (yo), nimm -ar, -er oder -ir weg und häng -o an.",
                            fr: "Un verbe a deux parties : le radical (bleu) dit l'action, la terminaison (orange) dit qui la fait. Pour parler de toi (yo), enlève -ar, -er ou -ir et ajoute -o."),
                examples: [
                    Example(es: "Yo hablo español.", gloss: Gloss(en: "I speak Spanish.", it: "Io parlo spagnolo.", uk: "Я розмовляю іспанською.", de: "Ich spreche Spanisch.", fr: "Je parle espagnol.")),
                    Example(es: "Yo como mucho.", gloss: Gloss(en: "I eat a lot.", it: "Io mangio molto.", uk: "Я багато їм.", de: "Ich esse viel.", fr: "Je mange beaucoup.")),
                    Example(es: "Yo vivo aquí.", gloss: Gloss(en: "I live here.", it: "Io vivo qui.", uk: "Я живу тут.", de: "Ich wohne hier.", fr: "Je vis ici.")),
                ])),
            snap("u1l1-yo-1", .forge, "trabajar", .yo, stemsFrom: ["trabajar", "vivir", "hablar", "comer"], endings: ["o"]),
            gap("u1l1-yo-2", .forge, "hablar", .yo),

            explain("u1l1-tu", .form("habl", "as",
                rule: Gloss(en: "To talk to someone (tú), add -s: AR verbs end in -as, ER and IR verbs in -es. To ask a question, put the same sentence between ¿ and ?.",
                            it: "Per parlare con qualcuno (tú), aggiungi -s: i verbi in AR finiscono in -as, quelli in ER e IR in -es. Per fare una domanda, metti la stessa frase tra ¿ e ?.",
                            uk: "Щоб звернутися до когось (tú), додай -s: дієслова на AR закінчуються на -as, на ER та IR — на -es. Щоб поставити запитання, візьми те саме речення між ¿ і ?.",
                            de: "Wenn du mit jemandem sprichst (tú), häng -s an: AR-Verben enden auf -as, ER- und IR-Verben auf -es. Für eine Frage setzt du denselben Satz zwischen ¿ und ?.",
                            fr: "Pour parler à quelqu'un (tú), ajoute -s : les verbes en AR finissent en -as, ceux en ER et IR en -es. Pour poser une question, mets la même phrase entre ¿ et ?."),
                examples: [
                    Example(es: "Tú hablas español.", gloss: Gloss(en: "You speak Spanish.", it: "Tu parli spagnolo.", uk: "Ти розмовляєш іспанською.", de: "Du sprichst Spanisch.", fr: "Tu parles espagnol.")),
                    Example(es: "¿Tú bebes café?", gloss: Gloss(en: "Do you drink coffee?", it: "Tu bevi caffè?", uk: "Ти п'єш каву?", de: "Trinkst du Kaffee?", fr: "Tu bois du café ?")),
                    Example(es: "¿Tú vives aquí?", gloss: Gloss(en: "Do you live here?", it: "Tu vivi qui?", uk: "Ти живеш тут?", de: "Wohnst du hier?", fr: "Tu vis ici ?")),
                ])),
            snap("u1l1-tu-1", .forge, "comer", .tu, stemsFrom: ["comer", "beber", "hablar", "escribir"], endings: ["o", "as", "es"]),
            gap("u1l1-tu-2", .forge, "beber", .tu),

            explain("u1l1-el", .form("habl", "a",
                rule: Gloss(en: "To talk about someone else (él, ella), take the tú form and drop the -s: -a for AR, -e for ER and IR.",
                            it: "Per parlare di qualcun altro (él, ella), prendi la forma di tú e togli la -s: -a per AR, -e per ER e IR.",
                            uk: "Щоб говорити про когось іншого (él, ella), візьми форму для tú і прибери -s: -a для AR, -e для ER та IR.",
                            de: "Wenn du über jemand anderen sprichst (él, ella), nimm die tú-Form und lass das -s weg: -a bei AR, -e bei ER und IR.",
                            fr: "Pour parler de quelqu'un d'autre (él, ella), prends la forme de tú et enlève le -s : -a pour AR, -e pour ER et IR."),
                examples: [
                    Example(es: "Ella habla español.", gloss: Gloss(en: "She speaks Spanish.", it: "Lei parla spagnolo.", uk: "Вона розмовляє іспанською.", de: "Sie spricht Spanisch.", fr: "Elle parle espagnol.")),
                    Example(es: "Él bebe café.", gloss: Gloss(en: "He drinks coffee.", it: "Lui beve caffè.", uk: "Він п'є каву.", de: "Er trinkt Kaffee.", fr: "Il boit du café.")),
                    Example(es: "Ella vive aquí.", gloss: Gloss(en: "She lives here.", it: "Lei vive qui.", uk: "Вона живе тут.", de: "Sie wohnt hier.", fr: "Elle vit ici.")),
                ])),
            snap("u1l1-el-1", .forge, "escribir", .el, stemsFrom: ["escribir", "beber", "trabajar", "vivir"], endings: ["o", "es", "e", "a"]),
            gap("u1l1-el-2", .forge, "trabajar", .el),

            // Mix: all three persons, all three families.
            gap("u1l1-mix-1", .mix, "vivir", .tu),
            snap("u1l1-mix-2", .mix, "beber", .yo, stemsFrom: ["beber", "hablar", "vivir", "escribir"], endings: ["o", "as", "a"]),
            gap("u1l1-mix-3", .mix, "comer", .el),
            builder("u1l1-mix-4", .mix,
                    intention: Gloss(en: "Ask someone if they speak Spanish.", it: "Chiedi a qualcuno se parla spagnolo.", uk: "Запитай когось, чи розмовляє він іспанською.", de: "Frag jemanden, ob er Spanisch spricht.", fr: "Demande à quelqu'un s'il parle espagnol."),
                    accepted: ["¿Tú hablas español?", "¿Hablas español?"],
                    tiles: ["Tú", "hablas", "español", "hablo", "habla"],
                    gloss: Gloss(en: "Do you speak Spanish?", it: "Parli spagnolo?", uk: "Ти розмовляєш іспанською?", de: "Sprichst du Spanisch?", fr: "Tu parles espagnol ?"),
                    hint: Gloss(en: "Talking to someone: habl- + -as.", it: "Parli con qualcuno: habl- + -as.", uk: "Звертаєшся до когось: habl- + -as.", de: "Du sprichst mit jemandem: habl- + -as.", fr: "Tu parles à quelqu'un : habl- + -as."),
                    formKeys: [Conjugator.key(verb("hablar"), .presente, .tu)]),
        ]

        return Lesson(
            id: "u1l1",
            title: "Yo, tú, él",
            titleGloss: Gloss(en: "I, you, he", it: "Io, tu, lui", uk: "Я, ти, він", de: "Ich, du, er", fr: "Je, tu, il"),
            goal: Gloss(en: "Learn 14 words and build present-tense forms for yo, tú and él/ella.",
                        it: "Impara 14 parole e costruisci il presente per yo, tú ed él/ella.",
                        uk: "Вивчи 14 слів і склади форми теперішнього часу для yo, tú та él/ella.",
                        de: "Lerne 14 Wörter und bilde Präsensformen für yo, tú und él/ella.",
                        fr: "Apprends 14 mots et construis le présent pour yo, tú et él/ella."),
            mode: .lesson,
            items: items,
            target: Example(es: "Yo hablo español. ¿Tú hablas español?",
                            gloss: Gloss(en: "I speak Spanish. Do you speak Spanish?", it: "Io parlo spagnolo. Tu parli spagnolo?", uk: "Я розмовляю іспанською. Ти розмовляєш іспанською?", de: "Ich spreche Spanisch. Sprichst du Spanisch?", fr: "Je parle espagnol. Tu parles espagnol ?"))
        )
    }

    // MARK: - Lesson 2: Me presento
    // Say three true sentences about yourself, built from the onboarding answers.

    static func lesson2Words(profile: Profile) -> VocabSet {
        let native = profile.nativeLanguage
        return VocabSet(words: [
            VocabWord(es: "me llamo", gloss: Gloss(en: "my name is", it: "mi chiamo", uk: "мене звати", de: "ich heiße", fr: "je m'appelle"), kind: .chunk),
            VocabWord(es: "en", gloss: Gloss(en: "in", it: "in, a", uk: "в, у", de: "in", fr: "à, dans"), kind: .rail),
            VocabWord(es: "y", gloss: Gloss(en: "and", it: "e", uk: "і", de: "und", fr: "et"), kind: .rail),
            VocabWord(es: profile.workplace.spanish, gloss: profile.workplace.nounGloss, kind: .chunk),
            VocabWord(es: native.spanishName,
                      gloss: native.languageNameGloss,
                      kind: .chunk),
            VocabWord(es: "un poco de", gloss: Gloss(en: "a little", it: "un po' di", uk: "трохи", de: "ein bisschen", fr: "un peu de"), kind: .chunk),
        ])
    }

    static func lesson2(profile: Profile) -> Lesson {
        func key(_ lemma: String) -> FormKey { Conjugator.key(verb(lemma), .presente, .yo) }
        let native = profile.nativeLanguage.spanishName
        let workplace = profile.workplace.spanish
        let words = lesson2Words(profile: profile)

        let items: [LessonItem] = [
            slides("u1l2-words", words),
            match("u1l2-match", words),

            explain("u1l2-frame", FrameCard(
                bricks: [FrameBrick(text: "Trabajo", kind: .stem), FrameBrick(text: "en", kind: .rail), FrameBrick(text: workplace, kind: .chunk)],
                result: nil,
                rule: Gloss(en: "To say where, put en before the place. You can leave out yo: the -o already says it's you.",
                            it: "Per dire dove, metti en prima del luogo. Puoi togliere yo: la -o dice già che sei tu.",
                            uk: "Щоб сказати де, постав en перед місцем. Yo можна не казати: -o вже показує, що це ти.",
                            de: "Um zu sagen, wo, setzt du en vor den Ort. Yo kannst du weglassen: Das -o zeigt schon, dass du es bist.",
                            fr: "Pour dire où, mets en devant le lieu. Tu peux omettre yo : le -o indique déjà que c'est toi."),
                examples: [
                    Example(es: "Trabajo en \(workplace).", gloss: Gloss(en: "I work \(profile.workplace.gloss.en).", it: "Lavoro \(profile.workplace.gloss.it).", uk: "Я працюю \(profile.workplace.gloss.uk).", de: "Ich arbeite \(profile.workplace.gloss.text(.german)).", fr: "Je travaille \(profile.workplace.gloss.text(.french)).")),
                    Example(es: "Vivo en \(profile.city).", gloss: Gloss(en: "I live in \(profile.city).", it: "Vivo a \(profile.city).", uk: "Я живу в місті \(profile.city).", de: "Ich wohne in \(profile.city).", fr: "J'habite à \(profile.city).")),
                ])),
            builder("u1l2-work", .fire,
                    intention: Gloss(en: "Say where you work.", it: "Di dove lavori.", uk: "Скажи, де ти працюєш.", de: "Sag, wo du arbeitest.", fr: "Dis où tu travailles."),
                    accepted: ["Trabajo en \(workplace).", "Yo trabajo en \(workplace)."],
                    tiles: ["Trabajo", "en", workplace, "Vivo", "aquí"],
                    gloss: Gloss(en: "I work \(profile.workplace.gloss.en).", it: "Lavoro \(profile.workplace.gloss.it).", uk: "Я працюю \(profile.workplace.gloss.uk).", de: "Ich arbeite \(profile.workplace.gloss.text(.german)).", fr: "Je travaille \(profile.workplace.gloss.text(.french))."),
                    hint: Gloss(en: "Action, then en, then the place.", it: "Azione, poi en, poi il luogo.", uk: "Дія, потім en, потім місце.", de: "Erst die Handlung, dann en, dann der Ort.", fr: "L'action, puis en, puis le lieu."),
                    formKeys: [key("trabajar")]),
            builder("u1l2-home", .fire,
                    intention: Gloss(en: "Say which city you live in.", it: "Di in che città vivi.", uk: "Скажи, в якому місті ти живеш.", de: "Sag, in welcher Stadt du wohnst.", fr: "Dis dans quelle ville tu vis."),
                    accepted: ["Vivo en \(profile.city).", "Yo vivo en \(profile.city)."],
                    tiles: ["Vivo", "en", profile.city, "Trabajo", "aquí"],
                    gloss: Gloss(en: "I live in \(profile.city).", it: "Vivo a \(profile.city).", uk: "Я живу в місті \(profile.city).", de: "Ich wohne in \(profile.city).", fr: "J'habite à \(profile.city)."),
                    hint: Gloss(en: "viv- + -o, then en and your city.", it: "viv- + -o, poi en e la tua città.", uk: "viv- + -o, потім en і твоє місто.", de: "viv- + -o, dann en und deine Stadt.", fr: "viv- + -o, puis en et ta ville."),
                    formKeys: [key("vivir")]),

            explain("u1l2-y", FrameCard(
                bricks: [FrameBrick(text: "Hablo español", kind: .chunk), FrameBrick(text: "y", kind: .rail), FrameBrick(text: "bebo café", kind: .chunk)],
                result: nil,
                rule: Gloss(en: "y (and) joins two sentences into one. It is your first connector.",
                            it: "y (e) unisce due frasi in una. È il tuo primo connettore.",
                            uk: "y (і) з'єднує два речення в одне. Це твій перший сполучник.",
                            de: "y (und) verbindet zwei Sätze zu einem. Das ist dein erstes Bindewort.",
                            fr: "y (et) relie deux phrases en une. C'est ton premier connecteur."),
                examples: [
                    Example(es: "Como mucho y bebo café.", gloss: Gloss(en: "I eat a lot and drink coffee.", it: "Mangio molto e bevo caffè.", uk: "Я багато їм і п'ю каву.", de: "Ich esse viel und trinke Kaffee.", fr: "Je mange beaucoup et je bois du café.")),
                    Example(es: "Hablo \(native) y un poco de español.", gloss: Gloss(en: "I speak \(profile.nativeLanguage.spokenName.en) and a little Spanish.",
                                                                                      it: "Parlo \(profile.nativeLanguage.spokenName.it) e un po' di spagnolo.",
                                                                                      uk: "Я розмовляю \(profile.nativeLanguage.spokenName.uk) і трохи іспанською.",
                                                                                      de: "Ich spreche \(profile.nativeLanguage.spokenName.text(.german)) und ein bisschen Spanisch.",
                                                                                      fr: "Je parle \(profile.nativeLanguage.spokenName.text(.french)) et un peu d'espagnol.")),
                ])),
            builder("u1l2-language", .fire,
                    intention: Gloss(en: "Say which language you speak, and that you speak a little Spanish.", it: "Di che lingua parli, e che parli un po' di spagnolo.", uk: "Скажи, якою мовою ти розмовляєш і що трохи розмовляєш іспанською.", de: "Sag, welche Sprache du sprichst und dass du ein bisschen Spanisch sprichst.", fr: "Dis quelle langue tu parles, et que tu parles un peu d'espagnol."),
                    accepted: ["Hablo \(native) y un poco de español."],
                    tiles: ["Hablo", native, "y", "un poco de", "español", "Como"],
                    gloss: Gloss(en: "I speak \(profile.nativeLanguage.spokenName.en) and a little Spanish.",
                                 it: "Parlo \(profile.nativeLanguage.spokenName.it) e un po' di spagnolo.",
                                 uk: "Я розмовляю \(profile.nativeLanguage.spokenName.uk) і трохи іспанською.",
                                 de: "Ich spreche \(profile.nativeLanguage.spokenName.text(.german)) und ein bisschen Spanisch.",
                                 fr: "Je parle \(profile.nativeLanguage.spokenName.text(.french)) et un peu d'espagnol."),
                    hint: Gloss(en: "y joins the two parts: Hablo ... y un poco de español.", it: "y unisce le due parti: Hablo ... y un poco de español.", uk: "y з'єднує дві частини: Hablo ... y un poco de español.", de: "y verbindet die beiden Teile: Hablo ... y un poco de español.", fr: "y relie les deux parties : Hablo ... y un poco de español."),
                    formKeys: [key("hablar")]),
            builder("u1l2-name", .fire,
                    intention: Gloss(en: "Say your name.", it: "Di come ti chiami.", uk: "Скажи, як тебе звати.", de: "Sag, wie du heißt.", fr: "Dis ton prénom."),
                    accepted: ["Me llamo \(profile.name)."],
                    tiles: ["Me llamo", profile.name, "Vivo"],
                    gloss: Gloss(en: "My name is \(profile.name).", it: "Mi chiamo \(profile.name).", uk: "Мене звати \(profile.name).", de: "Ich heiße \(profile.name).", fr: "Je m'appelle \(profile.name)."),
                    hint: Gloss(en: "Start with me llamo.", it: "Inizia con me llamo.", uk: "Почни з me llamo.", de: "Beginne mit me llamo.", fr: "Commence par me llamo."),
                    formKeys: []),

            LessonItem(
                id: "u1l2-output",
                beat: .mix,
                kind: .freeWrite(FreeWrite(
                    instruction: Gloss(en: "Now all together: your name, where you live and where you work, joined with y.",
                                       it: "Ora tutto insieme: il tuo nome, dove vivi e dove lavori, uniti con y.",
                                       uk: "Тепер усе разом: як тебе звати, де ти живеш і де працюєш, з'єднай за допомогою y.",
                                       de: "Jetzt alles zusammen: dein Name, wo du wohnst und wo du arbeitest, verbunden mit y.",
                                       fr: "Maintenant, tout ensemble : ton prénom, où tu vis et où tu travailles, reliés par y."),
                    requiredChunks: ["me llamo \(profile.name)", "vivo en \(profile.city)", "trabajo en \(workplace)", "y"],
                    model: Example(
                        es: "Me llamo \(profile.name), vivo en \(profile.city) y trabajo en \(workplace).",
                        gloss: Gloss(en: "My name is \(profile.name), I live in \(profile.city) and I work \(profile.workplace.gloss.en).",
                                     it: "Mi chiamo \(profile.name), vivo a \(profile.city) e lavoro \(profile.workplace.gloss.it).",
                                     uk: "Мене звати \(profile.name), я живу в місті \(profile.city) і працюю \(profile.workplace.gloss.uk).",
                                     de: "Ich heiße \(profile.name), ich wohne in \(profile.city) und ich arbeite \(profile.workplace.gloss.text(.german)).",
                                     fr: "Je m'appelle \(profile.name), j'habite à \(profile.city) et je travaille \(profile.workplace.gloss.text(.french)).")
                    )
                )),
                heartsAtRisk: true,
                formKeys: [key("vivir"), key("trabajar")]
            ),
        ]

        return Lesson(
            id: "u1l2",
            title: "Me presento",
            titleGloss: Gloss(en: "I introduce myself", it: "Mi presento", uk: "Я представляюся", de: "Ich stelle mich vor", fr: "Je me présente"),
            goal: Gloss(en: "Say 3 true sentences about yourself.", it: "Di 3 frasi vere su di te.", uk: "Скажи 3 правдиві речення про себе.", de: "Sag 3 wahre Sätze über dich.", fr: "Dis 3 phrases vraies sur toi."),
            mode: .lesson,
            items: items,
            target: Example(
                es: "Me llamo \(profile.name), vivo en \(profile.city) y trabajo en \(workplace).",
                gloss: Gloss(en: "My name is \(profile.name), I live in \(profile.city) and I work \(profile.workplace.gloss.en).",
                             it: "Mi chiamo \(profile.name), vivo a \(profile.city) e lavoro \(profile.workplace.gloss.it).",
                             uk: "Мене звати \(profile.name), я живу в місті \(profile.city) і працюю \(profile.workplace.gloss.uk).",
                             de: "Ich heiße \(profile.name), ich wohne in \(profile.city) und ich arbeite \(profile.workplace.gloss.text(.german)).",
                             fr: "Je m'appelle \(profile.name), j'habite à \(profile.city) et je travaille \(profile.workplace.gloss.text(.french)).")
            )
        )
    }

    // MARK: - Unit test
    // 10 mixed questions, no explanations, only words from the unit's lessons. 8 right skips the unit.

    static func unitTest() -> Lesson {
        var rng = SystemRandomNumberGenerator()
        let picks = (coreVerbs + coreVerbs).shuffled(using: &rng)
        var items: [LessonItem] = []

        for (index, verb) in picks.prefix(4).enumerated() {
            let person = persons.randomElement(using: &rng)!
            let others = coreVerbs.filter { $0.lemma != verb.lemma }.shuffled(using: &rng).prefix(3).map(\.lemma)
            items.append(snap("u1test-snap-\(index)", .test, verb.lemma, person,
                              stemsFrom: [verb.lemma] + others, endings: ["o", "as", "es", "a", "e"]))
        }
        for (index, verb) in picks.dropFirst(4).prefix(5).enumerated() {
            items.append(gap("u1test-gap-\(index)", .test, verb.lemma, persons.randomElement(using: &rng)!))
        }
        let questions: [(String, [String], Gloss, Gloss)] = [
            ("¿Bebes café?", ["Bebes", "café", "Bebo", "Bebe"], Gloss(en: "Ask someone if they drink coffee.", it: "Chiedi a qualcuno se beve caffè.", uk: "Запитай когось, чи п'є він каву.", de: "Frag jemanden, ob er Kaffee trinkt.", fr: "Demande à quelqu'un s'il boit du café."), Gloss(en: "Do you drink coffee?", it: "Bevi caffè?", uk: "Ти п'єш каву?", de: "Trinkst du Kaffee?", fr: "Tu bois du café ?")),
            ("¿Hablas español?", ["Hablas", "español", "Hablo", "Habla"], Gloss(en: "Ask someone if they speak Spanish.", it: "Chiedi a qualcuno se parla spagnolo.", uk: "Запитай когось, чи розмовляє він іспанською.", de: "Frag jemanden, ob er Spanisch spricht.", fr: "Demande à quelqu'un s'il parle espagnol."), Gloss(en: "Do you speak Spanish?", it: "Parli spagnolo?", uk: "Ти розмовляєш іспанською?", de: "Sprichst du Spanisch?", fr: "Tu parles espagnol ?")),
            ("¿Vives aquí?", ["Vives", "aquí", "Vivo", "Vive"], Gloss(en: "Ask someone if they live here.", it: "Chiedi a qualcuno se vive qui.", uk: "Запитай когось, чи живе він тут.", de: "Frag jemanden, ob er hier wohnt.", fr: "Demande à quelqu'un s'il vit ici."), Gloss(en: "Do you live here?", it: "Vivi qui?", uk: "Ти живеш тут?", de: "Wohnst du hier?", fr: "Tu vis ici ?")),
        ]
        let question = questions.randomElement(using: &rng)!
        items.append(builder("u1test-builder", .test, intention: question.2,
                             accepted: [question.0, "¿Tú " + question.0.dropFirst().lowercased()],
                             tiles: question.1, gloss: question.3,
                             hint: Gloss(en: "Talking to someone: -as or -es.", it: "Parli con qualcuno: -as o -es.", uk: "Звертаєшся до когось: -as або -es.", de: "Du sprichst mit jemandem: -as oder -es.", fr: "Tu parles à quelqu'un : -as ou -es."),
                             formKeys: []))

        return Lesson(
            id: "u1test",
            title: "Test: El presente",
            titleGloss: Gloss(en: "Unit 1 test", it: "Test dell'unità 1", uk: "Тест розділу 1", de: "Test zu Einheit 1", fr: "Test de l'unité 1"),
            goal: Gloss(en: "Get 8 out of 10 right to skip the unit.", it: "Rispondi bene a 8 domande su 10 per saltare l'unità.", uk: "Дай 8 правильних відповідей із 10, щоб пропустити розділ.", de: "Beantworte 8 von 10 Fragen richtig, um die Einheit zu überspringen.", fr: "Réponds juste à 8 questions sur 10 pour passer l'unité."),
            mode: .unitTest(unitId: "u1"),
            items: items.shuffled(using: &rng)
        )
    }

    // MARK: - Review and twins

    /// "Recupera energía": short practice on the forms the learner missed. Every right answer wins a bolt back.
    static func reviewLesson(weakForms: [FormKey], completed: Set<String>) -> Lesson {
        let persons = unlockedPersons(completed: completed)
        var keys = weakForms.filter { key in
            guard let parsed = parse(key) else { return false }
            return coreLemmas.contains(parsed.verb.lemma) && persons.contains(parsed.person)
        }
        if keys.count < 5 {
            keys += coreVerbs.shuffled().prefix(5).map { Conjugator.key($0, .presente, persons.randomElement()!) }
        }
        var items: [LessonItem] = []
        for (index, key) in keys.prefix(6).enumerated() {
            guard let parsed = parse(key) else { continue }
            let target = parsed.verb, person = parsed.person
            if index.isMultiple(of: 2) {
                let others = coreVerbs.filter { $0.lemma != target.lemma }.shuffled().prefix(3).map(\.lemma)
                items.append(snap("review-\(index)", .fix, target.lemma, person,
                                  stemsFrom: [target.lemma] + others, endings: ["o", "as", "es", "a", "e"]))
            } else {
                items.append(gap("review-\(index)", .fix, target.lemma, person))
            }
        }
        return Lesson(
            id: "review",
            title: "Repaso",
            titleGloss: Gloss(en: "Review", it: "Ripasso", uk: "Повторення", de: "Wiederholung", fr: "Révision"),
            goal: Gloss(en: "Fix your mistakes and win your hearts back.", it: "Correggi i tuoi errori e recupera i cuori.", uk: "Виправ свої помилки й поверни сердечка.", de: "Korrigiere deine Fehler und hol dir deine Herzen zurück.", fr: "Corrige tes erreurs et récupère tes cœurs."),
            mode: .review,
            items: items
        )
    }

    /// An easier question on the same pattern with another verb of the same family, right after
    /// someone gets stuck: one stem to choose and two endings.
    static func easyTwin(of key: FormKey, id: String) -> LessonItem? {
        guard let parsed = parse(key) else { return nil }
        let original = parsed.verb, person = parsed.person
        let twin = coreVerbs.first { $0.family == original.family && $0.lemma != original.lemma } ?? original
        let right = Conjugator.conjugate(twin, .presente, person).ending
        let wrong = ["o", "as", "es", "a", "e"].filter { $0 != right }.randomElement()!
        return snap(id, .review, twin.lemma, person, stemsFrom: [twin.lemma], endings: [right, wrong].shuffled())
    }

    /// "hablar.presente.yo" -> (hablar, yo), for Unit 1 verbs.
    static func parse(_ key: FormKey) -> (verb: Verb, person: Person)? {
        let parts = key.split(separator: ".")
        guard parts.count == 3, let verb = verbs.first(where: { $0.lemma == parts[0] }),
              let person = Person(rawValue: String(parts[2])) else { return nil }
        return (verb, person)
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
        let complement = target.complementGloss
        let sentenceGloss = Gloss(en: capitalized("\(personGloss.en) \(complement.en)."),
                                  it: capitalized("(\(subject.lowercased())) \(personGloss.it) \(complement.it)."),
                                  uk: capitalized("\(personGloss.uk) \(complement.uk)."),
                                  de: sentence(personGloss.de, complement.de),
                                  fr: sentence(personGloss.fr, complement.fr),
                                  pt: sentence(personGloss.pt, complement.pt),
                                  zh: personGloss.zh.flatMap { verb in complement.zh.map { verb + $0 + "。" } })
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

    private static func slides(_ id: String, _ set: VocabSet) -> LessonItem {
        LessonItem(id: id, beat: .words, kind: .slides(set), heartsAtRisk: false, formKeys: [])
    }

    private static func match(_ id: String, _ set: VocabSet) -> LessonItem {
        LessonItem(id: id, beat: .words, kind: .match(set), heartsAtRisk: false, formKeys: [])
    }

    private static func builder(_ id: String, _ beat: Beat, intention: Gloss, accepted: [String], tiles: [String],
                                gloss: Gloss, hint: Gloss, formKeys: [FormKey]) -> LessonItem {
        LessonItem(
            id: id,
            beat: beat,
            kind: .builder(SentenceBuilder(
                intention: intention,
                tiles: tiles.shuffled(),
                accepted: accepted,
                model: Example(es: accepted[0], gloss: gloss),
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
                     it: "Con \(person.label), i verbi in \(family) finiscono in -\(ending).",
                     uk: "Для \(person.label) дієслова на \(family) закінчуються на -\(ending).",
                     de: "Bei \(person.label) enden \(family)-Verben auf -\(ending).",
                     fr: "Avec \(person.label), les verbes en \(family) finissent en -\(ending).")
    }

    /// "ich spreche" + "Spanisch" -> "Ich spreche Spanisch."; nil until both parts are translated.
    private static func sentence(_ verb: String?, _ complement: String?) -> String? {
        guard let verb, let complement else { return nil }
        return capitalized("\(verb) \(complement).")
    }

    private static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
