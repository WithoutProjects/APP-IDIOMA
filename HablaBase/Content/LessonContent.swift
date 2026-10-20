import Foundation

/// Every playable step: Unit 1's first two lessons are written in Swift (Unit1.swift); the rest
/// come from the lessons-u{n}.json files (format: docs/content-format.md). Unit tests are drawn
/// from the unit's own lessons.
enum LessonContent {
    static func lesson(id: String, profile: Profile) -> Lesson? {
        if id.hasSuffix("test"), let test = unitTest(unitId: String(id.dropLast(4)), profile: profile) {
            return test
        }
        if let lesson = Unit1.lesson(id: id, profile: profile) { return lesson }
        return LessonLibrary.shared.spec(id)?.lesson(profile: profile)
    }

    /// The unit's built lessons, in order.
    static func lessons(ofUnit unitId: String, profile: Profile) -> [Lesson] {
        guard let unit = Curriculum.shared.unit(id: unitId) else { return [] }
        return unit.lessons.compactMap { lesson(id: $0.id, profile: profile) }
    }

    /// 10 questions drawn from every lesson of the unit, no explanations. 8 right skips the unit.
    /// Nil until every lesson of the unit exists.
    static func unitTest(unitId: String, profile: Profile) -> Lesson? {
        guard let unit = Curriculum.shared.unit(id: unitId) else { return nil }
        let unitLessons = lessons(ofUnit: unitId, profile: profile)
        guard !unitLessons.isEmpty, unitLessons.count == unit.lessons.count,
              unitLessons.allSatisfy({ if case .lesson = $0.mode { return true } else { return false } }) else { return nil }

        var rng = SystemRandomNumberGenerator()
        // Short questions from each lesson, taken in turns so every lesson is tested.
        var pools: [[LessonItem]] = unitLessons.map { lesson in
            lesson.items.filter { item in
                switch item.kind {
                case .legoSnap, .gapFill, .choice: return true
                default: return false
                }
            }.shuffled(using: &rng)
        }
        var picked: [LessonItem] = []
        while picked.count < Lesson.testQuestions - 1, pools.contains(where: { !$0.isEmpty }) {
            for index in pools.indices where !pools[index].isEmpty && picked.count < Lesson.testQuestions - 1 {
                picked.append(pools[index].removeFirst())
            }
        }
        // One sentence to build, from anywhere in the unit.
        let builders = unitLessons.flatMap(\.items).filter { if case .builder = $0.kind { return true } else { return false } }
        if let builder = builders.randomElement(using: &rng) {
            picked.append(builder)
        } else if let more = pools.flatMap({ $0 }).first {
            picked.append(more)
        }

        let items = picked.enumerated().map { index, item in
            LessonItem(id: "\(unitId)test-\(index)", beat: .test, kind: item.kind,
                       heartsAtRisk: item.heartsAtRisk, formKeys: item.formKeys)
        }
        return Lesson(
            id: "\(unitId)test",
            title: unit.test.title,
            titleGloss: Gloss(en: "Unit \(unit.number) test", it: "Test dell'unità \(unit.number)", uk: "Тест розділу \(unit.number)", de: "Test zu Einheit \(unit.number)", fr: "Test de l'unité \(unit.number)", pt: "Teste da unidade \(unit.number)", zh: "第 \(unit.number) 单元测试"),
            goal: Gloss(en: "Get 8 out of 10 right to skip the unit.", it: "Rispondi bene a 8 domande su 10 per saltare l'unità.",
                       uk: "Дай 8 правильних відповідей із 10, щоб пропустити розділ.",
                       de: "Beantworte 8 von 10 Fragen richtig, um die Einheit zu überspringen.",
                       fr: "Réponds juste à 8 questions sur 10 pour passer l'unité.",
                       pt: "Acerte 8 de 10 para pular a unidade.",
                       zh: "10 题答对 8 题即可跳过本单元。"),
            mode: .unitTest(unitId: unitId),
            items: items.shuffled(using: &rng)
        )
    }
}

/// All lesson files in the app bundle, loaded once.
final class LessonLibrary {
    static let shared = LessonLibrary()

    private(set) var files: [ContentFile] = []
    private var byId: [String: LessonSpec] = [:]

    init(bundle: Bundle = .main) {
        let urls = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("lessons-") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        for url in urls {
            do {
                let file = try JSONDecoder().decode(ContentFile.self, from: Data(contentsOf: url))
                files.append(file)
                for spec in file.lessons + [file.boss].compactMap({ $0 }) {
                    byId[spec.id] = spec
                }
            } catch {
                assertionFailure("\(url.lastPathComponent) does not match the lesson format: \(error)")
            }
        }
    }

    func spec(_ id: String) -> LessonSpec? { byId[id] }
}

// MARK: - File format

struct ContentFile: Decodable {
    let unit: String
    let lessons: [LessonSpec]
    let boss: LessonSpec?
}

struct GlossSpec: Decodable {
    let en: String
    let it: String
    /// Required by tools/validate_content.py; English stands in if one is ever missing.
    let uk: String?
    let de: String?
    let fr: String?
    let pt: String?
    let zh: String?

    var gloss: Gloss { Gloss(en: en, it: it, uk: uk ?? en, de: de, fr: fr, pt: pt, zh: zh) }
}

struct ExampleSpec: Decodable {
    let es: String
    let en: String
    let it: String
    let uk: String?
    let de: String?
    let fr: String?
    let pt: String?
    let zh: String?

    var spec: GlossSpec { GlossSpec(en: en, it: it, uk: uk, de: de, fr: fr, pt: pt, zh: zh) }
}

struct WordSpec: Decodable {
    let es: String
    let en: String
    let it: String
    let uk: String?
    let de: String?
    let fr: String?
    let pt: String?
    let zh: String?
    let kind: String?

    var spec: GlossSpec { GlossSpec(en: en, it: it, uk: uk, de: de, fr: fr, pt: pt, zh: zh) }
}

struct BrickSpec: Decodable {
    let text: String
    let kind: String
}

struct FormSpec: Decodable {
    let stem: String
    let ending: String
}

struct LessonSpec: Decodable {
    let id: String
    let title: String?
    let titleGloss: GlossSpec?
    let goal: GlossSpec
    let target: ExampleSpec?
    let items: [ItemSpec]

    func lesson(profile: Profile) -> Lesson {
        let node = Curriculum.sharedPath.first { $0.id == id }
        let fill = Placeholders(profile: profile)
        var built: [LessonItem] = []
        for (index, item) in items.enumerated() {
            built += item.items(id: "\(id)-\(index)", fill: fill)
        }
        return Lesson(
            id: id,
            title: title ?? node?.title ?? id,
            titleGloss: titleGloss?.gloss ?? node?.gloss ?? Gloss(en: "", it: "", uk: "", de: "", fr: "", pt: "", zh: ""),
            goal: goal.gloss,
            mode: .lesson,
            items: built,
            target: target.map(fill.example)
        )
    }
}

/// {name}, {city}, {work} (the place after "Trabajo en"), {language} (inglés / italiano / ucraniano)
/// make sentences personal, as in Lesson 2.
struct Placeholders {
    let profile: Profile

    func callAsFunction(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "{name}", with: profile.name)
            .replacingOccurrences(of: "{city}", with: profile.city)
            .replacingOccurrences(of: "{work}", with: profile.workplace.spanish)
            .replacingOccurrences(of: "{language}", with: profile.nativeLanguage.spanishName)
        // {workEn}, {workIt}, {languageUk}…: the workplace and the learner's language, said in each learner language.
        for language in NativeLanguage.allCases {
            let suffix = language.code.prefix(1).uppercased() + language.code.dropFirst()
            result = result.replacingOccurrences(of: "{work\(suffix)}", with: profile.workplace.gloss.text(language))
                .replacingOccurrences(of: "{language\(suffix)}", with: profile.nativeLanguage.spokenName.text(language))
        }
        return result
    }

    func gloss(_ spec: GlossSpec) -> Gloss {
        Gloss(en: self(spec.en), it: self(spec.it), uk: self(spec.uk ?? spec.en),
              de: spec.de.map { self($0) }, fr: spec.fr.map { self($0) },
              pt: spec.pt.map { self($0) }, zh: spec.zh.map { self($0) })
    }

    func example(_ spec: ExampleSpec) -> Example {
        Example(es: self(spec.es), gloss: gloss(spec.spec))
    }
}

struct ItemSpec: Decodable {
    let type: String
    let beat: String?
    // words
    let words: [WordSpec]?
    // explain
    let bricks: [BrickSpec]?
    let result: FormSpec?
    let rule: GlossSpec?
    let examples: [ExampleSpec]?
    let teaches: [WordSpec]?
    // snap
    let person: String?
    let prompt: GlossSpec?
    let stems: [String]?
    let endings: [String]?
    let answer: AnswerSpec?
    // gap and choose
    let before: String?
    let after: String?
    let label: String?
    let accepted: [String]?
    let options: [String]?
    let en: String?
    let it: String?
    let uk: String?
    let de: String?
    let fr: String?
    let pt: String?
    let zh: String?
    let hint: GlossSpec?
    // build and write
    let intention: GlossSpec?
    let tiles: [String]?
    let instruction: GlossSpec?
    let required: [String]?
    let model: ExampleSpec?
    let keys: [String]?

    /// A snap answer is a form; a choice answer is a word.
    enum AnswerSpec: Decodable {
        case form(FormSpec)
        case word(String)

        init(from decoder: Decoder) throws {
            if let word = try? decoder.singleValueContainer().decode(String.self) {
                self = .word(word)
            } else {
                self = .form(try FormSpec(from: decoder))
            }
        }
    }

    
    func items(id: String, fill: Placeholders) -> [LessonItem] {
        let itemBeat = self.beat.flatMap(Beat.init(rawValue:))
        let formKeys = self.keys ?? []
        let hintGloss = self.hint.map(fill.gloss) ?? Gloss(en: "", it: "", uk: "", de: "", fr: "", pt: "", zh: "")
        let gloss = fill.gloss(GlossSpec(en: en ?? "", it: it ?? "", uk: uk, de: de, fr: fr, pt: pt, zh: zh))

        switch type {
        case "words":
            let set = VocabSet(words: (words ?? []).map { $0.vocab(fill) })
            return [
                LessonItem(id: id + "-slides", beat: .words, kind: .slides(set), heartsAtRisk: false, formKeys: []),
                LessonItem(id: id + "-match", beat: .words, kind: .match(set), heartsAtRisk: false, formKeys: []),
            ]
        case "explain":
            let card = FrameCard(
                bricks: (bricks ?? []).map { FrameBrick(text: fill($0.text), kind: Brick(name: $0.kind)) },
                result: result.map { VerbForm(stem: $0.stem, ending: $0.ending) },
                rule: rule.map(fill.gloss) ?? Gloss(en: "", it: "", uk: "", de: "", fr: "", pt: "", zh: ""),
                examples: (examples ?? []).map(fill.example),
                teaches: (teaches ?? []).map { $0.vocab(fill) }
            )
            return [LessonItem(id: id, beat: .frame, kind: .frame(card), heartsAtRisk: false, formKeys: [])]
        case "snap":
            guard case .form(let form) = answer else { return [] }
            let snap = LegoSnap(person: Person(rawValue: person ?? "") ?? .yo,
                                prompt: prompt.map(fill.gloss) ?? gloss,
                                stems: stems ?? [], endings: endings ?? [],
                                answer: VerbForm(stem: form.stem, ending: form.ending))
            return [LessonItem(id: id, beat: itemBeat ?? .forge, kind: .legoSnap(snap), heartsAtRisk: false, formKeys: formKeys)]
        case "gap":
            let gap = GapFill(before: fill(before ?? ""), after: fill(after ?? ""), lemma: label ?? "",
                              accepted: (accepted ?? []).map { fill($0) }, gloss: gloss, hint: hintGloss)
            return [LessonItem(id: id, beat: itemBeat ?? .forge, kind: .gapFill(gap), heartsAtRisk: true, formKeys: formKeys)]
        case "choose":
            guard case .word(let word) = answer else { return [] }
            let choice = Choice(before: fill(before ?? ""), after: fill(after ?? ""),
                                options: (options ?? []).map { fill($0) }, answer: fill(word), gloss: gloss, hint: hintGloss)
            return [LessonItem(id: id, beat: itemBeat ?? .forge, kind: .choice(choice), heartsAtRisk: false, formKeys: formKeys)]
        case "build":
            let answers = (accepted ?? []).map { fill($0) }
            let builder = SentenceBuilder(intention: intention.map(fill.gloss) ?? gloss,
                                          tiles: (tiles ?? []).map { fill($0) }.shuffled(),
                                          accepted: answers,
                                          model: Example(es: answers.first ?? "", gloss: gloss),
                                          hint: hintGloss)
            return [LessonItem(id: id, beat: itemBeat ?? .fire, kind: .builder(builder), heartsAtRisk: true, formKeys: formKeys)]
        case "write":
            let write = FreeWrite(instruction: instruction.map(fill.gloss) ?? gloss,
                                  requiredChunks: (required ?? []).map { fill($0).lowercased() },
                                  model: model.map(fill.example) ?? Example(es: "", gloss: gloss),
                                  accepted: (accepted ?? []).map { fill($0) })
            return [LessonItem(id: id, beat: itemBeat ?? .mix, kind: .freeWrite(write), heartsAtRisk: true, formKeys: formKeys)]
        default:
            assertionFailure("Unknown item type \(type) in \(id)")
            return []
        }
    }
}

private extension WordSpec {
    func vocab(_ fill: Placeholders) -> VocabWord {
        VocabWord(es: fill(es), gloss: fill.gloss(spec), kind: Brick(name: kind ?? "chunk"))
    }
}

extension Brick {
    init(name: String) {
        switch name {
        case "stem": self = .stem
        case "ending": self = .ending
        case "time": self = .time
        case "rail": self = .rail
        default: self = .chunk
        }
    }
}
