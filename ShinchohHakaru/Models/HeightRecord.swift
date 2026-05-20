import Foundation

struct HeightRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let heightCm: Double
    let personLabel: String

    init(id: UUID = UUID(), date: Date = Date(), heightCm: Double, personLabel: String = "") {
        self.id = id
        self.date = date
        self.heightCm = heightCm
        self.personLabel = personLabel
    }

    var heightText: String {
        String(format: "%.1f cm", heightCm)
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        return f.string(from: date)
    }
}
