import Foundation

/// "Parejas": match each verb form to its person. Every round uses different persons,
/// so each form has exactly one right partner.
enum PairsGame {
    struct Card: Identifiable, Hashable {
        let form: VerbForm
        let person: Person
        let key: FormKey

        var id: FormKey { key }
    }

    static let rounds = 5

    /// Builds the rounds from the verbs and persons the learner has unlocked.
    static func makeRounds(verbs: [Verb], persons: [Person], count: Int = PairsGame.rounds) -> [[Card]] {
        let perRound = min(persons.count, 4)
        guard perRound >= 2, !verbs.isEmpty else { return [] }
        return (0..<count).map { _ in
            let roundPersons = persons.shuffled().prefix(perRound)
            let roundVerbs = verbs.shuffled()
            return roundPersons.enumerated().map { index, person in
                let verb = roundVerbs[index % roundVerbs.count]
                return Card(form: Conjugator.conjugate(verb, .presente, person),
                            person: person,
                            key: Conjugator.key(verb, .presente, person))
            }
        }
    }
}

/// A verb minigame in the Lab. Each one opens at a point on the path.
struct LabGame: Identifiable {
    let id: String
    let title: String
    let gloss: Gloss
    let icon: String
    /// The path step that unlocks it.
    let unlockedBy: String
    /// False while the game is designed but not built yet. Only built games are shown.
    let isBuilt: Bool

    /// What the game practises; the Lab shows one section per kind.
    enum Kind: CaseIterable {
        case verbs, words, sentences

        var title: Gloss {
            switch self {
            case .verbs: return Gloss(en: "Verbs", it: "Verbi", uk: "Дієслова", de: "Verben", fr: "Verbes", pt: "Verbos", zh: "动词")
            case .words: return Gloss(en: "Words", it: "Parole", uk: "Слова", de: "Wörter", fr: "Mots", pt: "Palavras", zh: "词汇")
            case .sentences: return Gloss(en: "Sentences", it: "Frasi", uk: "Речення", de: "Sätze", fr: "Phrases", pt: "Frases", zh: "句子")
            }
        }
    }

    var kind: Kind {
        switch id {
        case LabGame.voiceId, LabGame.wordMatchId, LabGame.meaningId, LabGame.genderId, LabGame.oppositesId: return .words
        case LabGame.orderId, LabGame.dictationId, LabGame.huntId, LabGame.sayingsId: return .sentences
        default: return .verbs
        }
    }

    static let all: [LabGame] = [
        LabGame(id: "pairs", title: "Parejas",
                gloss: Gloss(en: "Match each verb to the right person.", it: "Abbina ogni verbo alla persona giusta.", uk: "З'єднай кожне дієслово з правильною особою.", de: "Ordne jedes Verb der richtigen Person zu.", fr: "Associe chaque verbe à la bonne personne.", pt: "Ligue cada verbo à pessoa certa.", zh: "把每个动词和正确的人称配对。"),
                icon: "rectangle.on.rectangle", unlockedBy: "u1l1", isBuilt: true),
        LabGame(id: LabGame.sprintId, title: "Contrarreloj",
                gloss: Gloss(en: "60 seconds: pick the right form of as many verbs as you can.", it: "60 secondi: scegli la forma giusta del maggior numero di verbi.", uk: "60 секунд: обери правильну форму якомога більшої кількості дієслів.", de: "60 Sekunden: Wähle die richtige Form von so vielen Verben wie möglich.", fr: "60 secondes : choisis la bonne forme du plus de verbes possible.", pt: "60 segundos: escolha a forma certa do maior número de verbos.", zh: "60 秒内：为尽可能多的动词选出正确形式。"),
                icon: "stopwatch", unlockedBy: "u1l2", isBuilt: true),
        LabGame(id: LabGame.huntId, title: "Caza de errores",
                gloss: Gloss(en: "Find the wrong verb in sentences from your lessons.", it: "Trova il verbo sbagliato nelle frasi delle tue lezioni.", uk: "Знайди неправильне дієслово в реченнях з твоїх уроків.", de: "Finde das falsche Verb in Sätzen aus deinen Lektionen.", fr: "Trouve le verbe faux dans des phrases de tes leçons.", pt: "Encontre o verbo errado em frases das suas lições.", zh: "在你课程的句子里找出错误的动词。"),
                icon: "magnifyingglass", unlockedBy: "u2boss", isBuilt: true),
        LabGame(id: LabGame.voiceId, title: "Dilo en español",
                gloss: Gloss(en: "See a word you've learned and say it in Spanish.", it: "Vedi una parola che hai imparato e dilla in spagnolo.", uk: "Побач слово, яке ти вивчив, і скажи його іспанською.", de: "Sieh ein gelerntes Wort und sag es auf Spanisch.", fr: "Vois un mot que tu as appris et dis-le en espagnol.", pt: "Veja uma palavra que você aprendeu e diga em espanhol.", zh: "看到学过的词，用西班牙语说出来。"),
                icon: "mic.fill", unlockedBy: "u1l1", isBuilt: true),
        LabGame(id: LabGame.wordMatchId, title: "Parejas de palabras",
                gloss: Gloss(en: "Match the words you've learned with their Spanish.", it: "Abbina le parole che hai imparato al loro spagnolo.", uk: "З'єднай вивчені слова з їхніми іспанськими відповідниками.", de: "Ordne gelernte Wörter ihrem Spanisch zu.", fr: "Associe les mots appris à leur équivalent espagnol.", pt: "Ligue as palavras que você aprendeu ao espanhol delas.", zh: "把学过的词和对应的西班牙语配对。"),
                icon: "square.grid.2x2", unlockedBy: "u1l1", isBuilt: true),
        LabGame(id: LabGame.orderId, title: "Ordena la frase",
                gloss: Gloss(en: "Put the words of a sentence from your lessons back in order.", it: "Rimetti in ordine le parole di una frase delle tue lezioni.", uk: "Розстав у правильному порядку слова речення з твоїх уроків.", de: "Bring die Wörter eines Satzes aus deinen Lektionen wieder in die richtige Reihenfolge.", fr: "Remets dans l'ordre les mots d'une phrase de tes leçons.", pt: "Coloque em ordem as palavras de uma frase das suas lições.", zh: "把你课程中一个句子的词语排回正确顺序。"),
                icon: "list.number", unlockedBy: "u1l2", isBuilt: true),
        LabGame(id: LabGame.dictationId, title: "Dictado",
                gloss: Gloss(en: "Listen to a sentence you've learned and write it in Spanish.", it: "Ascolta una frase che hai imparato e scrivila in spagnolo.", uk: "Послухай речення, яке ти вивчив, і запиши його іспанською.", de: "Hör dir einen gelernten Satz an und schreib ihn auf Spanisch.", fr: "Écoute une phrase que tu as apprise et écris-la en espagnol.", pt: "Ouça uma frase que você aprendeu e escreva em espanhol.", zh: "听一个学过的句子，用西班牙语写下来。"),
                icon: "ear", unlockedBy: "u2l1", isBuilt: true),
        LabGame(id: LabGame.tensesId, title: "¿Qué tiempo es?",
                gloss: Gloss(en: "See a verb form and say which tense it is.", it: "Guarda una forma verbale e indica in quale tempo è.", uk: "Подивись на форму дієслова й скажи, який це час.", de: "Sieh eine Verbform und sag, welche Zeitform es ist.", fr: "Regarde une forme verbale et dis à quel temps elle est.", pt: "Veja uma forma verbal e diga em que tempo está.", zh: "看一个动词形式，说出它是什么时态。"),
                icon: "clock.arrow.circlepath", unlockedBy: "u14l1", isBuilt: true),
        LabGame(id: LabGame.timeMachineId, title: "Máquina del tiempo",
                gloss: Gloss(en: "Move a verb to another tense and write the new form.", it: "Porta un verbo in un altro tempo e scrivi la nuova forma.", uk: "Перенеси дієслово в інший час і напиши нову форму.", de: "Setz ein Verb in eine andere Zeitform und schreib die neue Form.", fr: "Mets un verbe à un autre temps et écris la nouvelle forme.", pt: "Passe um verbo para outro tempo e escreva a nova forma.", zh: "把动词换成另一个时态，写出新的形式。"),
                icon: "dial.medium", unlockedBy: "u21l1", isBuilt: true),
        LabGame(id: LabGame.raceId, title: "Carrera de verbos",
                gloss: Gloss(en: "Write whole verb tables against the clock. Beat your best time.", it: "Scrivi tabelle intere di verbi contro il tempo. Batti il tuo miglior tempo.", uk: "Пиши цілі таблиці дієслів на час. Побий свій найкращий час.", de: "Schreib ganze Verbtabellen gegen die Uhr. Schlag deine Bestzeit.", fr: "Écris des tableaux de verbes entiers contre la montre. Bats ton meilleur temps.", pt: "Escreva tabelas inteiras de verbos contra o relógio. Supere seu melhor tempo.", zh: "限时写出完整的动词变位表。打破你的最好成绩。"),
                icon: "flag.checkered", unlockedBy: "u2l3", isBuilt: true),
        LabGame(id: LabGame.meaningId, title: "¿Qué significa?",
                gloss: Gloss(en: "See and hear a Spanish word you've learned, and pick what it means.", it: "Vedi e ascolta una parola spagnola che hai imparato e scegli che cosa significa.", uk: "Побач і почуй іспанське слово, яке ти вивчив, і обери, що воно означає.", de: "Sieh und hör ein gelerntes spanisches Wort und wähle, was es bedeutet.", fr: "Vois et écoute un mot espagnol que tu as appris, et choisis ce qu'il veut dire.", pt: "Veja e ouça uma palavra em espanhol que você aprendeu e escolha o que ela significa.", zh: "看并听一个学过的西班牙语词，选出它的意思。"),
                icon: "questionmark.bubble", unlockedBy: "u1l1", isBuilt: true),
        LabGame(id: LabGame.genderId, title: "¿El o la?",
                gloss: Gloss(en: "Is it el or la? Quick rounds with the nouns you've learned.", it: "È el o la? Round veloci con i nomi che hai imparato.", uk: "El чи la? Швидкі раунди з іменниками, які ти вивчив.", de: "El oder la? Schnelle Runden mit den Nomen, die du gelernt hast.", fr: "El ou la ? Des manches rapides avec les noms que tu as appris.", pt: "É el ou la? Rodadas rápidas com os substantivos que você aprendeu.", zh: "是 el 还是 la？用学过的名词快速答题。"),
                icon: "textformat", unlockedBy: "u4l3", isBuilt: true),
        LabGame(id: LabGame.oppositesId, title: "Contrarios",
                gloss: Gloss(en: "Find the opposite: alto and bajo, abrir and cerrar.", it: "Trova il contrario: alto e bajo, abrir e cerrar.", uk: "Знайди протилежність: alto і bajo, abrir і cerrar.", de: "Finde das Gegenteil: alto und bajo, abrir und cerrar.", fr: "Trouve le contraire : alto et bajo, abrir et cerrar.", pt: "Encontre o contrário: alto e bajo, abrir e cerrar.", zh: "找出反义词：alto 和 bajo，abrir 和 cerrar。"),
                icon: "arrow.left.arrow.right", unlockedBy: "u3l5", isBuilt: true),
        LabGame(id: LabGame.sayingsId, title: "Termina el refrán",
                gloss: Gloss(en: "Finish real Spanish sayings and learn what they mean.", it: "Completa veri proverbi spagnoli e scopri che cosa significano.", uk: "Закінчуй справжні іспанські прислів'я і дізнавайся, що вони означають.", de: "Vervollständige echte spanische Sprichwörter und lerne, was sie bedeuten.", fr: "Termine de vrais proverbes espagnols et découvre ce qu'ils veulent dire.", pt: "Complete ditados espanhóis de verdade e aprenda o que eles significam.", zh: "补全真正的西班牙俗语，了解它们的意思。"),
                icon: "quote.bubble", unlockedBy: "u24l1", isBuilt: true),
    ]

    static let sprintId = "sprint"
    static let huntId = "hunt"
    static let voiceId = "voice"
    static let wordMatchId = "wordmatch"
    static let orderId = "order"
    static let dictationId = "dictation"
    static let tensesId = "tenses"
    static let timeMachineId = "timemachine"
    static let meaningId = "meaning"
    static let raceId = "race"
    static let sayingsId = "sayings"
    static let genderId = "gender"
    static let oppositesId = "opposites"

    static var built: [LabGame] { all.filter(\.isBuilt) }
}
