import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var mm: MeasureManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.97, green: 0.97, blue: 0.98).ignoresSafeArea()

                if mm.history.isEmpty {
                    Text(NSLocalizedString("history_empty", comment: ""))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(mm.history.reversed()) { record in
                                HStack(spacing: 12) {
                                    Image(systemName: "ruler.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .rotationEffect(.degrees(90))
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.heightText)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.black)

                                        HStack {
                                            if !record.personLabel.isEmpty {
                                                Text(record.personLabel)
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                            Text(record.dateLabel)
                                                .font(.system(size: 12, design: .rounded))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(NSLocalizedString("history_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("history_done", comment: "")) { dismiss() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
        }
    }
}
