import SwiftUI
import SpriteKit
import Combine

// MARK: - Public SwiftUI Entry

struct RaceGameView: View {
    @StateObject private var viewModel = RaceGameViewModel()
    @State private var sceneSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(colors: [.purple.opacity(0.8), .blue, .indigo],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // SpriteKit сцена с прозрачным фоном
            GeometryReader { geo in
                SpriteView(scene: viewModel.makeScene(size: geo.size))
                    .background(Color.clear)
                    .ignoresSafeArea()
                    .onAppear { sceneSize = geo.size }
            }
            
            // SwiftUI HUD и кнопки
            VStack {
                HStack {
                    Text("Время: \(viewModel.timeRemainingString)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                    
                    Spacer()
                    
                    Text("Скорость соперников: \(viewModel.speedHint)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Кнопки управления игроком (смена полосы)
                HStack(spacing: 24) {
                    Button {
                        viewModel.movePlayer(direction: .left)
                    } label: {
                        Label("Влево", systemImage: "arrow.left.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
                    
                    Button {
                        viewModel.movePlayer(direction: .right)
                    } label: {
                        Label("Вправо", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.25))
                }
                .padding(.bottom, 10)
                
                // Кнопки старта/рестарта
                HStack(spacing: 16) {
                    Button {
                        viewModel.startGame()
                    } label: {
                        Text(viewModel.state == .running ? "Идёт гонка…" : "Старт")
                            .font(.title3.bold())
                            .frame(maxWidth: 240)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.state == .running ? .green.opacity(0.6) : .green)
                    .disabled(viewModel.state == .running)
                    
                    Button {
                        viewModel.resetGame()
                    } label: {
                        Text("Сброс")
                            .font(.title3.bold())
                            .frame(maxWidth: 140)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding(.bottom, 18)
            }
            
            // SwiftUI окна результата
            if case let .finished(winner) = viewModel.state {
                ResultOverlay(
                    isWin: winner == .player,
                    onAgain: { viewModel.resetGame() }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Result Overlay

private struct ResultOverlay: View {
    let isWin: Bool
    var onAgain: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(isWin ? "Победа" : "Поражение")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(isWin ? .green : .red)
                
                Button(action: onAgain) {
                    Text("Играть снова")
                        .font(.title3.bold())
                        .padding(.horizontal, 24).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.25))
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(radius: 20)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - ViewModel & Scene Glue

final class RaceGameViewModel: ObservableObject {
    enum GameState {
        case idle
        case running
        case finished(Winner)
    }
    enum Winner {
        case player, opponent1, opponent2
    }
    enum Direction { case left, right }
    
    @Published var state: GameState = .idle
    @Published private(set) var timeRemaining: Int = totalSeconds
    @Published private(set) var speedHint: String = "нормальные"
    
    var timeRemainingString: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private var scene: RaceGameScene?
    private var cancellables = Set<AnyCancellable>()
    
    static let totalSeconds = 60
    
    func makeScene(size: CGSize) -> SKScene {
        if let s = scene, s.size == size { return s }
        let new = RaceGameScene(size: size, totalSeconds: Self.totalSeconds)
        new.scaleMode = .resizeFill
        new.gameDelegate = self
        new.backgroundColor = .clear
        scene = new
        return new
    }
    
    func startGame() {
        guard state != .running else { return }
        timeRemaining = Self.totalSeconds
        state = .running
        scene?.startRace()
        // лёгкая вариативность скорости соперников
        let descriptor = ["медленные","нормальные","быстрые"].randomElement() ?? "нормальные"
        speedHint = descriptor
        scene?.setOpponentsSpeed(mode: descriptor)
    }
    
    func resetGame() {
        state = .idle
        timeRemaining = Self.totalSeconds
        scene?.resetRace()
    }
    
    func movePlayer(direction: Direction) {
        scene?.movePlayer(direction: direction == .left ? -1 : 1)
    }
}

extension RaceGameViewModel: RaceGameSceneDelegate {
    func gameDidUpdateTime(_ secondsLeft: Int) {
        if state == .running {
            timeRemaining = max(0, secondsLeft)
        }
    }
    func gameDidFinish(winner: RaceGameScene.WinnerID) {
        switch winner {
        case .player: state = .finished(.player)
        case .opponent1: state = .finished(.opponent1)
        case .opponent2: state = .finished(.opponent2)
        }
    }
}

// MARK: - SpriteKit Scene

protocol RaceGameSceneDelegate: AnyObject {
    func gameDidUpdateTime(_ secondsLeft: Int)
    func gameDidFinish(winner: RaceGameScene.WinnerID)
}

final class RaceGameScene: SKScene {
    enum WinnerID { case player, opponent1, opponent2 }
    
    weak var gameDelegate: RaceGameSceneDelegate?
    
    // Лэйаут полос
    private var laneXs: [CGFloat] = []
    private let lanesCount = 3
    
    // Ноды
    private var player: SKSpriteNode!
    private var opponent1: SKSpriteNode!
    private var opponent2: SKSpriteNode!
    private var finishLine: SKShapeNode?
    private var roadLines: [SKShapeNode] = []
    
    // Параметры
    private var raceStarted = false
    private var raceEnded = false
    private var totalSeconds: Int
    private var startTime: TimeInterval = 0
    private var lastReportedSecond: Int = .max
    private var baseScrollSpeed: CGFloat = 260  // скорость "движения дороги"
    private var playerSpeed: CGFloat = 300
    private var opponent1Speed: CGFloat = 300
    private var opponent2Speed: CGFloat = 300
    
    init(size: CGSize, totalSeconds: Int) {
        self.totalSeconds = totalSeconds
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        backgroundColor = .clear
        configureLanes()
        addDashedSeparators()
        spawnCars()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        roadLines.removeAll()
        finishLine = nil
        configureLanes()
        addDashedSeparators()
        spawnCars()
        raceStarted = false
        raceEnded = false
    }
    
    // MARK: - Setup helpers
    
    private func configureLanes() {
        // три вертикальных полосы равной ширины
        let w = size.width
        let laneWidth = w / CGFloat(lanesCount)
        laneXs = (0..<lanesCount).map { i in
            let x0 = CGFloat(i) * laneWidth
            return x0 + laneWidth/2
        }
    }
    
    private func addDashedSeparators() {
        // две пунктирные вертикальные линии между тремя полосами
        for i in 1..<lanesCount {
            let x = size.width * CGFloat(i) / CGFloat(lanesCount)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            let line = SKShapeNode(path: path)
            line.strokeColor = .white
            line.lineWidth = 6
            line.lineDashPattern = [16, 14] as [NSNumber]
            line.alpha = 0.7
            addChild(line)
            roadLines.append(line)
        }
    }
    
    private func spawnCars() {
        // простые цветные прямоугольники; замените на изображения при желании
        func makeCar(color: SKColor) -> SKSpriteNode {
            let node = SKSpriteNode(color: color, size: CGSize(width: size.width / 9, height: size.height / 10))
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.colorBlendFactor = 1.0
            node.zPosition = 5
            return node
        }
        player = makeCar(color: .cyan)
        opponent1 = makeCar(color: .red)
        opponent2 = makeCar(color: .yellow)
        
        // начальные позиции у нижнего края
        let bottomY = size.height * 0.15
        player.position = CGPoint(x: laneXs[1], y: bottomY)   // старт в средней полосе
        opponent1.position = CGPoint(x: laneXs[0], y: bottomY + 80)
        opponent2.position = CGPoint(x: laneXs[2], y: bottomY + 160)
        
        addChild(player)
        addChild(opponent1)
        addChild(opponent2)
    }
    
    // MARK: - Control
    
    func startRace() {
        guard !raceStarted else { return }
        raceStarted = true
        raceEnded = false
        startTime = CACurrentMediaTime()
        lastReportedSecond = .max
        finishLine?.removeFromParent()
        finishLine = nil
    }
    
    func resetRace() {
        raceStarted = false
        raceEnded = false
        finishLine?.removeFromParent()
        finishLine = nil
        removeAllChildren()
        roadLines.removeAll()
        configureLanes()
        addDashedSeparators()
        spawnCars()
    }
    
    func setOpponentsSpeed(mode: String) {
        switch mode {
        case "медленные":
            opponent1Speed = 260
            opponent2Speed = 270
        case "быстрые":
            opponent1Speed = 330
            opponent2Speed = 350
        default:
            opponent1Speed = 300
            opponent2Speed = 305
        }
    }
    
    func movePlayer(direction: Int) {
        // direction: -1 (влево), +1 (вправо)
        guard let idx = laneXs.firstIndex(where: { abs($0 - player.position.x) < 2 * 1000 }) else { return }
        var new = idx + direction
        new = max(0, min(lanesCount - 1, new))
        let newX = laneXs[new]
        let move = SKAction.moveTo(x: newX, duration: 0.18)
        move.timingMode = .easeInEaseOut
        player.run(move)
    }
    
    // MARK: - Finish Line
    
    private func ensureFinishLine() {
        guard finishLine == nil else { return }
        // белая поперечная линия у верхней части экрана
        let y = size.height * 0.82
        let path = CGMutablePath()
        path.move(to: CGPoint(x: size.width * 0.05, y: y))
        path.addLine(to: CGPoint(x: size.width * 0.95, y: y))
        let line = SKShapeNode(path: path)
        line.strokeColor = .white
        line.lineWidth = 10
        line.lineDashPattern = [18, 10] as [NSNumber]
        line.glowWidth = 2
        line.zPosition = 20
        addChild(line)
        finishLine = line
    }
    
    // MARK: - Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard raceStarted, !raceEnded else { return }
        
        // оставшееся время
        let elapsed = max(0, currentTime - startTime)
        let left = max(0, totalSeconds - Int(elapsed))
        if left != lastReportedSecond {
            lastReportedSecond = left
            gameDelegate?.gameDidUpdateTime(left)
        }
        
        // движение вперёд: поднимаем машины вверх по экрану
        let dt: CGFloat = 1.0 / 60.0
        player.position.y += playerSpeed * dt
        opponent1.position.y += opponent1Speed * dt
        opponent2.position.y += opponent2Speed * dt
        
        // прокрутка: когда машина уходит слишком высоко — слегка отбрасываем назад,
        // чтобы создать иллюзию непрерывного движения по "бесконечной" трассе
        let clampHigh = size.height * 0.9
        let resetDelta = size.height * 0.6
        for car in [player!, opponent1!, opponent2!] {
            if car.position.y > clampHigh {
                car.position.y -= resetDelta
            }
        }
        
        // по достижении 60-й секунды — показать стоп-линию
        if left == 0 {
            ensureFinishLine()
            // как только кто-то пересёк линию — фиксируем победителя
            checkFinish()
        }
    }
    
    private func checkFinish() {
        guard let finishLine else { return }
        let finishY = finishLine.path!.boundingBoxOfPath.origin.y  // линия горизонтальная, берём y
        func passed(_ node: SKNode) -> Bool { node.position.y >= finishY }
        
        var order: [(WinnerID, CGFloat)] = []
        if passed(player)   { order.append((.player, player.position.y)) }
        if passed(opponent1){ order.append((.opponent1, opponent1.position.y)) }
        if passed(opponent2){ order.append((.opponent2, opponent2.position.y)) }
        
        if !order.isEmpty {
            // победил тот, кто выше относительно линии
            order.sort { $0.1 > $1.1 }
            raceEnded = true
            raceStarted = false
            gameDelegate?.gameDidFinish(winner: order.first!.0)
        }
    }
}

// MARK: - (Опционально) Блокировка ориентации в альбомную

/// Добавьте `.modifier(OrientationLock(.landscape))` в корневой вью App, если хотите жёстко зафиксировать альбомную ориентацию.
/// Либо пропустите, если проект уже настроен под альбом.
struct OrientationLock: ViewModifier {
    enum Orientation { case portrait, landscape }
    let orientation: Orientation
    init(_ o: Orientation) { self.orientation = o }
    func body(content: Content) -> some View {
        content
            .onAppear {
                AppOrientation.lock(to: orientation == .landscape ? .landscape : .portrait)
            }
            .onDisappear {
                AppOrientation.lock(to: .all)
            }
    }
}

private enum AppOrientation {
    static func lock(to mask: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        (scene.delegate as? UIWindowSceneDelegateProxy)?.orientationMask = mask
    }
    static func lock(to orientation: OrientationMaskPreset) {
        switch orientation {
        case .landscape: lock(to: [.landscapeLeft, .landscapeRight])
        case .portrait:  lock(to: [.portrait])
        case .all:       lock(to: .all)
        }
    }
    enum OrientationMaskPreset { case landscape, portrait, all }
}

private final class UIWindowSceneDelegateProxy: NSObject, UIWindowSceneDelegate {
    var orientationMask: UIInterfaceOrientationMask = .all
    func windowScene(_ windowScene: UIWindowScene, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        orientationMask
    }
}
