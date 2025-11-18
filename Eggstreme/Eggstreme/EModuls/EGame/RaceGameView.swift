//
//  RaceGameView.swift
//  Eggstreme
//
//  Created by Dias Atudinov on 18.11.2025.
//


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
            
            GeometryReader { geo in
                SpriteView(scene: viewModel.scene)
                    .background(Color.clear)
                    .ignoresSafeArea()
                    .onAppear { viewModel.attachSceneSize(geo.size) }
                    .onChange(of: geo.size) { viewModel.attachSceneSize($0) }
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
                    Button { viewModel.movePlayer(direction: .left) }  label: { Label("Влево", systemImage: "arrow.left.circle.fill") }
                        .buttonStyle(.borderedProminent)
                    Button { viewModel.movePlayer(direction: .right) } label: { Label("Вправо", systemImage: "arrow.right.circle.fill") }
                        .buttonStyle(.borderedProminent)
                    
                    Button {
                            viewModel.resetGame()
                            viewModel.startGame()
                        } label: {
                            Label("Рестарт", systemImage: "arrow.counterclockwise.circle.fill")
                                .font(.title3.weight(.bold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                }
                .padding(.bottom, 16)
                
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
            if case let .finished(w) = viewModel.state {
                ResultOverlay(isWin: w == .player) { viewModel.resetGame() }
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

// MARK: - Assets
private enum CarAsset {
    static let player  = "car_player"
    static let enemy1  = "car_enemy1"
    static let enemy2  = "car_enemy2"
}

private enum ObstacleAsset {
    static let oil     = "obs_oil"     // масляное пятно (PNG с альфой)
    static let cone    = "obs_cone"    // дорожный конус
    static let barrier = "obs_barrier" // барьер/блок
    static let spikes  = "obs_spikes"  // шипы
}

// MARK: - ViewModel & Scene Glue

final class RaceGameViewModel: ObservableObject {
    enum GameState: Equatable { case idle, running, finished(Winner) }
    enum Winner { case player, opponent1, opponent2 }
    enum Direction { case left, right }

    @Published var state: GameState = .idle
    @Published private(set) var timeRemaining: Int = totalSeconds
    @Published private(set) var speedHint: String = "нормальные"

    static let totalSeconds = 60

    // <<<<<<<<<<<<<<<< ЕДИНСТВЕННАЯ СЦЕНА
    let scene: RaceGameScene

    init() {
        let s = RaceGameScene(size: CGSize(width: 1024, height: 768), totalSeconds: Self.totalSeconds)
        s.scaleMode = .resizeFill
        s.backgroundColor = .clear
        self.scene = s              // сначала инициализируем ВСЕ свойства
        self.scene.gameDelegate = self
    }

    var timeRemainingString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    func attachSceneSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        if scene.size != size { scene.size = size }
    }

    func startGame() {
        guard state != .running else { return }
        timeRemaining = Self.totalSeconds
        state = .running
        scene.startRace()
        let descriptor = ["медленные","нормальные","быстрые"].randomElement() ?? "нормальные"
        speedHint = descriptor
        scene.setOpponentsSpeed(mode: descriptor)
    }

    func resetGame() {
        state = .idle
        timeRemaining = Self.totalSeconds
        scene.resetRace()
    }

    func movePlayer(direction: Direction) {
        scene.movePlayer(direction: direction == .left ? -1 : 1)
    }
}

extension RaceGameViewModel: RaceGameSceneDelegate {
    func gameDidUpdateTime(_ secondsLeft: Int) { if state == .running { timeRemaining = max(0, secondsLeft) } }
    func gameDidFinish(winner: RaceGameScene.WinnerID) {
        state = .finished(
            winner == .player ? .player : (winner == .opponent1 ? .opponent1 : .opponent2)
        )
    }
}

// MARK: - Physics
private struct Physics {
    static let player: UInt32    = 1 << 0
    static let obstacle: UInt32  = 1 << 1
}

// MARK: - Obstacle Types
private enum ObstacleType: CaseIterable {
    case oil, cone, barrier, spikes

    var imageName: String {
        switch self {
        case .oil:     return ObstacleAsset.oil
        case .cone:    return ObstacleAsset.cone
        case .barrier: return ObstacleAsset.barrier
        case .spikes:  return ObstacleAsset.spikes
        }
    }

    // Рекомендованный целевой размер на экране (можно подогнать под свои текстуры)
    var targetSize: CGSize {
        switch self {
        case .oil:     return CGSize(width: 64, height: 36)
        case .cone:    return CGSize(width: 32, height: 40)
        case .barrier: return CGSize(width: 72, height: 28)
        case .spikes:  return CGSize(width: 68, height: 22)
        }
    }

    var slowFactor: CGFloat {
        switch self {
        case .oil:     return 0.55
        case .cone:    return 0.85
        case .barrier: return 0.75
        case .spikes:  return 0.60
        }
    }
    var duration: TimeInterval {
        switch self {
        case .oil:
            1.5
        case .cone:
            0.8
        case .barrier:
            2.0
        case .spikes:
            2.2
        }
    }
}

protocol RaceGameSceneDelegate: AnyObject {
    func gameDidUpdateTime(_ secondsLeft: Int)
    func gameDidFinish(winner: RaceGameScene.WinnerID)
}

final class RaceGameScene: SKScene {
    enum WinnerID { case player, opponent1, opponent2 }
    weak var gameDelegate: RaceGameSceneDelegate?
    
    // MARK: - Lanes
    private let lanesCount = 3
    private var laneXs: [CGFloat] = []
    private var laneWidth: CGFloat = 0
    
    // MARK: - Cars
    private var player: SKSpriteNode!
    private var opp1: SKSpriteNode!
    private var opp2: SKSpriteNode!
    
    // Логический прогресс (вперед по трассе), px
    private var progressPlayer: CGFloat = 0
    private var progressOpp1: CGFloat = 0
    private var progressOpp2: CGFloat = 0
    
    // Скорости (px/s)
//    private var speedPlayer: CGFloat = 320
    private var speedOpp1: CGFloat = 300
    private var speedOpp2: CGFloat = 340
    
    private var basePlayerSpeed: CGFloat = 320
    private var currentPlayerSpeed: CGFloat = 320
    
    // MARK: - Road scrolling
    private var scrollSpeed: CGFloat = 300 // скорость «движения дороги» вниз
    private var scrollY: CGFloat = 0       // сколько пикселей «проехали»
    
    private var obstacles: [SKNode] = []
    private var obstacleSpawnAccumulator: TimeInterval = 0
    private var obstacleSpawnInterval: TimeInterval = 1.0   // средний интервал спавна
    private var lastSpawnLane: Int? = nil
    
    // Пунктирные разделители как бесконечные «ленты»
    private struct ScrollingStripe {
        let container: SKNode
        let segA: SKSpriteNode
        let segB: SKSpriteNode
    }
    private var stripes: [ScrollingStripe] = []
    
    // Финишная линия
    private var finishEnabled = false
    private var finishNode: SKSpriteNode?
    private var finishLogicalY: CGFloat = 0 // логическая позиция финиша по трассе
    
    // MARK: - Time
    private var totalSeconds: Int
    private var startTime: TimeInterval = 0
    private var lastReportedSecond: Int = .max
    private var raceStarted = false
    private var raceEnded = false
    
    private var isConfigured = false       // сцену собрали хотя бы раз
    private var needsRelayout = false
    
    private let carSize = CGSize(width: 55, height: 65)
    private let laneSidePadding: CGFloat = 12
    private let tiltAngle: CGFloat = .pi * 0.10

    // Кулдаун смены полосы
    private var lastLaneChangeTime: TimeInterval = 0
    private let laneChangeCooldown: TimeInterval = 0.16
    
    private var separatorXs: [CGFloat] = []
    
    private var playerLaneIndex: Int = 1 // стартуем в средней полосе

    private var slowEndTime: TimeInterval = 0
    
    // камера/скролл
    private var lastScrollY: CGFloat = 0

    // визуальный масштаб разницы прогресса в экранные пиксели (как было)
    private let diffScale: CGFloat = 0.15
    
    private var isInputReady: Bool {
        isConfigured && laneXs.count == lanesCount && player != nil
    }
    
    init(size: CGSize, totalSeconds: Int) {
        self.totalSeconds = totalSeconds
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Life cycle
    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        backgroundColor = .clear
        physicsWorld.contactDelegate = self
        guard !isConfigured else { return }
        configureAll()
        isConfigured = true
        
    }
    
    private func configureAll() {
        layoutLanes()
        buildRoad()
        spawnCars()
    }
    
    private func rebuildAll() {
        removeAllChildren()
        stripes.removeAll()
        finishNode = nil
        finishEnabled = false
        scrollY = 0
        configureAll()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size else { return }
        needsRelayout = true
    }
    
    // MARK: - Layout
    private func layoutLanes() {
        // ширина полосы = ширина машины + двусторонний отступ
        laneWidth = carSize.width + laneSidePadding * 2
        let totalTrackWidth = laneWidth * CGFloat(lanesCount)
        let leftEdge = (size.width - totalTrackWidth) / 2.0

        // центры полос
        laneXs = (0..<lanesCount).map { i in
            leftEdge + laneWidth * (CGFloat(i) + 0.5)
        }

        // сохраним границы для разделителей
        separatorXs = [
            leftEdge + laneWidth,              // между 1-й и 2-й
            leftEdge + laneWidth * 2           // между 2-й и 3-й
        ]
    }
    
    private func updateStripesScrolling(delta: CGFloat) {
        // каждый stripe состоит из двух сегментов A/B, циклически прокручиваем по delta
        for stripe in stripes {
            for seg in [stripe.segA, stripe.segB] {
                seg.position.y -= delta

                // обёртка вниз
                if seg.position.y + seg.size.height <= 0 {
                    seg.position.y += seg.size.height * 2
                }
                // обёртка вверх (в случае резкой коррекции камеры)
                if seg.position.y >= seg.size.height {
                    seg.position.y -= seg.size.height * 2
                }
            }
        }
    }
    
    private func nearestLaneIndex(forX x: CGFloat) -> Int? {
        guard !laneXs.isEmpty else { return nil }
        return laneXs.enumerated().min(by: { abs($0.element - x) < abs($1.element - x) })?.offset
    }

    private func edgeBounce(isLeftEdge: Bool) {
        guard let player else { return } // безопасно
        let dx: CGFloat = isLeftEdge ? -6 : 6
        let wobble = SKAction.sequence([
            .group([
                .moveBy(x: dx, y: 0, duration: 0.06),
                .rotate(byAngle: isLeftEdge ? -tiltAngle*0.35 : tiltAngle*0.35, duration: 0.06)
            ]),
            .group([
                .moveBy(x: -dx, y: 0, duration: 0.08),
                .rotate(toAngle: 0, duration: 0.08, shortestUnitArc: true)
            ])
        ])
        wobble.timingMode = .easeInEaseOut
        player.run(wobble)
    }
    
    private func buildRoad() {
        stripes.removeAll()

        let dashSize = CGSize(width: 6, height: 20)
        let gap: CGFloat = 16

        func makeDashTexture() -> SKTexture {
            let node = SKShapeNode(rectOf: dashSize, cornerRadius: 3)
            node.fillColor = .white
            node.strokeColor = .clear
            let view = SKView()
            let scene = SKScene(size: dashSize)
            scene.backgroundColor = .clear
            node.position = CGPoint(x: dashSize.width/2, y: dashSize.height/2)
            scene.addChild(node)
            return view.texture(from: scene) ?? SKTexture()
        }
        let dashTexture = makeDashTexture()

        func makeStripe(atX x: CGFloat) -> ScrollingStripe {
            func makeSegment() -> SKSpriteNode {
                let segHeight = size.height + 2 * (dashSize.height + gap)
                let renderSize = CGSize(width: dashSize.width, height: segHeight)
                let v = SKView()
                let s = SKScene(size: renderSize)
                s.backgroundColor = .clear
                var y: CGFloat = dashSize.height/2
                while y < segHeight {
                    let sp = SKSpriteNode(texture: dashTexture)
                    sp.position = CGPoint(x: dashSize.width/2, y: y)
                    s.addChild(sp)
                    y += dashSize.height + gap
                }
                let tex = v.texture(from: s) ?? SKTexture()
                let node = SKSpriteNode(texture: tex)
                node.size = renderSize
                node.anchorPoint = CGPoint(x: 0.5, y: 0)
                node.zPosition = 2
                return node
            }
            let container = SKNode()
            let segA = makeSegment()
            let segB = makeSegment()
            segA.position = CGPoint(x: x, y: 0)
            segB.position = CGPoint(x: x, y: segA.size.height)
            container.addChild(segA)
            container.addChild(segB)
            addChild(container)
            return ScrollingStripe(container: container, segA: segA, segB: segB)
        }

        for x in separatorXs {
            stripes.append(makeStripe(atX: x))
        }
    }
    
    private func spawnCars() {
        func car(imageNamed name: String) -> SKSpriteNode {
               let node = SKSpriteNode(imageNamed: name)
               node.size = carSize // 55×65
               node.zPosition = 5
               node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
               return node
           }
        player = car(imageNamed: CarAsset.player)
        opp1   = car(imageNamed: CarAsset.enemy1)
        opp2   = car(imageNamed: CarAsset.enemy2)

        let baseY = size.height * 0.18
        player.position = CGPoint(x: laneXs[1], y: baseY)
        player.physicsBody = SKPhysicsBody(rectangleOf: carSize)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = Physics.player
        player.physicsBody?.contactTestBitMask = Physics.obstacle
        player.physicsBody?.collisionBitMask = 0
        
        playerLaneIndex = 1
        opp1.position   = CGPoint(x: laneXs[0], y: baseY + 20)
        opp2.position   = CGPoint(x: laneXs[2], y: baseY + 40)

        
        addChild(player); addChild(opp1); addChild(opp2)

        progressPlayer = 0; progressOpp1 = 0; progressOpp2 = 0
        
    }
    
    private func spawnObstacle() {
        let type = ObstacleType.allCases.randomElement()!

        // lane — не повторяем предыдущую по возможности
        var laneIndex = Int.random(in: 0..<lanesCount)
        if let last = lastSpawnLane, lanesCount > 1 {
            for _ in 0..<3 where laneIndex == last { laneIndex = Int.random(in: 0..<lanesCount) }
        }
        lastSpawnLane = laneIndex

        // создаём спрайт по картинке
        let sprite = SKSpriteNode(imageNamed: type.imageName)
        sprite.size = type.targetSize
        sprite.zPosition = 4
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        // sprite.texture?.filteringMode = .nearest

        // физтело по альфе текстуры — точный хитбокс
        if let tex = sprite.texture {
            sprite.physicsBody = SKPhysicsBody(texture: tex, size: sprite.size)
        } else {
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        }
        sprite.physicsBody?.isDynamic = false
        sprite.physicsBody?.categoryBitMask = Physics.obstacle
        sprite.physicsBody?.contactTestBitMask = Physics.player
        sprite.physicsBody?.collisionBitMask = 0

        sprite.name = "obstacle:\(type)"  // для идентификации при контакте

        // позиция: сверху, чтобы «въезжало» в кадр
        let x = laneXs[laneIndex]
        let startY = size.height + sprite.size.height
        sprite.position = CGPoint(x: x, y: startY)

        addChild(sprite)
        obstacles.append(sprite)
    }
    
    // MARK: - Public API from ViewModel
    func startRace() {
        guard !raceStarted else { return }
        currentPlayerSpeed = basePlayerSpeed
        raceStarted = true
        raceEnded = false
        startTime = CACurrentMediaTime()
        lastReportedSecond = .max
        finishEnabled = false
        finishNode?.removeFromParent()
        finishNode = nil
        scrollY = 0
        progressPlayer = 0
        progressOpp1 = 0
        progressOpp2 = 0
    }
    
    func resetRace() {
        currentPlayerSpeed = basePlayerSpeed
        raceStarted = false
        raceEnded = false
        finishEnabled = false
        finishNode?.removeFromParent()
        finishNode = nil
        removeAllChildren()
        stripes.removeAll()
        layoutLanes()
        buildRoad()
        spawnCars()
    }
    
    func setOpponentsSpeed(mode: String) {
        switch mode {
        case "медленные":
            speedOpp1 = 280; speedOpp2 = 290
        case "быстрые":
            speedOpp1 = 330; speedOpp2 = 350
        default:
            speedOpp1 = 305; speedOpp2 = 315
        }
    }
    
    func movePlayer(direction: Int) {
        guard isInputReady, let player else { return }

        // защита от спама
        let now = CACurrentMediaTime()
        guard now - lastLaneChangeTime >= laneChangeCooldown else { return }

        // считаем целевую полосу индексом
        let targetIdx = max(0, min(lanesCount - 1, playerLaneIndex + (direction < 0 ? -1 : 1)))

        // если упёрлись в край – пружинка и выходим
        if targetIdx == playerLaneIndex {
            edgeBounce(isLeftEdge: direction < 0)
            return
        }

        // целевая координата по центру полосы
        let newX = laneXs[targetIdx]
        let duration: TimeInterval = 0.16
        let targetTilt = (direction < 0 ? -tiltAngle : tiltAngle)

        let tilt = SKAction.rotate(toAngle: targetTilt, duration: duration * 0.6, shortestUnitArc: true)
        let move = SKAction.moveTo(x: newX, duration: duration)
        move.timingMode = .easeInEaseOut
        let straighten = SKAction.rotate(toAngle: 0, duration: duration * 0.4, shortestUnitArc: true)

        player.run(.sequence([.group([tilt, move]), straighten]))
        playerLaneIndex = targetIdx                      // <<< фиксируем полосу сразу
        lastLaneChangeTime = now
    }
    
    // MARK: - Finish line
    private func ensureFinish() {
        guard finishNode == nil else { return }

        let totalTrackWidth = laneWidth * CGFloat(lanesCount)
        let leftEdge = (size.width - totalTrackWidth) / 2.0
        let w = totalTrackWidth * 0.98 // полоска почти на всю ширину трека
        let h: CGFloat = 14

        finishLogicalY = scrollY + size.height * 0.9

        // рисуем «зебру»
        let bandWidth: CGFloat = 24
        let texSize = CGSize(width: w, height: h)
        let view = SKView()
        let scene = SKScene(size: texSize)
        scene.backgroundColor = .clear
        var x: CGFloat = 0
        var white = true
        while x < w {
            let rect = SKShapeNode(rectOf: CGSize(width: min(bandWidth, w - x), height: h))
            rect.position = CGPoint(x: x + min(bandWidth, w - x)/2, y: h/2)
            rect.fillColor = white ? .white : .black
            rect.strokeColor = .clear
            scene.addChild(rect)
            white.toggle()
            x += bandWidth
        }
        let texture = view.texture(from: scene) ?? SKTexture()
        let line = SKSpriteNode(texture: texture)
        line.size = texSize
        line.zPosition = 15
        line.position = CGPoint(x: leftEdge + totalTrackWidth/2, y: size.height + 100) // старт за экраном
        addChild(line)
        finishNode = line
    }
    
    // MARK: - Update loop
    override func update(_ currentTime: TimeInterval) {
        
        if needsRelayout {
               needsRelayout = false
               rebuildAll()
           }
        
        guard raceStarted, !raceEnded else { return }
        
        // Таймер
        let elapsed = max(0, currentTime - startTime)
        let left = max(0, totalSeconds - Int(elapsed))
        if left != lastReportedSecond {
            lastReportedSecond = left
            gameDelegate?.gameDidUpdateTime(left)
            if left == 0 { // время вышло — показываем финиш
                finishEnabled = true
                ensureFinish()
            }
        }
        
        // dt (≈ 1/60)
        let dt: CGFloat = 1.0 / 60.0

            // 1) Базовый скролл дороги вперёд
            let oldScroll = scrollY
            scrollY += scrollSpeed * dt

            // 2) Логический прогресс машин
            progressPlayer += currentPlayerSpeed * dt
            progressOpp1   += speedOpp1 * dt
            progressOpp2   += speedOpp2 * dt

            // 3) Камера: держим игрока в видимом вертикальном коридоре
            let baseY = size.height * 0.18
            let minY  = size.height * 0.14   // нижняя граница окна видимости
            let maxY  = size.height * 0.60   // верхняя граница окна видимости

            // текущая экранная Y игрока до коррекции
            var playerScreenY = baseY + (progressPlayer - scrollY) * diffScale

            if playerScreenY < minY {
                // пересчитаем scrollY так, чтобы игрок оказался на minY
                scrollY = progressPlayer - (minY - baseY) / diffScale
                playerScreenY = minY
            } else if playerScreenY > maxY {
                // держим игрока не выше maxY
                scrollY = progressPlayer - (maxY - baseY) / diffScale
                playerScreenY = maxY
            }

            // 4) delta скролла за кадр
            let deltaScroll = scrollY - oldScroll

            // 5) Двигаем пунктирные линии на delta
            updateStripesScrolling(delta: deltaScroll)

            // 6) Позиции машин по экрану
            // (opp1/opp2 считаются от того же scrollY, визуально «едут»)
            opp1.position.y   = baseY + (progressOpp1 - scrollY) * diffScale + 20
            opp2.position.y   = baseY + (progressOpp2 - scrollY) * diffScale + 40
            player.position.y = playerScreenY

            // 7) Препятствия двигаем согласованно со «скоростью камеры»
        obstacleSpawnAccumulator += 1.0 / 60.0
        let dynamicInterval = obstacleSpawnInterval + Double.random(in: -0.35...0.35)
        if obstacleSpawnAccumulator >= dynamicInterval {
            obstacleSpawnAccumulator = 0
            spawnObstacle()
        }

        // Движение препятствий вниз вместе с дорогой
        for node in obstacles {
            node.position.y -= scrollSpeed * dt
        }

        // Удаление, если вышли за низ
        obstacles.removeAll { node in
            if node.position.y < -200 {
                node.removeFromParent()
                return true
            }
            return false
        }

            // 8) Финишная линия: экранная Y = логическая - scrollY
            if finishEnabled, let finishNode {
                let screenY = finishLogicalY - scrollY
                finishNode.position = CGPoint(x: size.width/2, y: screenY)
                checkFinishIfCrossed(finishY: screenY)
            }

            // 9) Восстановление скорости после «slow»
            let nowT = CACurrentMediaTime()
            if nowT >= slowEndTime {
                currentPlayerSpeed = basePlayerSpeed
            }
    }
    
    private func updateStripesScrolling() {
        // каждый stripe состоит из двух сегментов A/B, которые циклически двигаются вниз
        for stripe in stripes {
            for seg in [stripe.segA, stripe.segB] {
                seg.position.y -= scrollSpeed * (1.0/60.0)
                if seg.position.y + seg.size.height <= 0 {
                    seg.position.y += seg.size.height * 2
                }
            }
        }
    }
    
    private func checkFinishIfCrossed(finishY: CGFloat) {
        guard !raceEnded else { return }
        // кто первым пересек линию: та машина, чья «экранная» Y >= finishY
        var crossed: [(WinnerID, CGFloat)] = []
        if player.position.y >= finishY { crossed.append((.player, player.position.y)) }
        if opp1.position.y   >= finishY { crossed.append((.opponent1, opp1.position.y)) }
        if opp2.position.y   >= finishY { crossed.append((.opponent2, opp2.position.y)) }
        guard !crossed.isEmpty else { return }
        crossed.sort { $0.1 > $1.1 } // выше по экрану — раньше пересёк
        raceEnded = true
        raceStarted = false
        gameDelegate?.gameDidFinish(winner: crossed.first!.0)
    }
}

extension RaceGameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard mask == (Physics.player | Physics.obstacle) else { return }

        // Узнаём ноду препятствия
        let obstacleNode = (contact.bodyA.categoryBitMask == Physics.obstacle ? contact.bodyA.node
                                                                             : contact.bodyB.node)
        applySlowEffect(for: obstacleNode)
    }
    
    private func applySlowEffect(for obstacleNode: SKNode?) {
        guard let obstacleNode else { return }
        // Определяем тип по имени
        let type: ObstacleType = {
            if let name = obstacleNode.name {
                if name.contains("oil")     { return .oil }
                if name.contains("cone")    { return .cone }
                if name.contains("barrier") { return .barrier }
                if name.contains("spikes")  { return .spikes }
            }
            // если имя не закодировалось, оценим по размеру/цвету (fallback)
            return .barrier
        }()

        // Время сейчас
        let now = CACurrentMediaTime()
        // Не наслаиваем, а переустанавливаем более «сильный/долгий» эффект
        let newEnd = now + type.duration
        slowEndTime = max(slowEndTime, newEnd)

        // Применяем замедление: текущая скорость = база * slowFactor,
        // но не ниже «пола» (чтобы машина совсем не встала)
        let floorSpeed: CGFloat = 160
        currentPlayerSpeed = max(basePlayerSpeed * type.slowFactor, floorSpeed)

        // Визуальный фидбек: краткий флэш
        if let player {
            let flash = SKAction.sequence([
                .colorize(with: .white, colorBlendFactor: 0.6, duration: 0.06),
                .wait(forDuration: 0.08),
                .colorize(withColorBlendFactor: 0.0, duration: 0.12)
            ])
            player.run(flash)
        }

        // Удаляем препятствие после столкновения (чтобы не триггерило повторно)
        obstacleNode.removeFromParent()
        obstacles.removeAll { $0 === obstacleNode }
    }
}




#Preview {
    RaceGameView()
}
