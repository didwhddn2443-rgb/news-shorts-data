import SwiftUI

// MARK: - 색상 토큰
extension Color {
    static let inkBG = Color(red: 0x12/255, green: 0x15/255, blue: 0x1c/255)
    static let inkBG2 = Color(red: 0x1b/255, green: 0x1f/255, blue: 0x29/255)
    static let goldAccent = Color(red: 0xe8/255, green: 0xa3/255, blue: 0x3d/255)
    static let tealAccent = Color(red: 0x3e/255, green: 0x7c/255, blue: 0x74/255)
    static let dimText = Color(red: 0x7d/255, green: 0x84/255, blue: 0x94/255)
}

struct ContentView: View {
    @State private var cards: [NewsCard] = []
    @State private var generatedAt: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.inkBG.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if isLoading {
                    loadingState
                } else if let error = errorMessage {
                    errorState(error)
                } else if cards.isEmpty {
                    emptyState
                } else {
                    cardStack
                }
            }
        }
        .task { await load() }
    }

    // MARK: - 상단 바
    private var topBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘의 브리핑")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.goldAccent)
                if !generatedAt.isEmpty {
                    Text(formattedTime(generatedAt))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.dimText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { await load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(10)
                    .background(Color.goldAccent)
                    .foregroundColor(.inkBG)
                    .clipShape(Circle())
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 카드 스택 (세로 스와이프, iOS 17+)
    private var cardStack: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(cards) { card in
                    NewsCardView(card: card)
                        .containerRelativeFrame(.vertical)
                }
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }

    // MARK: - 상태 화면들
    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().tint(.goldAccent)
            Text("브리핑 불러오는 중")
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("아직 뉴스가 없어요")
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundColor(.white)
            Text("새로고침 버튼을 눌러보세요")
                .font(.system(size: 14))
                .foregroundColor(.dimText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text("불러오기 실패")
                .font(.system(size: 19, weight: .bold, design: .serif))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.dimText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button("다시 시도") { Task { await load() } }
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(Capsule().stroke(Color.white.opacity(0.3)))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 데이터 로드
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await NewsService.fetchNews()
            cards = result.cards
            generatedAt = result.generatedAt
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func formattedTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: iso)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: iso)
        }
        guard let date else { return "" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "ko_KR")
        out.dateFormat = "M월 d일 a h:mm 업데이트"
        return out.string(from: date)
    }
}

// MARK: - 개별 카드
struct NewsCardView: View {
    let card: NewsCard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()

            Text(card.category)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(.tealAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.tealAccent.opacity(0.4))
                )
                .background(Color.tealAccent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(card.title)
                .font(.system(size: 26, weight: .heavy, design: .serif))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.summary)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.83))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.source)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.dimText)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 42)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
