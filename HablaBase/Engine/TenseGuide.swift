import Foundation

/// The tenses of "Repasar tablas", one folder each: the eight the games drill plus the
/// compound ones built from haber + participle (había hablado, habría hablado, hubiera hablado).
enum TableTense: String, CaseIterable, Identifiable {
    case presente, perfecto, indefinido, imperfecto, pluscuamperfecto
    case futuro, condicional, condicionalCompuesto
    case subjuntivo, subjuntivoImperfecto, subjuntivoPluscuamperfecto

    var id: String { rawValue }

    /// The folders are grouped like the path teaches them: now, the past, what is to come, wishes.
    enum Group: CaseIterable, Identifiable {
        case present, past, future, subjunctive

        var id: Self { self }

        var name: Gloss {
            switch self {
            case .present: return Gloss(en: "Present", it: "Presente", uk: "Теперішній час", de: "Gegenwart", fr: "Présent", pt: "Presente", zh: "现在")
            case .past: return Gloss(en: "Past", it: "Passato", uk: "Минулий час", de: "Vergangenheit", fr: "Passé", pt: "Passado", zh: "过去")
            case .future: return Gloss(en: "Future and conditional", it: "Futuro e condizionale", uk: "Майбутній час і умовний спосіб", de: "Zukunft und Konditional", fr: "Futur et conditionnel", pt: "Futuro e condicional", zh: "将来时和条件式")
            case .subjunctive: return Gloss(en: "Subjunctive", it: "Congiuntivo", uk: "Субʼюнктив", de: "Subjunktiv", fr: "Subjonctif", pt: "Subjuntivo", zh: "虚拟式")
            }
        }

        var tenses: [TableTense] { TableTense.allCases.filter { $0.group == self } }
    }

    var group: Group {
        switch self {
        case .presente: return .present
        case .perfecto, .indefinido, .imperfecto, .pluscuamperfecto: return .past
        case .futuro, .condicional, .condicionalCompuesto: return .future
        case .subjuntivo, .subjuntivoImperfecto, .subjuntivoPluscuamperfecto: return .subjunctive
        }
    }

    /// The Spanish name, as a teacher in Spain says it.
    var spanishName: String {
        switch self {
        case .presente: return "Presente"
        case .perfecto: return "Pretérito perfecto"
        case .indefinido: return "Pretérito indefinido"
        case .imperfecto: return "Pretérito imperfecto"
        case .pluscuamperfecto: return "Pretérito pluscuamperfecto"
        case .futuro: return "Futuro"
        case .condicional: return "Condicional"
        case .condicionalCompuesto: return "Condicional compuesto"
        case .subjuntivo: return "Presente de subjuntivo"
        case .subjuntivoImperfecto: return "Imperfecto de subjuntivo"
        case .subjuntivoPluscuamperfecto: return "Pluscuamperfecto de subjuntivo"
        }
    }

    /// The name in the learner's language.
    var name: Gloss {
        switch self {
        case .pluscuamperfecto: return Gloss(en: "past perfect (had spoken)", it: "trapassato prossimo", uk: "давноминулий час", de: "Plusquamperfekt", fr: "plus-que-parfait", pt: "pretérito mais-que-perfeito composto", zh: "过去完成时")
        case .condicionalCompuesto: return Gloss(en: "conditional perfect (would have spoken)", it: "condizionale passato", uk: "умовний спосіб минулого часу", de: "Konditional II", fr: "conditionnel passé", pt: "futuro do pretérito composto", zh: "条件完成式")
        case .subjuntivoPluscuamperfecto: return Gloss(en: "past perfect subjunctive (had spoken)", it: "congiuntivo trapassato", uk: "давноминулий субʼюнктив", de: "Subjunktiv Plusquamperfekt", fr: "subjonctif plus-que-parfait", pt: "mais-que-perfeito do subjuntivo", zh: "虚拟式过去完成时")
        default: return base.name
        }
    }

    /// The simple tense the forms come from. Compound tenses take the participle of the perfecto.
    var base: VerbTense {
        switch self {
        case .presente: return .presente
        case .perfecto, .pluscuamperfecto, .condicionalCompuesto, .subjuntivoPluscuamperfecto: return .perfecto
        case .indefinido: return .indefinido
        case .imperfecto: return .imperfecto
        case .futuro: return .futuro
        case .condicional: return .condicional
        case .subjuntivo: return .subjuntivo
        case .subjuntivoImperfecto: return .subjuntivoImperfecto
        }
    }

    /// haber for the compound tenses other than the perfecto, in Person order.
    var auxiliary: [String]? {
        switch self {
        case .pluscuamperfecto: return ["había", "habías", "había", "habíamos", "habíais", "habían"]
        case .condicionalCompuesto: return ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"]
        case .subjuntivoPluscuamperfecto: return ["hubiera", "hubieras", "hubiera", "hubiéramos", "hubierais", "hubieran"]
        default: return nil
        }
    }

    /// haber + participle: the folder shows haber and the participles instead of endings.
    var isCompound: Bool { base == .perfecto }

    /// The first lesson that explains the tense. Before it, the folder is marked as coming up.
    var gate: String {
        switch self {
        case .presente: return "u1l1"
        case .perfecto: return "u14l1"
        case .indefinido: return "u15l1"
        case .imperfecto: return "u21l1"
        case .pluscuamperfecto: return "u27l3"
        case .futuro: return "u29l1"
        case .condicional: return "u34l1"
        case .condicionalCompuesto: return "u43l2"
        case .subjuntivo: return "u31l1"
        case .subjuntivoImperfecto: return "u37l1"
        case .subjuntivoPluscuamperfecto: return "u43l1"
        }
    }

    /// The unit that teaches the tense, for "Unit 29".
    var unit: CurriculumUnit? {
        Curriculum.sharedPath.first { $0.id == gate }?.unitId.flatMap { Curriculum.shared.unit(id: $0) }
    }

    func isTaught(completed: Set<String>) -> Bool {
        completed.contains(gate)
    }

    /// One verb's six forms in this tense, split into stem and ending.
    func forms(_ verb: VerbEntry) -> [VerbForm]? {
        guard let list = verb.forms[base] else { return nil }
        guard let auxiliary else { return list }
        return list.enumerated().map { index, form in
            Self.swapAuxiliary(form, to: auxiliary[index], reflexive: verb.lemma.hasSuffix("se"))
        }
    }

    /// "he habl|ado" -> "había habl|ado"; "me he despert|ado" -> "me había despert|ado".
    static func swapAuxiliary(_ form: VerbForm, to auxiliary: String, reflexive: Bool) -> VerbForm {
        // "he |ido" keeps its empty participle stem, so ir works too.
        var words = form.stem.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        let index = reflexive ? 1 : 0
        guard words.count > index + 1 else { return form }
        words[index] = auxiliary
        return VerbForm(stem: words.joined(separator: " "), ending: form.ending)
    }

    /// The participle alone: "hecho", "habl|ado".
    static func participle(_ verb: VerbEntry) -> VerbForm? {
        guard let form = verb.form(.perfecto, .yo) else { return nil }
        let last = form.stem.split(separator: " ", omittingEmptySubsequences: false).last.map(String.init) ?? form.stem
        return VerbForm(stem: last, ending: form.ending)
    }

    func isIrregular(_ verb: VerbEntry) -> Bool {
        verb.irregular.contains(base)
    }

    /// The three model verbs, one per family.
    static let models = ["hablar", "comer", "vivir"]

    /// The irregulars worth learning by heart for this tense, not every one: the folder stays calm.
    var keyIrregulars: [String] {
        switch self {
        case .presente: return ["ser", "estar", "ir", "tener", "hacer", "querer", "poder", "decir", "venir"]
        case .indefinido: return ["ser", "ir", "estar", "tener", "hacer", "poder", "decir", "venir"]
        case .imperfecto: return ["ser", "ir", "ver"]
        case .futuro, .condicional: return ["tener", "poder", "hacer", "decir", "salir", "venir", "querer", "saber"]
        case .subjuntivo: return ["ser", "ir", "estar", "dar", "saber", "tener", "hacer", "decir"]
        case .subjuntivoImperfecto: return ["ser", "ir", "estar", "tener", "hacer", "poder", "decir"]
        // Compound tenses: only the participle changes, and it is the same in all four.
        case .perfecto, .pluscuamperfecto, .condicionalCompuesto, .subjuntivoPluscuamperfecto:
            return ["hacer", "decir", "ver", "escribir", "poner", "volver", "abrir", "devolver"]
        }
    }

    /// How the tense is built, in the learner's language.
    var formula: Gloss {
        switch self {
        case .presente:
            return Gloss(en: "Take -ar, -er or -ir off the infinitive and add the ending of the person. -er and -ir share every ending except nosotros and vosotros.",
                         it: "Togli -ar, -er o -ir dall'infinito e aggiungi la desinenza della persona. -er e -ir hanno le stesse desinenze, tranne nosotros e vosotros.",
                         uk: "Відкинь -ar, -er або -ir від інфінітива й додай закінчення особи. У -er та -ir однакові закінчення, крім nosotros і vosotros.",
                         de: "Nimm -ar, -er oder -ir vom Infinitiv weg und häng die Endung der Person an. -er und -ir haben dieselben Endungen, außer bei nosotros und vosotros.",
                         fr: "Enlève -ar, -er ou -ir de l'infinitif et ajoute la terminaison de la personne. -er et -ir ont les mêmes terminaisons, sauf pour nosotros et vosotros.",
                         pt: "Tire -ar, -er ou -ir do infinitivo e acrescente a terminação da pessoa. -er e -ir têm as mesmas terminações, menos em nosotros e vosotros.",
                         zh: "去掉不定式的 -ar、-er 或 -ir，加上对应人称的词尾。-er 和 -ir 的词尾相同，只有 nosotros 和 vosotros 不同。")
        case .perfecto:
            return Gloss(en: "haber in the present (he, has, ha…) + the participle: -ar becomes -ado, -er and -ir become -ido.",
                         it: "haber al presente (he, has, ha…) + il participio: -ar diventa -ado, -er e -ir diventano -ido.",
                         uk: "haber у теперішньому часі (he, has, ha…) + дієприкметник: -ar стає -ado, -er та -ir стають -ido.",
                         de: "haber im Präsens (he, has, ha…) + Partizip: aus -ar wird -ado, aus -er und -ir wird -ido.",
                         fr: "haber au présent (he, has, ha…) + le participe : -ar devient -ado, -er et -ir deviennent -ido.",
                         pt: "haber no presente (he, has, ha…) + o particípio: -ar vira -ado, -er e -ir viram -ido.",
                         zh: "haber 的现在时（he、has、ha…）+ 过去分词：-ar 变成 -ado，-er 和 -ir 变成 -ido。")
        case .indefinido:
            return Gloss(en: "Stem + ending. -er and -ir verbs have exactly the same endings. Watch the accent: hablé, habló.",
                         it: "Radice + desinenza. I verbi in -er e -ir hanno esattamente le stesse desinenze. Attento all'accento: hablé, habló.",
                         uk: "Основа + закінчення. У дієслів на -er та -ir закінчення повністю однакові. Зверни увагу на наголос: hablé, habló.",
                         de: "Stamm + Endung. Verben auf -er und -ir haben genau dieselben Endungen. Achte auf den Akzent: hablé, habló.",
                         fr: "Radical + terminaison. Les verbes en -er et -ir ont exactement les mêmes terminaisons. Attention à l'accent : hablé, habló.",
                         pt: "Radical + terminação. Os verbos em -er e -ir têm exatamente as mesmas terminações. Atenção ao acento: hablé, habló.",
                         zh: "词根 + 词尾。-er 和 -ir 动词的词尾完全相同。注意重音：hablé、habló。")
        case .imperfecto:
            return Gloss(en: "Stem + ending: -aba for -ar, -ía for -er and -ir. Only three verbs are irregular: ser, ir and ver.",
                         it: "Radice + desinenza: -aba per -ar, -ía per -er e -ir. Solo tre verbi sono irregolari: ser, ir e ver.",
                         uk: "Основа + закінчення: -aba для -ar, -ía для -er та -ir. Неправильних дієслів лише три: ser, ir і ver.",
                         de: "Stamm + Endung: -aba bei -ar, -ía bei -er und -ir. Nur drei Verben sind unregelmäßig: ser, ir und ver.",
                         fr: "Radical + terminaison : -aba pour -ar, -ía pour -er et -ir. Seuls trois verbes sont irréguliers : ser, ir et ver.",
                         pt: "Radical + terminação: -aba para -ar, -ía para -er e -ir. Só três verbos são irregulares: ser, ir e ver.",
                         zh: "词根 + 词尾：-ar 用 -aba，-er 和 -ir 用 -ía。只有三个不规则动词：ser、ir 和 ver。")
        case .pluscuamperfecto:
            return Gloss(en: "haber in the imperfect (había, habías…) + the participle. It is the past before another past: ya había salido.",
                         it: "haber all'imperfetto (había, habías…) + il participio. È il passato prima di un altro passato: ya había salido.",
                         uk: "haber у минулому недоконаному (había, habías…) + дієприкметник. Це минуле перед іншим минулим: ya había salido.",
                         de: "haber im Imperfekt (había, habías…) + Partizip. Es ist die Vergangenheit vor einer anderen Vergangenheit: ya había salido.",
                         fr: "haber à l'imparfait (había, habías…) + le participe. C'est le passé avant un autre passé : ya había salido.",
                         pt: "haber no imperfeito (había, habías…) + o particípio. É o passado antes de outro passado: ya había salido.",
                         zh: "haber 的过去未完成时（había、habías…）+ 过去分词。表示另一个过去之前的过去：ya había salido。")
        case .futuro:
            return Gloss(en: "The whole infinitive + the ending, the same for -ar, -er and -ir. Some verbs shorten the stem: tendr-, podr-, har-, dir-.",
                         it: "L'infinito intero + la desinenza, uguale per -ar, -er e -ir. Alcuni verbi accorciano la radice: tendr-, podr-, har-, dir-.",
                         uk: "Увесь інфінітив + закінчення, однакове для -ar, -er та -ir. Деякі дієслова скорочують основу: tendr-, podr-, har-, dir-.",
                         de: "Der ganze Infinitiv + Endung, gleich für -ar, -er und -ir. Manche Verben verkürzen den Stamm: tendr-, podr-, har-, dir-.",
                         fr: "L'infinitif entier + la terminaison, la même pour -ar, -er et -ir. Certains verbes raccourcissent le radical : tendr-, podr-, har-, dir-.",
                         pt: "O infinitivo inteiro + a terminação, igual para -ar, -er e -ir. Alguns verbos encurtam o radical: tendr-, podr-, har-, dir-.",
                         zh: "完整的不定式 + 词尾，-ar、-er、-ir 都一样。有些动词会缩短词根：tendr-、podr-、har-、dir-。")
        case .condicional:
            return Gloss(en: "The whole infinitive + -ía, -ías, -ía…, the same for all three. Irregular verbs use the stem of the future: tendría, podría, haría.",
                         it: "L'infinito intero + -ía, -ías, -ía…, uguale per tutti e tre. I verbi irregolari usano la radice del futuro: tendría, podría, haría.",
                         uk: "Увесь інфінітив + -ía, -ías, -ía…, однаково для всіх трьох. Неправильні дієслова беруть основу майбутнього часу: tendría, podría, haría.",
                         de: "Der ganze Infinitiv + -ía, -ías, -ía…, gleich für alle drei. Unregelmäßige Verben nehmen den Stamm des Futurs: tendría, podría, haría.",
                         fr: "L'infinitif entier + -ía, -ías, -ía…, le même pour les trois. Les verbes irréguliers prennent le radical du futur : tendría, podría, haría.",
                         pt: "O infinitivo inteiro + -ía, -ías, -ía…, igual para os três. Os verbos irregulares usam o radical do futuro: tendría, podría, haría.",
                         zh: "完整的不定式 + -ía、-ías、-ía…，三类动词都一样。不规则动词用将来时的词根：tendría、podría、haría。")
        case .condicionalCompuesto:
            return Gloss(en: "haber in the conditional (habría, habrías…) + the participle: what would have happened. Habría ido.",
                         it: "haber al condizionale (habría, habrías…) + il participio: quello che sarebbe successo. Habría ido.",
                         uk: "haber в умовному способі (habría, habrías…) + дієприкметник: те, що сталося б. Habría ido.",
                         de: "haber im Konditional (habría, habrías…) + Partizip: was passiert wäre. Habría ido.",
                         fr: "haber au conditionnel (habría, habrías…) + le participe : ce qui se serait passé. Habría ido.",
                         pt: "haber no condicional (habría, habrías…) + o particípio: o que teria acontecido. Habría ido.",
                         zh: "haber 的条件式（habría、habrías…）+ 过去分词：表示本来会发生的事。Habría ido。")
        case .subjuntivo:
            return Gloss(en: "Take the yo form of the present, drop the -o and swap the vowel: -ar verbs take -e, -er and -ir verbs take -a. Hablo → hable, como → coma.",
                         it: "Prendi la forma yo del presente, togli la -o e scambia la vocale: i verbi in -ar prendono -e, quelli in -er e -ir prendono -a. Hablo → hable, como → coma.",
                         uk: "Візьми форму yo теперішнього часу, відкинь -o й заміни голосну: дієслова на -ar беруть -e, на -er та -ir беруть -a. Hablo → hable, como → coma.",
                         de: "Nimm die yo-Form des Präsens, streich das -o und tausch den Vokal: Verben auf -ar bekommen -e, Verben auf -er und -ir bekommen -a. Hablo → hable, como → coma.",
                         fr: "Prends la forme yo du présent, enlève le -o et inverse la voyelle : les verbes en -ar prennent -e, ceux en -er et -ir prennent -a. Hablo → hable, como → coma.",
                         pt: "Pegue a forma yo do presente, tire o -o e troque a vogal: verbos em -ar recebem -e, verbos em -er e -ir recebem -a. Hablo → hable, como → coma.",
                         zh: "取现在时 yo 的形式，去掉 -o，再换元音：-ar 动词用 -e，-er 和 -ir 动词用 -a。Hablo → hable，como → coma。")
        case .subjuntivoImperfecto:
            return Gloss(en: "Take the ellos form of the simple past, drop -ron and add -ra, -ras, -ra… Hablaron → hablara, tuvieron → tuviera.",
                         it: "Prendi la forma ellos del passato remoto, togli -ron e aggiungi -ra, -ras, -ra… Hablaron → hablara, tuvieron → tuviera.",
                         uk: "Візьми форму ellos минулого доконаного, відкинь -ron і додай -ra, -ras, -ra… Hablaron → hablara, tuvieron → tuviera.",
                         de: "Nimm die ellos-Form der einfachen Vergangenheit, streich -ron und häng -ra, -ras, -ra… an. Hablaron → hablara, tuvieron → tuviera.",
                         fr: "Prends la forme ellos du passé simple, enlève -ron et ajoute -ra, -ras, -ra… Hablaron → hablara, tuvieron → tuviera.",
                         pt: "Pegue a forma ellos do pretérito perfeito, tire -ron e acrescente -ra, -ras, -ra… Hablaron → hablara, tuvieron → tuviera.",
                         zh: "取简单过去时 ellos 的形式，去掉 -ron，加上 -ra、-ras、-ra…：hablaron → hablara，tuvieron → tuviera。")
        case .subjuntivoPluscuamperfecto:
            return Gloss(en: "haber in the past subjunctive (hubiera, hubieras…) + the participle: si hubiera sabido…",
                         it: "haber al congiuntivo imperfetto (hubiera, hubieras…) + il participio: si hubiera sabido…",
                         uk: "haber у субʼюнктиві минулого часу (hubiera, hubieras…) + дієприкметник: si hubiera sabido…",
                         de: "haber im Subjunktiv Imperfekt (hubiera, hubieras…) + Partizip: si hubiera sabido…",
                         fr: "haber au subjonctif imparfait (hubiera, hubieras…) + le participe : si hubiera sabido…",
                         pt: "haber no imperfeito do subjuntivo (hubiera, hubieras…) + o particípio: si hubiera sabido…",
                         zh: "haber 的虚拟式过去时（hubiera、hubieras…）+ 过去分词：si hubiera sabido…")
        }
    }
}
