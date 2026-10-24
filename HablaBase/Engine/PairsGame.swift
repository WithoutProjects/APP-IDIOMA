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
        LabGame(id: "tenses", title: "Presente, pasado o futuro",
                gloss: Gloss(en: "Match each verb to its tense.", it: "Abbina ogni verbo al suo tempo.", uk: "З'єднай кожне дієслово з його часом.", de: "Ordne jedes Verb seiner Zeitform zu.", fr: "Associe chaque verbe à son temps.", pt: "Ligue cada verbo ao seu tempo verbal.", zh: "把每个动词和它的时态配对。"),
                icon: "clock.arrow.circlepath", unlockedBy: "u14l1", isBuilt: false),
        LabGame(id: "timemachine", title: "Máquina del tiempo",
                gloss: Gloss(en: "Turn the time dial and re-conjugate the sentence.", it: "Gira la manopola del tempo e coniuga di nuovo la frase.", uk: "Поверни перемикач часу й переміни речення.", de: "Dreh am Zeitrad und konjugiere den Satz neu.", fr: "Tourne le cadran du temps et conjugue à nouveau la phrase.", pt: "Gire o seletor de tempo e conjugue a frase de novo.", zh: "转动时间旋钮，重新给句子变位。"),
                icon: "dial.medium", unlockedBy: "u21l1", isBuilt: false),
    ]

    static let sprintId = "sprint"
    static let huntId = "hunt"

    static var built: [LabGame] { all.filter(\.isBuilt) }
}
