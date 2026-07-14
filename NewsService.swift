import Foundation

enum NewsServiceError: LocalizedError {
    case badResponse(Int)
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .badResponse(let code): return "서버 오류 (코드 \(code))"
        case .decodeFailed: return "뉴스 데이터를 해석하지 못했어요"
        }
    }
}

// docs/news.json 구조
private struct NewsPayload: Decodable {
    let generated_at: String
    let count: Int
    let cards: [NewsCardDTO]
}

private struct NewsCardDTO: Decodable {
    let category: String
    let title: String
    let summary: String
    let source: String
    let link: String?
    let published: String?
}

enum NewsService {

    static func fetchNews() async throws -> (cards: [NewsCard], generatedAt: String) {
        guard let url = URL(string: Config.newsJSONURL) else {
            throw NewsServiceError.decodeFailed
        }
        // 캐시 무시하고 항상 최신 파일 가져오기
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NewsServiceError.badResponse(code)
        }

        let payload: NewsPayload
        do {
            payload = try JSONDecoder().decode(NewsPayload.self, from: data)
        } catch {
            throw NewsServiceError.decodeFailed
        }

        let cards = payload.cards.map {
            NewsCard(category: $0.category,
                     title: $0.title,
                     summary: $0.summary,
                     source: $0.source)
        }
        return (cards, payload.generated_at)
    }
}
