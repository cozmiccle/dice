import SwiftUI
import AppKit
import Combine

// MARK: - App Entry Point

@main
struct DiceMenuBarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            DicePopoverView()
                .environmentObject(appState)
        } label: {
            Image(systemName: "dice.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Die Type

enum DieType: String, CaseIterable, Identifiable {
    case coin = "Coin"
    case d4   = "d4"
    case d6   = "d6"
    case d8   = "d8"
    case d10  = "d10"
    case d12  = "d12"
    case d20  = "d20"
    case d40  = "d40"
    case d50  = "d50"
    case d100 = "d100"

    var id: String { rawValue }

    static let symbolDice1: [DieType] = [.coin, .d4, .d6]
    static let symbolDice2: [DieType] = [.d8, .d10, .d12]
    static let numericDice: [DieType] = [.d20, .d40, .d50, .d100]

    var sides: Int {
        switch self {
        case .coin: return 2
        case .d4:   return 4
        case .d6:   return 6
        case .d8:   return 8
        case .d10:  return 10
        case .d12:  return 12
        case .d20:  return 20
        case .d40:  return 40
        case .d50:  return 50
        case .d100: return 100
        }
    }

    var kanji: String {
        switch self {
        case .coin: return "両"
        case .d4:   return "四"
        case .d6:   return "六"
        case .d8:   return "八"
        case .d10:  return "十"
        case .d12:  return "十二"
        default:    return ""
        }
    }
    var symbolName: String? {
        switch self {
        case .coin: return "circle.fill"
        case .d4:   return "triangle.fill"
        case .d6:   return "square.fill"
        case .d8:   return "diamond.fill"
        case .d10:  return "pentagon.fill"
        case .d12:  return "hexagon.fill"
        default:    return nil
        }
    }

// MARK: - Processing Logic
    func roll(showKanji: Bool) -> RollResult {
        let n = Int.random(in: 1...sides)
        let display: String

        if self == .coin {
            display = showKanji
                ? (n == 1 ? "表" : "裏")
                : (n == 1 ? "Heads" : "Tails")
        } else {
            display = "\(n)"
        }

        return RollResult(display: display, numeric: n, die: self)
    }
}

// MARK: - Roll Result

struct RollResult {
    let display: String
    let numeric: Int
    let die: DieType
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var selectedDie: DieType = .d6
    @Published var result: RollResult? = nil
    @Published var isRolling = false
    @Published var instantRoll = false
    @Published var showKanji = true {
        didSet {
            if let current = result {
                let n = current.numeric
                let display = current.die == .coin
                    ? (showKanji ? (n == 1 ? "表" : "裏") : (n == 1 ? "Heads" : "Tails"))
                    : "\(n)"
                result = RollResult(display: display, numeric: n, die: current.die)
            }
        }
    }

    func roll() {
        guard !isRolling else { return }
        isRolling = true
        result = nil

        if selectedDie == .coin {
            let delay = instantRoll ? 0.0 : 0.6
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.result = self.selectedDie.roll(showKanji: self.showKanji)
                self.isRolling = false
            }
        } else {
            let steps = instantRoll ? 0 : 12
            let interval = 0.045
            for step in 0..<steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                    self.result = self.selectedDie.roll(showKanji: self.showKanji)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(steps)) {
                self.result = self.selectedDie.roll(showKanji: self.showKanji)
                self.isRolling = false
            }
        }
    }
}

// MARK: - Shared Button Style

/// Reusable glass tile background used by all selector buttons.
struct GlassTile: View {
    let isSelected: Bool
    var secondary: Bool = false
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isSelected ? AnyShapeStyle(.tint) : secondary ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.thickMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(isSelected ? 0.55 : 0.45), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? .accentColor.opacity(0.4) : .black.opacity(0.12),
                radius: isSelected ? 8 : 3,
                y: isSelected ? 4 : 1.5
            )
            .frame(width: width, height: height)
    }
}

// MARK: - Flashing Ellipsis

struct FlashingEllipsis: View {
    @State private var opacity1 = 1.0
    @State private var opacity2 = 1.0
    @State private var opacity3 = 1.0

    var body: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 7, height: 7).opacity(opacity1)
            Circle().frame(width: 7, height: 7).opacity(opacity2)
            Circle().frame(width: 7, height: 7).opacity(opacity3)
        }
        .foregroundStyle(.tertiary)
        .onAppear {
            let duration = 0.35
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(0.00)) { opacity1 = 0.2 }
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(0.15)) { opacity2 = 0.2 }
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(0.30)) { opacity3 = 0.2 }
        }
    }
}

// MARK: - Popover

struct DicePopoverView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Dice Roller")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    ZStack {
                        GlassTile(isSelected: false, secondary: true, width: 100, height: 30, cornerRadius: 15)
                        HStack {
                            Text("漢字")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Toggle("", isOn: $appState.showKanji)
                                .toggleStyle(.switch)
                                    .controlSize(.small)
                        }
                    }
                    
                }
                .padding(.horizontal, 15)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().opacity(0.2)

                sectionLabel("Simple Dice")
                    .padding(.top, 14)
                    .padding(.bottom, 2)

                SymbolDiePicker1()
                    .padding(.top, 2)
                    .padding(.bottom, 0)
                    .padding(.horizontal, 12)
                
                SymbolDiePicker2()
                    .padding(.top, 0)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                
                sectionLabel("Large Dice")
                    .padding(.bottom, 4)

                NumericDiePicker()
                    .padding(.bottom, 14)
                    .padding(.horizontal, 12)

                Divider().opacity(0.3)

                ResultView()
                    .padding(.vertical, 4)
                
                QuickRollToggle()
                    .padding(.bottom, 16)
                
                RollButton()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                QuitButton()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Symbol Die Picker

struct SymbolDiePicker1: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DieType.symbolDice1) { die in
                SymbolDieButton(die: die)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
}
struct SymbolDiePicker2: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DieType.symbolDice2) { die in
                SymbolDieButton(die: die)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
}
struct SymbolDieButton: View {
    @EnvironmentObject var appState: AppState
    let die: DieType
    @State private var isHovered = false

    var isSelected: Bool { appState.selectedDie == die }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                appState.selectedDie = die
                appState.result = nil
            }
        } label: {
            ZStack {
                GlassTile(isSelected: isSelected, width: 55, height: 40, cornerRadius: 10)
                if appState.showKanji {
                    Text(die.kanji)
                            .font(.custom("Zen Maru Gothic", size: 20))
                            .foregroundStyle(isSelected ? .white : .primary)
                } else {
                    Image(systemName: die.symbolName ?? "circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .scaleEffect(isSelected ? 1.08 : (isHovered ? 1.03 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Numeric Die Picker

struct NumericDiePicker: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DieType.numericDice) { die in
                NumericDieButton(die: die)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }
}

struct NumericDieButton: View {
    @EnvironmentObject var appState: AppState
    let die: DieType
    @State private var isHovered = false

    var isSelected: Bool { appState.selectedDie == die }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                appState.selectedDie = die
                appState.result = nil
            }
        } label: {
            ZStack {
                GlassTile(isSelected: isSelected, width: 60, height: 36, cornerRadius: 10)
                Text(die.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Result View

struct ResultView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .frame(height: 72)
                .padding(.horizontal, 16)

            VStack(spacing: 2) {
                if appState.isRolling && appState.selectedDie == .coin {
                    FlashingEllipsis()
                        .transition(.opacity)
                } else if let result = appState.result {
                    Text(result.display)
                        .font(appState.showKanji && appState.selectedDie == .coin
                              ? .custom("Zen Maru Gothic Bold", size: 36)
                              : .system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .id(result.display)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))

                    Text(appState.selectedDie == .coin ? "coin flip" : appState.selectedDie.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                } else {
                    Text(appState.selectedDie == .coin ? "Flip a coin" : "Roll \(appState.selectedDie.rawValue)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: appState.result?.display)
            .animation(.easeOut(duration: 0.15), value: appState.isRolling)
        }
        .frame(height: 72 + 32)
    }
}
// MARK: - QuickRoll Toggle
struct QuickRollToggle: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            GlassTile(isSelected: false, secondary: true, width: 265, height: 30, cornerRadius: 15)
            HStack {
                Text("Quick Roll")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                Spacer()
                Toggle("", isOn: $appState.instantRoll)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .padding(.horizontal, 20)
            }
            .padding(.horizontal, 16)
        }
    }
}
// MARK: - Roll Button

struct RollButton: View {
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation { appState.roll() }
        } label: {
            HStack {
                Image(systemName: appState.isRolling ? "hourglass" : "dice")
                    .symbolEffect(.pulse, isActive: appState.isRolling)
                Text(appState.isRolling ? "Rolling…" : "Roll")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(.tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .accentColor.opacity(0.4), radius: isHovered ? 12 : 8, y: isHovered ? 5 : 3)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(appState.isRolling)
        .scaleEffect(appState.isRolling ? 0.97 : (isHovered ? 1.02 : 1.0))
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: appState.isRolling)
    }
}

// MARK: - Quit Button

struct QuitButton: View {
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                ZStack {
                    GlassTile(isSelected:false, width:58, height:30, cornerRadius:15)
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, -4)
                        Text("quit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                }
                .scaleEffect(isHovered ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 0)
            .onHover{ isHovered = $0 }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            Spacer()
        }
    }
}

#Preview {
    DicePopoverView()
        .environmentObject(AppState())
}
