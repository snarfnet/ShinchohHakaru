import SwiftUI
import ARKit

struct ContentView: View {
    @EnvironmentObject var mm: MeasureManager
    @State private var showHistory = false
    @State private var personLabel = ""

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(red: 0.95, green: 0.97, blue: 1.0), .white],
                          startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header.padding(.top, 8)

                if mm.isMeasuring {
                    measureView
                } else {
                    homeView
                }

                BannerAdView(adUnitID: AdMobManager.shared.bannerAdUnitID)
                    .frame(height: 50)
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("app_title", comment: ""))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                Text(NSLocalizedString("app_subtitle", comment: ""))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.gray)
            }
            Spacer()
            if !mm.history.isEmpty {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(8)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Home
    private var homeView: some View {
        VStack(spacing: 30) {
            Spacer()

            // Illustration
            Image(systemName: "ruler.fill")
                .font(.system(size: 70))
                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                .rotationEffect(.degrees(90))

            Text(NSLocalizedString("home_desc", comment: ""))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if mm.isARAvailable {
                // AR mode
                Button {
                    mm.startSession()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                        Text(NSLocalizedString("btn_start_ar", comment: ""))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.3, green: 0.5, blue: 0.9))
                    )
                    .shadow(color: Color.blue.opacity(0.2), radius: 10, y: 4)
                }
                .padding(.horizontal, 30)
            } else {
                // No AR support message
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    Text(NSLocalizedString("no_ar_message", comment: ""))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            // Last result
            if let last = mm.history.last {
                VStack(spacing: 4) {
                    Text(NSLocalizedString("last_result", comment: ""))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.gray)
                    Text(last.heightText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                    Text(last.dateLabel)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }

            Spacer()

            Text(NSLocalizedString("disclaimer", comment: ""))
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Measure View
    private var measureView: some View {
        VStack(spacing: 20) {
            // AR Camera view placeholder
            ZStack {
                ARViewContainer()
                    .cornerRadius(20)
                    .padding(.horizontal, 16)

                VStack {
                    // Status
                    HStack(spacing: 8) {
                        Circle()
                            .fill(mm.personDetected ? .green : (mm.floorDetected ? .orange : .red))
                            .frame(width: 10, height: 10)
                        Text(mm.statusMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.top, 24)

                    Spacer()

                    // Height display
                    if let height = mm.currentHeight {
                        VStack(spacing: 4) {
                            Text(String(format: "%.1f", height))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("cm")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }

                    Spacer()
                }
            }

            // Controls
            HStack(spacing: 16) {
                // Stop
                Button {
                    mm.stopSession()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text(NSLocalizedString("btn_cancel", comment: ""))
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }

                // Save
                if mm.currentHeight != nil {
                    Button {
                        mm.saveResult()
                        mm.stopSession()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text(NSLocalizedString("btn_save", comment: ""))
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - AR View
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.automaticallyUpdatesLighting = true
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if uiView.session.configuration == nil {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.bodyDetection) {
                config.frameSemantics.insert(.bodyDetection)
            }
            uiView.session.run(config)
        }
    }
}
