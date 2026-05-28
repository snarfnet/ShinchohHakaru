import SwiftUI
import ARKit
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var mm: MeasureManager
    @State private var showHistory = false
    @State private var personLabel = ""
    // Manual height calculator states (iPad fallback)
    @State private var manualHeightCm: Double = 170
    @State private var manualWeightKg: Double = 65
    @State private var heightText: String = "170"
    @State private var weightText: String = "65"

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
        Group {
            if mm.isARAvailable {
                arHomeView
            } else {
                manualCalcView
            }
        }
    }

    // MARK: - AR Home (iPhone with AR support)
    private var arHomeView: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "ruler.fill")
                .font(.system(size: 70))
                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                .rotationEffect(.degrees(90))

            Text(NSLocalizedString("home_desc", comment: ""))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            mm.startSession()
                        }
                    }
                }
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

    // MARK: - Manual Height Calculator (iPad / non-AR fallback)
    private var manualCalcView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title section
                VStack(spacing: 6) {
                    Image(systemName: "pencil.and.ruler.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                    Text(NSLocalizedString("manual_title", comment: ""))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                    Text(NSLocalizedString("manual_subtitle", comment: ""))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 12)

                // Height input card
                VStack(spacing: 12) {
                    Text(NSLocalizedString("manual_height_label", comment: ""))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        TextField("170", text: $heightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                            .multilineTextAlignment(.center)
                            .frame(width: 120)
                            .onChange(of: heightText) { _, newVal in
                                if let v = Double(newVal), v > 0, v < 300 {
                                    manualHeightCm = v
                                }
                            }
                        Text("cm")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }

                    Slider(value: $manualHeightCm, in: 50...250, step: 0.5)
                        .tint(Color(red: 0.3, green: 0.5, blue: 0.9))
                        .onChange(of: manualHeightCm) { _, newVal in
                            heightText = String(format: "%.1f", newVal)
                        }

                    // Conversion display
                    let totalInches = manualHeightCm / 2.54
                    let feet = Int(totalInches) / 12
                    let inches = totalInches - Double(feet * 12)
                    HStack(spacing: 16) {
                        conversionBadge(
                            value: String(format: "%d'%04.1f\"", feet, inches),
                            label: NSLocalizedString("unit_ft_in", comment: "")
                        )
                        conversionBadge(
                            value: String(format: "%.2f m", manualHeightCm / 100),
                            label: NSLocalizedString("unit_meters", comment: "")
                        )
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 20)

                // Height comparison chart
                heightComparisonChart
                    .padding(.horizontal, 20)

                // Weight & BMI card
                VStack(spacing: 12) {
                    Text(NSLocalizedString("manual_weight_label", comment: ""))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        TextField("65", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                            .multilineTextAlignment(.center)
                            .frame(width: 120)
                            .onChange(of: weightText) { _, newVal in
                                if let v = Double(newVal), v > 0, v < 500 {
                                    manualWeightKg = v
                                }
                            }
                        Text("kg")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }

                    Slider(value: $manualWeightKg, in: 20...200, step: 0.5)
                        .tint(Color(red: 0.3, green: 0.5, blue: 0.9))
                        .onChange(of: manualWeightKg) { _, newVal in
                            weightText = String(format: "%.1f", newVal)
                        }

                    // BMI result
                    let bmi = manualWeightKg / pow(manualHeightCm / 100, 2)
                    let bmiCategory = bmiCategoryFor(bmi)
                    VStack(spacing: 8) {
                        Text("BMI")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(bmiCategory.color)
                        Text(bmiCategory.label)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(bmiCategory.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(bmiCategory.color.opacity(0.12))
                            .cornerRadius(20)

                        // BMI scale bar
                        bmiScaleBar(bmi: bmi)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 20)

                // Weight conversions
                HStack(spacing: 16) {
                    conversionBadge(
                        value: String(format: "%.1f lbs", manualWeightKg * 2.20462),
                        label: NSLocalizedString("unit_pounds", comment: "")
                    )
                    conversionBadge(
                        value: String(format: "%.1f st", manualWeightKg * 0.157473),
                        label: NSLocalizedString("unit_stone", comment: "")
                    )
                }
                .padding(.horizontal, 20)

                Text(NSLocalizedString("disclaimer", comment: ""))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.gray.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Height Comparison Chart
    private var heightComparisonChart: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("chart_title", comment: ""))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            let references: [(String, Double, Color)] = [
                (NSLocalizedString("chart_child", comment: ""), 120, .green),
                (NSLocalizedString("chart_avg_female", comment: ""), 158, .pink),
                (NSLocalizedString("chart_avg_male", comment: ""), 171, Color(red: 0.3, green: 0.5, blue: 0.9)),
                (NSLocalizedString("chart_tall", comment: ""), 190, .purple),
            ]

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(references, id: \.1) { label, refHeight, color in
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", refHeight))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.3))
                            .frame(width: 30, height: CGFloat(refHeight) * 0.6)
                        Text(label)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }

                // User's height
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", manualHeightCm))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.3, green: 0.5, blue: 0.9))
                        .cornerRadius(6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.3, green: 0.5, blue: 0.9))
                        .frame(width: 30, height: CGFloat(manualHeightCm) * 0.6)
                    Text(NSLocalizedString("chart_you", comment: ""))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - BMI Scale Bar
    private func bmiScaleBar(bmi: Double) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .leading) {
                // Gradient bar
                HStack(spacing: 0) {
                    Color.blue.opacity(0.5).frame(width: width * 0.25)
                    Color.green.frame(width: width * 0.25)
                    Color.orange.frame(width: width * 0.25)
                    Color.red.opacity(0.7).frame(width: width * 0.25)
                }
                .frame(height: 8)
                .cornerRadius(4)

                // Indicator
                let clampedBmi = min(max(bmi, 15), 40)
                let position = (clampedBmi - 15) / 25 * width
                Circle()
                    .fill(.white)
                    .frame(width: 14, height: 14)
                    .shadow(radius: 2)
                    .overlay(Circle().fill(bmiCategoryFor(bmi).color).frame(width: 8, height: 8))
                    .offset(x: position - 7)
            }
        }
        .frame(height: 14)
        .padding(.top, 4)
    }

    // MARK: - BMI Category
    private func bmiCategoryFor(_ bmi: Double) -> (label: String, color: Color) {
        switch bmi {
        case ..<18.5:
            return (NSLocalizedString("bmi_underweight", comment: ""), .blue)
        case 18.5..<25:
            return (NSLocalizedString("bmi_normal", comment: ""), .green)
        case 25..<30:
            return (NSLocalizedString("bmi_overweight", comment: ""), .orange)
        default:
            return (NSLocalizedString("bmi_obese", comment: ""), .red)
        }
    }

    // MARK: - Conversion Badge
    private func conversionBadge(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(red: 0.95, green: 0.97, blue: 1.0))
        .cornerRadius(12)
    }

    // MARK: - Measure View
    private var measureView: some View {
        VStack(spacing: 20) {
            // AR Camera feed
            ZStack {
                ARViewContainer(session: mm.arSession)
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
    var session: ARSession?

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.automaticallyUpdatesLighting = true
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        guard let session = session else { return }
        if uiView.session !== session {
            uiView.session = session
        }
    }
}
