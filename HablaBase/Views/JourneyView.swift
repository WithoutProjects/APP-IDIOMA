import SwiftUI

/// The home path: every unit as a winding trail of round steps, with a reward chest halfway,
/// the boss and the unit trophy at the end, and a "Jump here?" stop to skip ahead with the test.
struct JourneyView<Top: View>: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var selected: String?
    @State private var didCenter = false
    @State private var showChestReward = false

    private let start: (Lesson) -> Void
    private let top: Top
    private let curriculum = Curriculum.shared

    init(start: @escaping (Lesson) -> Void, @ViewBuilder top: () -> Top) {
        self.start = start
        self.top = top()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section { top }
                    ForEach(curriculum.levels) { level in
                        Section {
                            LevelHeader(level: level, language: store.language)
                        }
                        ForEach(level.units) { unit in
                            Section {
                                trail(for: unit)
                            } header: {
                                UnitBanner(unit: unit, level: level,
                                           done: Journey.nodes(in: unit).filter { store.isCompleted($0.id) }.count,
                                           total: Journey.nodes(in: unit).count)
                            }
                        }
                        Section {
                            checkpoint(level)
                        }
                    }
                }
                .padding(.bottom, 80)
            }
            .overlay(alignment: .bottomTrailing) {
                if let id = store.nextNode?.id {
                    Button {
                        center(on: id, proxy: proxy, animated: true)
                    } label: {
                        Image(systemName: "scope")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(FunColor.sky.main)
                            .frame(width: 56, height: 56)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color(.systemGray4), lineWidth: 2))
                    }
                    .buttonStyle(SquishButtonStyle())
                    .padding(20)
                    .accessibilityLabel(Journey.goToLesson.text(store.language))
                }
            }
            .overlay(alignment: .top) {
                if showChestReward {
                    chestReward
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onAppear {
                guard !didCenter, let id = store.nextNode?.id else { return }
                didCenter = true
                DispatchQueue.main.async { center(on: id, proxy: proxy, animated: false) }
            }
        }
    }

    // MARK: Unit trail

    private func trail(for unit: CurriculumUnit) -> some View {
        let color = FunColor.forUnit(unit.number)
        let stops = Journey.stops(in: unit)
        let mirrored = unit.number.isMultiple(of: 2)
        return VStack(spacing: 22) {
            if showsJump(unit) {
                jumpStop(unit)
            }
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                let x = Journey.offset(index, mirrored: mirrored)
                stopView(stop, color: color)
                    .offset(x: x)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: x > 0 ? .leading : .trailing) {
                        if index == 2 {
                            Mascot(shape: .forUnit(unit.number), color: color.main, mood: mascotMood(unit), size: 84)
                                .padding(.horizontal, 28)
                        }
                    }
                    .id(stop.id)
            }
        }
        .padding(.vertical, 32)
        .id(unit.id)
    }

    @ViewBuilder
    private func stopView(_ stop: TrailStop, color: FunColor) -> some View {
        switch stop {
        case .step(let node):
            stepView(node, color: color)
        case .chest(let id, let after):
            chestView(id: id, after: after)
        }
    }

    private func stepView(_ node: PathNode, color: FunColor) -> some View {
        let stepStatus = status(of: node)
        return Button {
            selected = node.id
        } label: {
            StepDisc(icon: icon(for: node, status: stepStatus),
                     color: stepStatus == .locked ? .locked : color,
                     size: node.kind == .checkpoint ? 88 : 72,
                     isCurrent: stepStatus == .current)
        }
        .buttonStyle(SquishButtonStyle())
        .popover(isPresented: popover(node.id)) {
            stepCard(node, status: stepStatus, color: color)
        }
        .overlay(alignment: .top) {
            if stepStatus == .current {
                SpeechBubble(text: store.language.localized("Start"), color: color, bobbing: !reduceMotion)
                    .fixedSize()
                    .offset(y: -56)
                    .allowsHitTesting(false)
            }
        }
        .padding(.top, stepStatus == .current ? 40 : 0)
        .accessibilityLabel(node.title)
        .accessibilityValue(statusText(stepStatus))
    }

    private func stepCard(_ node: PathNode, status: StepStatus, color: FunColor) -> some View {
        let language = store.language
        let focus = node.unitId.flatMap { curriculum.unit(id: $0) }?.lessons.first { $0.id == node.id }?.focus
        return VStack(alignment: .leading, spacing: 10) {
            Text(node.title)
                .font(.system(.title3, design: .rounded).weight(.heavy))
            Text(node.gloss.text(language))
                .foregroundStyle(.secondary)
            if let focus {
                Text(focus)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(color.main)
            }
            if status == .locked {
                Label(Journey.lockedHint.text(language), systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if Journey.isBuilt(node, store: store) {
                Button(actionTitle(node, status: status)) { launch(node.id) }
                    .buttonStyle(PrimaryButtonStyle(color: color.main, textColor: color.ink))
                    .padding(.top, 4)
            } else {
                Label(language.localized("You're up to date"), systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.success)
            }
        }
        .padding(20)
        .frame(width: 300, alignment: .leading)
        .presentationCompactAdaptation(.popover)
    }

    private func actionTitle(_ node: PathNode, status: StepStatus) -> String {
        let language = store.language
        switch status {
        case .done: return language.localized("Practice")
        case .open: return language.localized("Already know this? Take the test (10 questions)")
        case .current, .locked: return language.localized("Start")
        }
    }

    // MARK: Chest

    private func chestView(id: String, after: [String]) -> some View {
        let ready = after.allSatisfy { store.isCompleted($0) }
        let status: ChestView.Status = store.isChestOpen(id) ? .open : (ready ? .ready : .locked)
        return Button {
            switch status {
            case .ready: openChest(id)
            case .locked: selected = id
            case .open: break
            }
        } label: {
            ChestView(status: status)
        }
        .buttonStyle(SquishButtonStyle())
        .popover(isPresented: popover(id)) {
            Label(Journey.chestLocked.text(store.language), systemImage: "lock.fill")
                .font(.subheadline)
                .padding(20)
                .frame(width: 280, alignment: .leading)
                .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel(Journey.chest.text(store.language))
        .accessibilityValue(status == .open ? store.language.localized("Done")
                            : status == .ready ? "+\(AppStore.chestXP) XP" : store.language.localized("Locked"))
    }

    private func openChest(_ id: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            store.openChest(id)
            showChestReward = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeOut) { showChestReward = false }
        }
    }

    private var chestReward: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .accessibilityHidden(true)
            Text(Journey.chestOpened.text(store.language))
            Text(verbatim: "+\(AppStore.chestXP) XP")
        }
        .font(.system(.headline, design: .rounded).weight(.heavy))
        .foregroundStyle(FunColor.sunshine.ink)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Capsule().fill(FunColor.sunshine.main))
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: Jump ahead

    /// A unit further on, not started yet, whose test exists: passing it skips everything before.
    private func showsJump(_ unit: CurriculumUnit) -> Bool {
        guard let first = Journey.nodes(in: unit).first,
              let current = store.nextNode,
              let unitStart = Journey.position[first.id],
              let currentPosition = Journey.position[current.id],
              unitStart > currentPosition,
              !store.isCompleted(unit.test.id) else { return false }
        return Journey.isBuilt(unitTest: unit, store: store)
    }

    private func jumpStop(_ unit: CurriculumUnit) -> some View {
        let id = "\(unit.id)-jump"
        let language = store.language
        return Button {
            selected = id
        } label: {
            StepDisc(icon: "forward.fill", color: .bubblegum, size: 72)
        }
        .buttonStyle(SquishButtonStyle())
        .popover(isPresented: popover(id)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(Journey.jumpHere.text(language))
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                Text(Journey.jumpDetail.text(language))
                    .foregroundStyle(.secondary)
                Button(Journey.takeTest.text(language)) { launch(unit.test.id) }
                    .buttonStyle(PrimaryButtonStyle(color: FunColor.bubblegum.main))
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(width: 300, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
        .overlay(alignment: .top) {
            SpeechBubble(text: Journey.jumpHere.text(language), color: .bubblegum)
                .fixedSize()
                .offset(y: -56)
                .allowsHitTesting(false)
        }
        .padding(.top, 40)
        .accessibilityLabel(Journey.jumpHere.text(language))
        .accessibilityHint(Journey.jumpDetail.text(language))
        .id(id)
    }

    // MARK: Level checkpoint

    private func checkpoint(_ level: CurriculumLevel) -> some View {
        let node = PathNode(id: level.checkpoint.id, title: level.checkpoint.title, gloss: level.checkpoint.gloss,
                            kind: .checkpoint, levelId: level.id, unitId: nil)
        let done = store.isCompleted(node.id)
        return HStack(spacing: 22) {
            Mascot(shape: .flower, color: FunColor.bubblegum.main, mood: done ? .excited : .sleepy, size: 62)
            stepView(node, color: .sunshine)
            Mascot(shape: .cloud, color: FunColor.teal.main, mood: done ? .excited : .sleepy, size: 62)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .id(node.id)
    }

    // MARK: Helpers

    /// Steps far down the path are not built yet, so first reach their unit, then the step.
    private func center(on id: String, proxy: ScrollViewProxy, animated: Bool) {
        let unitId = Curriculum.sharedPath.first { $0.id == id }?.unitId ?? id
        proxy.scrollTo(unitId, anchor: .top)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if animated {
                withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) }
            } else {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private func launch(_ id: String) {
        selected = nil
        guard let lesson = store.playableLesson(id) else { return }
        // Let the bubble close before the lesson slides up.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { start(lesson) }
    }

    private func popover(_ id: String) -> Binding<Bool> {
        Binding(
            get: { selected == id },
            set: { isShown in
                if !isShown, selected == id { selected = nil }
            }
        )
    }

    private func status(of node: PathNode) -> StepStatus {
        if store.isCompleted(node.id) { return .done }
        if store.nextNode?.id == node.id { return .current }
        // The unit test can be taken at any time.
        if node.kind == .test, Journey.isBuilt(node, store: store) { return .open }
        return .locked
    }

    private func statusText(_ status: StepStatus) -> String {
        switch status {
        case .done: return store.language.localized("Done")
        case .current: return store.language.localized("Next")
        case .open: return store.language.localized("Unit test")
        case .locked: return store.language.localized("Locked")
        }
    }

    private func icon(for node: PathNode, status: StepStatus) -> String {
        if status == .done && node.kind == .lesson { return "checkmark" }
        switch node.kind {
        case .lesson: return "star.fill"
        case .boss: return "flag.fill"
        case .test: return "trophy.fill"
        case .checkpoint: return "crown.fill"
        }
    }

    private func mascotMood(_ unit: CurriculumUnit) -> MascotMood {
        let nodes = Journey.nodes(in: unit)
        if nodes.allSatisfy({ store.isCompleted($0.id) }) { return .happy }
        if nodes.contains(where: { $0.id == store.nextNode?.id }) { return .excited }
        return .sleepy
    }
}

enum StepStatus {
    case done, current, open, locked
}

/// One stop on a unit's trail.
enum TrailStop: Identifiable {
    case step(PathNode)
    /// A reward chest that opens once every lesson before it is done.
    case chest(id: String, after: [String])

    var id: String {
        switch self {
        case .step(let node): return node.id
        case .chest(let id, _): return id
        }
    }
}

/// The path's fixed layout and texts.
@MainActor
enum Journey {
    static let nodesByUnit: [String: [PathNode]] = Dictionary(
        grouping: Curriculum.sharedPath.filter { $0.unitId != nil },
        by: { $0.unitId ?? "" }
    )

    /// Where each step sits on the whole path.
    static let position: [String: Int] = Dictionary(
        uniqueKeysWithValues: Curriculum.sharedPath.enumerated().map { ($0.element.id, $0.offset) }
    )

    static func nodes(in unit: CurriculumUnit) -> [PathNode] {
        nodesByUnit[unit.id] ?? []
    }

    /// The unit's steps with a chest after the first half of its lessons.
    static func stops(in unit: CurriculumUnit) -> [TrailStop] {
        let nodes = nodes(in: unit)
        var stops = nodes.map { TrailStop.step($0) }
        let lessons = nodes.filter { $0.kind == .lesson }
        if lessons.count >= 2 {
            let half = lessons.count / 2
            stops.insert(.chest(id: "\(unit.id)-chest", after: lessons.prefix(half).map(\.id)), at: half)
        }
        return stops
    }

    /// The zigzag: steps swing right, back through the middle, then left.
    private static let pattern: [CGFloat] = [0, 48, 72, 48, 0, -48, -72, -48]

    static func offset(_ index: Int, mirrored: Bool) -> CGFloat {
        let x = pattern[index % pattern.count]
        return mirrored ? -x : x
    }

    // Building a lesson to find out whether it exists is costly, so the answer is kept.
    private static var built: [String: Bool] = [:]

    static func isBuilt(_ node: PathNode, store: AppStore) -> Bool {
        if let known = built[node.id] { return known }
        guard store.profile != nil else { return false }
        let exists = store.playableLesson(node.id) != nil
        built[node.id] = exists
        return exists
    }

    static func isBuilt(unitTest unit: CurriculumUnit, store: AppStore) -> Bool {
        guard let node = nodes(in: unit).first(where: { $0.id == unit.test.id }) else { return false }
        return isBuilt(node, store: store)
    }

    static let goToLesson = Gloss(en: "Go to my lesson", it: "Vai alla mia lezione", uk: "До мого уроку", de: "Zu meiner Lektion", fr: "Aller à ma leçon", pt: "Ir para minha lição", zh: "前往我的课程")
    static let lockedHint = Gloss(en: "Finish the steps before this one to unlock it.", it: "Completa i passi precedenti per sbloccarlo.", uk: "Заверши попередні кроки, щоб відкрити його.", de: "Schließe die Schritte davor ab, um ihn freizuschalten.", fr: "Termine les étapes précédentes pour le débloquer.", pt: "Conclua as etapas anteriores para desbloquear.", zh: "完成前面的步骤即可解锁。")
    static let chest = Gloss(en: "Chest", it: "Forziere", uk: "Скриня", de: "Truhe", fr: "Coffre", pt: "Baú", zh: "宝箱")
    static let chestLocked = Gloss(en: "Finish the lessons before it to open this chest.", it: "Completa le lezioni precedenti per aprire questo forziere.", uk: "Заверши попередні уроки, щоб відкрити цю скриню.", de: "Schließe die Lektionen davor ab, um diese Truhe zu öffnen.", fr: "Termine les leçons précédentes pour ouvrir ce coffre.", pt: "Conclua as lições anteriores para abrir este baú.", zh: "完成前面的课程即可打开这个宝箱。")
    static let chestOpened = Gloss(en: "Chest opened!", it: "Forziere aperto!", uk: "Скриню відкрито!", de: "Truhe geöffnet!", fr: "Coffre ouvert !", pt: "Baú aberto!", zh: "宝箱已打开！")
    static let jumpHere = Gloss(en: "Jump here?", it: "Saltare qui?", uk: "Перейти сюди?", de: "Hierher springen?", fr: "Sauter ici ?", pt: "Pular para cá?", zh: "跳到这里？")
    static let jumpDetail = Gloss(en: "Pass the 10-question test of this unit to skip everything before it.", it: "Supera il test di 10 domande di questa unità per saltare tutto ciò che viene prima.", uk: "Склади тест із 10 запитань цього розділу, щоб пропустити все, що перед ним.", de: "Bestehe den Test mit 10 Fragen dieser Einheit, um alles davor zu überspringen.", fr: "Réussis le test de 10 questions de cette unité pour sauter tout ce qui la précède.", pt: "Passe no teste de 10 perguntas desta unidade para pular tudo o que vem antes.", zh: "通过本单元的10道题测试，即可跳过之前的所有内容。")
    static let takeTest = Gloss(en: "Take the test", it: "Fai il test", uk: "Пройти тест", de: "Test machen", fr: "Passer le test", pt: "Fazer o teste", zh: "参加测试")
}

/// A round, raised step on the path.
struct StepDisc: View {
    let icon: String
    let color: FunColor
    var size: CGFloat = 72
    var isCurrent = false

    var body: some View {
        ZStack {
            Circle().fill(color.deep)
                .offset(y: size * 0.08)
            Circle().fill(color.main)
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center))
                .padding(size * 0.06)
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .heavy))
                .foregroundStyle(color.ink)
        }
        .frame(width: size, height: size)
        .padding(.bottom, size * 0.08)
        .background {
            if isCurrent {
                Circle()
                    .stroke(color.main.opacity(0.3), lineWidth: 7)
                    .frame(width: size + 20, height: size + 20)
                    .offset(y: -size * 0.04)
            }
        }
    }
}

/// "START" or "JUMP HERE?" floating over a step.
struct SpeechBubble: View {
    let text: String
    let color: FunColor
    var bobbing = false

    @State var up = false

    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.system(.subheadline, design: .rounded).weight(.heavy))
            .foregroundStyle(color.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.main))
            .overlay(alignment: .bottom) {
                BubbleTail()
                    .fill(color.main)
                    .frame(width: 18, height: 9)
                    .offset(y: 8)
            }
            .offset(y: up ? -5 : 0)
            .onAppear {
                guard bobbing else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { up = true }
            }
            .accessibilityHidden(true)
    }
}

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The coloured banner that stays on top while the learner scrolls through a unit.
struct UnitBanner: View {
    let unit: CurriculumUnit
    let level: CurriculumLevel
    let done: Int
    let total: Int

    var body: some View {
        let color = FunColor.forUnit(unit.number)
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(level.number) · \(level.name) · \(level.cefr)")
                    .textCase(.uppercase)
                    .font(.caption.weight(.heavy))
                    .opacity(0.8)
                Text("Unit \(unit.number) · \(unit.title)")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 8)
            ZStack {
                Circle().stroke(color.ink.opacity(0.25), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: total == 0 ? 0 : CGFloat(done) / CGFloat(total))
                    .stroke(color.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(done)/\(total)")
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
            }
            .frame(width: 46, height: 46)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(done) of \(total) steps done"))
        }
        .foregroundStyle(color.ink)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(shape.fill(color.main))
        .background(shape.fill(color.deep).offset(y: 5))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 13)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// "— Level 2 · Motor · A2 —" and what the learner will be able to do.
struct LevelHeader: View {
    let level: CurriculumLevel
    let language: NativeLanguage

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                line
                Text("Level \(level.number) · \(level.name) · \(level.cefr)")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                line
            }
            Text(level.canDo.text(language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var line: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(maxWidth: 36, maxHeight: 3)
    }
}
