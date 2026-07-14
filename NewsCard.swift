import Foundation

struct NewsCard: Identifiable {
    var id: UUID = UUID()
    let category: String
    let title: String
    let summary: String
    let source: String
}
