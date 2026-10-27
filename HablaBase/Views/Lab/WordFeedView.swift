import SwiftUI

/// "Palabras al azar": swipe up for a new Spanish word, one per screen, with its meaning in the
/// learner's language. The heart (or a double tap) saves it to "Mis favoritas".
struct WordFeedView: View {
    enum Source {
        /// Random words up to the learner's level.
        case discover
        /// Only the words in the favourites folder.
        case favorites
    }

    var source: Source = .discover
    @EnvironmentObject private var store: AppStore
    @State private var words: [FeedWord] = []
    @State private var cards: [Card] = []
    @State private var loaded = false

    /// The same word can come back in a later round, so every card has its own id.
    private struct Card: Identifiable {
        let id = UUID()
        let word: FeedWord
    }

    var body: some View {
        Group {
            if !loaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if cards.isEmpty {
                Text(Self.nothingYet.text(language))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                feed
            }
        }
        .navigationTitle(Text(verbatim: source == .discover ? Self.title : FavoriteWordsView.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if source == .discover {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FavoriteWordsView()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .accessibilityLabel(Text(verbatim: FavoriteWordsView.title))
                }
            }
        }
        .onAppear(perform: load)
    }

    private var language: NativeLanguage { store.language }

    private var feed: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    WordCardView(word: card.word, showsSwipeHint: index == 0)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .onAppear {
                            if index >= cards.count - 3 { extend() }
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollIndicators(.hidden)
    }

    private func load() {
        guard !loaded else { return }
        switch source {
        case .discover:
            if let profile = store.profile {
                let level = Journey.currentLevel(store: store)?.number ?? 1
                words = WordFeed.words(upToLevel: level, profile: profile)
            }
        case .favorites:
            words = store.favoriteWords
        }
        cards = WordFeed.deck(words).map { Card(word: $0) }
        loaded = true
    }

    /// Another round of the same words in a new order, so the feed never ends.
    private func extend() {
        guard !words.isEmpty else { return }
        cards += WordFeed.deck(words, after: cards.last?.word).map { Card(word: $0) }
    }

    static let title = "Palabras al azar"
    static let nothingYet = Gloss(en: "Your words will appear here once your profile is set up.",
                                  it: "Le tue parole appariranno qui quando avrai creato il profilo.",
                                  uk: "Твої слова з'являться тут, щойно ти налаштуєш профіль.",
                                  de: "Deine Wörter erscheinen hier, sobald dein Profil eingerichtet ist.",
                                  fr: "Tes mots apparaîtront ici dès que ton profil sera créé.",
                                  pt: "Suas palavras vão aparecer aqui quando o seu perfil estiver pronto.",
                                  zh: "设置好个人资料后，你的单词会出现在这里。")
}

/// One word, full screen: the Spanish, its meaning, a sentence that uses it and the heart.
struct WordCardView: View {
    let word: FeedWord
    var showsSwipeHint = false
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 16)
            VStack(spacing: 14) {
                HStack(spacing: 6) {
                    Text(verbatim: word.es)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                    SpeakButton(text: word.spoken)
                        .font(.title2)
                }
                Text(verbatim: word.gloss.text(language))
                    .font(.title2)
                    .foregroundStyle(tone.main)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            if let example = word.example {
                exampleView(example)
                    .padding(.top, 28)
            }
            Spacer(minLength: 16)
            footer
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Palette.card))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { save() }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text(verbatim: heartLabel)) { toggle() }
    }

    private var language: NativeLanguage { store.language }
    private var isFavorite: Bool { store.isFavorite(word) }
    private var isLearned: Bool { store.isCompleted(word.lessonId) }

    private var header: some View {
        HStack {
            if let unit = Self.unit(of: word.lessonId) {
                Text(verbatim: language.localized("Unit \(unit.number) · \(unit.title)"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Label(isLearned ? Self.learned.text(language) : Self.upcoming.text(language),
                  systemImage: isLearned ? "checkmark.circle.fill" : "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(tone.main)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(tone.soft))
        }
    }

    private func exampleView(_ example: Example) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: example.es)
                    .font(.body.weight(.medium))
                Spacer(minLength: 0)
                SpeakButton(text: example.es)
                    .font(.subheadline)
            }
            Text(verbatim: example.gloss.text(language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(tone.soft))
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Button(action: toggle) {
                Label(isFavorite ? Self.saved.text(language) : Self.save.text(language),
                      systemImage: isFavorite ? "heart.fill" : "heart")
                    .font(.headline)
                    .foregroundStyle(isFavorite ? Color.white : tone.main)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(isFavorite ? tone.fill : tone.soft))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: heartLabel))
            .sensoryFeedback(.selection, trigger: isFavorite)
            if showsSwipeHint {
                Label(Self.swipeHint.text(language), systemImage: "chevron.up")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private var heartLabel: String {
        isFavorite ? Self.remove.text(language) : Self.saveToFolder.text(language)
    }

    private func toggle() {
        withAnimation(.easeOut(duration: 0.2)) { store.toggleFavorite(word) }
    }

    /// A double tap only saves, like a like: it never takes a word out by accident.
    private func save() {
        guard !isFavorite else { return }
        toggle()
    }

    static func unit(of lessonId: String) -> CurriculumUnit? {
        Curriculum.sharedPath.first { $0.id == lessonId }?.unitId.flatMap { Curriculum.shared.unit(id: $0) }
    }

    static let learned = Gloss(en: "You know it", it: "La conosci", uk: "Ти його знаєш", de: "Kennst du", fr: "Tu le connais", pt: "Você já sabe", zh: "已学过")
    static let upcoming = Gloss(en: "Coming up", it: "In arrivo", uk: "Попереду", de: "Kommt bald", fr: "Bientôt", pt: "Em breve", zh: "即将学到")
    static let save = Gloss(en: "Save", it: "Salva", uk: "Зберегти", de: "Speichern", fr: "Enregistrer", pt: "Salvar", zh: "收藏")
    static let saved = Gloss(en: "Saved", it: "Salvata", uk: "Збережено", de: "Gespeichert", fr: "Enregistré", pt: "Salva", zh: "已收藏")
    static let saveToFolder = Gloss(en: "Save to Mis favoritas", it: "Salva in Mis favoritas", uk: "Зберегти в Mis favoritas", de: "In Mis favoritas speichern", fr: "Enregistrer dans Mis favoritas", pt: "Salvar em Mis favoritas", zh: "收藏到 Mis favoritas")
    static let remove = Gloss(en: "Remove from Mis favoritas", it: "Togli da Mis favoritas", uk: "Прибрати з Mis favoritas", de: "Aus Mis favoritas entfernen", fr: "Retirer de Mis favoritas", pt: "Tirar de Mis favoritas", zh: "从 Mis favoritas 移除")
    static let swipeHint = Gloss(en: "Swipe up for another word", it: "Scorri in su per un'altra parola", uk: "Гортай угору, щоб побачити інше слово", de: "Nach oben wischen für ein neues Wort", fr: "Glisse vers le haut pour un autre mot", pt: "Deslize para cima para ver outra palavra", zh: "向上滑动，看下一个词")
}

/// "Mis favoritas": the folder of saved words, newest first. Open one to see its card, swipe it
/// away to remove it, or go through them all in the feed.
struct FavoriteWordsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.favoriteWords.isEmpty {
                ContentUnavailableView {
                    Label { Text(verbatim: Self.emptyTitle.text(language)) } icon: { Image(systemName: "heart") }
                } description: {
                    Text(verbatim: Self.emptyDetail.text(language))
                }
            } else {
                List {
                    Section {
                        NavigationLink {
                            WordFeedView(source: .favorites)
                        } label: {
                            Label(Self.review.text(language), systemImage: "rectangle.stack")
                        }
                    }
                    Section {
                        ForEach(store.favoriteWords) { word in
                            NavigationLink {
                                WordCardView(word: word)
                                    .padding(16)
                                    .navigationTitle(Text(verbatim: word.es))
                                    .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                row(word)
                            }
                        }
                        .onDelete { store.removeFavorites(at: $0) }
                    } header: {
                        Text(verbatim: Self.count(store.favoriteWords.count, language: language))
                    }
                }
            }
        }
        .navigationTitle(Text(verbatim: Self.title))
        .toolbar {
            if !store.favoriteWords.isEmpty {
                EditButton()
            }
        }
    }

    private var language: NativeLanguage { store.language }

    private func row(_ word: FeedWord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: word.es)
                    .font(.headline)
                Text(verbatim: word.gloss.text(language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            SpeakButton(text: word.spoken)
                .buttonStyle(.borderless)
        }
    }

    static let title = "Mis favoritas"

    /// "Saved words: 3", written without plurals so it reads right in every language.
    static func count(_ count: Int, language: NativeLanguage) -> String {
        Gloss(en: "Saved words: \(count)", it: "Parole salvate: \(count)", uk: "Збережені слова: \(count)",
              de: "Gespeicherte Wörter: \(count)", fr: "Mots enregistrés : \(count)", pt: "Palavras salvas: \(count)",
              zh: "已收藏的词：\(count)").text(language)
    }

    static let detail = Gloss(en: "The words you saved with the heart.", it: "Le parole che hai salvato con il cuore.",
                              uk: "Слова, які ти зберіг сердечком.", de: "Die Wörter, die du mit dem Herz gespeichert hast.",
                              fr: "Les mots que tu as enregistrés avec le cœur.", pt: "As palavras que você salvou com o coração.",
                              zh: "你用爱心收藏的词。")
    static let emptyTitle = Gloss(en: "No saved words yet", it: "Ancora nessuna parola salvata", uk: "Ще немає збережених слів",
                                  de: "Noch keine gespeicherten Wörter", fr: "Aucun mot enregistré pour l'instant",
                                  pt: "Nenhuma palavra salva ainda", zh: "还没有收藏的词")
    static let emptyDetail = Gloss(en: "In Palabras al azar, tap the heart or double-tap a word to keep it here.",
                                   it: "In Palabras al azar, tocca il cuore o tocca due volte una parola per tenerla qui.",
                                   uk: "У Palabras al azar натисни сердечко або двічі торкнися слова, щоб зберегти його тут.",
                                   de: "Tippe in Palabras al azar auf das Herz oder tippe doppelt auf ein Wort, um es hier zu behalten.",
                                   fr: "Dans Palabras al azar, touche le cœur ou touche deux fois un mot pour le garder ici.",
                                   pt: "Em Palabras al azar, toque no coração ou toque duas vezes numa palavra para guardá-la aqui.",
                                   zh: "在 Palabras al azar 里点爱心或双击单词，就能把它收藏到这里。")
    static let review = Gloss(en: "Go through them one by one", it: "Ripassale una per una", uk: "Переглянути по одному",
                              de: "Eins nach dem anderen durchgehen", fr: "Les revoir une par une", pt: "Revisar uma por uma",
                              zh: "逐个复习")
}
