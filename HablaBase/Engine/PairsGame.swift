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
                gloss: Gloss(en: "Match each verb to the right person.", it: "Abbina ogni verbo alla persona giusta.", uk: "З'єднай кожне дієслово з правильною особою.", de: "Ordne jedes Verb der richtigen Person zu."),
                icon: "rectangle.on.rectangle", unlockedBy: "u1l1", isBuilt: true),
        LabGame(id: "rush", title: "Ending Rush",
                gloss: Gloss(en: "60 seconds: flick each stem into the right person lane.", it: "60 secondi: lancia ogni radice nella corsia giusta.", uk: "60 секунд: кидай кожну основу на доріжку правильної особи.", de: "60 Sekunden: Schnipp jeden Stamm in die Bahn der richtigen Person."),
                icon: "bolt.fill", unlockedBy: "u2l1", isBuilt: false),
        LabGame(id: "hunt", title: "Caza de errores",
                gloss: Gloss(en: "Spot and fix the wrong forms in a chat.", it: "Trova e correggi le forme sbagliate in una chat.", uk: "Знайди й виправ неправильні форми в чаті.", de: "Finde und korrigiere die falschen Formen in einem Chat."),
                icon: "magnifyingglass", unlockedBy: "u7l1", isBuilt: false),
        LabGame(id: "tenses", title: "Presente, pasado o futuro",
                gloss: Gloss(en: "Match each verb to its tense.", it: "Abbina ogni verbo al suo tempo.", uk: "З'єднай кожне дієслово з його часом.", de: "Ordne jedes Verb seiner Zeitform zu."),
                icon: "clock.arrow.circlepath", unlockedBy: "u14l1", isBuilt: false),
        LabGame(id: "timemachine", title: "Máquina del tiempo",
                gloss: Gloss(en: "Turn the time dial and re-conjugate the sentence.", it: "Gira la manopola del tempo e coniuga di nuovo la frase.", uk: "Поверни перемикач часу й переміни речення.", de: "Dreh am Zeitrad und konjugiere den Satz neu."),
                icon: "dial.medium", unlockedBy: "u21l1", isBuilt: false),
    ]

    static var built: [LabGame] { all.filter(\.isBuilt) }
}
