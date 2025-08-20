import UIKit
import SwiftUI

// MARK: - SwiftUI 버전 (이미지 사용)
struct PuzzleCharacterImageView: View {
    @State private var bounceOffset = 0.0
    @State private var rotation = 0.0
    @State private var scale = 1.0
    @State private var wiggle = 0.0
    
    var character: PuzzleCharacter
    
    var body: some View {
        Image(character.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation + wiggle))
            .offset(y: bounceOffset)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .onAppear {
                startAnimations()
            }
            .onTapGesture {
                playTapAnimation()
            }
    }
    
    private func startAnimations() {
        // 바운스 애니메이션
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            bounceOffset = -12
        }
        
        // 호흡 스케일 애니메이션
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            scale = 1.03
        }
        
        // 좌우 흔들기 애니메이션
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            wiggle = 3
        }
        
        // 랜덤 회전
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                rotation = Double.random(in: -2...2)
            }
        }
    }
    
    private func playTapAnimation() {
        // 터치 애니메이션
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
            scale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                scale = 1.0
            }
        }
        
        // 햅틱 피드백
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
}

// MARK: - 캐릭터 타입 정의
enum PuzzleCharacter: CaseIterable {
    case blue, cream, yellow, orange
    
    var imageName: String {
        switch self {
        case .blue: return "puzzle_blue_soccer"
        case .cream: return "puzzle_cream_glasses"
        case .yellow: return "puzzle_yellow"
        case .orange: return "puzzle_orange"
        }
    }
    
    var name: String {
        switch self {
        case .blue: return "블루"
        case .cream: return "크림"
        case .yellow: return "옐로우"
        case .orange: return "오렌지"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .blue: return Color.blue.opacity(0.1)
        case .cream: return Color.brown.opacity(0.05)
        case .yellow: return Color.yellow.opacity(0.1)
        case .orange: return Color.orange.opacity(0.1)
        }
    }
}

extension PuzzleCharacter {
    var serverIndex: Int {
        switch self {
        case .blue:   return 1
        case .cream:  return 2
        case .yellow: return 3
        case .orange: return 4
        }
    }
}

// MARK: - 메인 SwiftUI 뷰
struct PuzzleCharactersMainView: View {
    @EnvironmentObject var viewModel: MyPageViewModel
    @State private var selectedCharacter: PuzzleCharacter? = nil
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.97, blue: 0.99),
                        Color(red: 0.94, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    Group {
                        VStack(spacing: 30) {
                            // 제목
                            Text("퍼즐 친구들")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.top, 20)
                            
                            // 설명
                            Text("귀여운 친구들을 터치해보세요!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // 캐릭터 그리드
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 35) {
                                ForEach(PuzzleCharacter.allCases, id: \.self) { character in
                                    VStack(spacing: 15) {
                                        // 캐릭터 카드
                                        ZStack {
                                            // 배경 카드
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(character.backgroundColor)
                                                .frame(width: 150, height: 150)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 25)
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                                            
                                            // 캐릭터 이미지
                                            PuzzleCharacterImageView(character: character)
                                        }
                                        .contentShape(Rectangle())
                                        .scaleEffect(selectedCharacter == character ? 1.05 : 1.0)
                                        .onTapGesture {
                                            print("🔵 [UI] 캐릭터 탭: \(character) -> index: \(character.serverIndex)")
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedCharacter = character
                                            }
                                            isLoading = true
                                            let selectedImageIndex = character.serverIndex
                                            Task {
                                                do {
                                                    let response = try await UserAPIManager.shared.setProfileImage(index: selectedImageIndex)
                                                    print("✅ [Profile] API 응답 statusCode:", response.statusCode ?? -1,
                                                          "image:", response.profileImage ?? "nil",
                                                          "url:", response.profileImageUrl ?? "nil")

                                                    await viewModel.updateProfileImage(with: response)
                                                    print("📌 [Profile] updateProfileImage 이후 VM.userInfo.profileImage:", viewModel.userInfo?.profileImage ?? "nil",
                                                          "url:", viewModel.userInfo?.profileImageUrl ?? "nil")

                                                    UserDefaults.standard.set(true, forKey: "hasProfileImage")
                                                    isLoading = false
                                                } catch {
                                                    isLoading = false
                                                    print("❌ [Profile] 프로필 이미지 저장 실패:", error)
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedCharacter = nil
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 캐릭터 이름
                                        Text(character.name)
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            // .allowsHitTesting(!isLoading) moved out to Group below
                            
                            Spacer(minLength: 50)
                        }
                    }
                    .allowsHitTesting(!isLoading)
                }
                .scrollDisabled(true)
                
                // ProgressView overlay when loading
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.6)
                    }
                    .zIndex(2)
                    .allowsHitTesting(true)
                }
            }
            // .task removed
        }
    }
}

// MARK: - UIKit 버전 (이미지 사용)
class PuzzleCharacterImageUIView: UIView {
    
    private let character: PuzzleCharacter
    private var imageView: UIImageView!
    private var backgroundView: UIView!
    private var containerView: UIView!
    
    init(character: PuzzleCharacter) {
        self.character = character
        super.init(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        setupCharacter()
        startAnimations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCharacter() {
        // 컨테이너 뷰
        containerView = UIView(frame: bounds)
        addSubview(containerView)
        
        // 배경 카드
        backgroundView = UIView(frame: bounds)
        backgroundView.backgroundColor = character.backgroundUIColor
        backgroundView.layer.cornerRadius = 25
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.08
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 5)
        backgroundView.layer.shadowRadius = 10
        
        // 배경에 흰색 테두리 추가
        backgroundView.layer.borderWidth = 2
        backgroundView.layer.borderColor = UIColor.white.cgColor
        
        containerView.addSubview(backgroundView)
        
        // 캐릭터 이미지
        imageView = UIImageView(frame: CGRect(x: 15, y: 15, width: 120, height: 120))
        imageView.image = UIImage(named: character.imageName)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.15
        imageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        imageView.layer.shadowRadius = 8
        
        containerView.addSubview(imageView)
    }
    
    private func startAnimations() {
        // 바운스 애니메이션
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounceAnimation.values = [0, -12, 0, -6, 0]
        bounceAnimation.keyTimes = [0, 0.3, 0.6, 0.8, 1.0]
        bounceAnimation.duration = 2.5
        bounceAnimation.repeatCount = .infinity
        bounceAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bounceAnimation.beginTime = CACurrentMediaTime() + Double.random(in: 0...1)
        containerView.layer.add(bounceAnimation, forKey: "bounce")
        
        // 호흡 스케일 애니메이션
        let breatheAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        breatheAnimation.values = [1.0, 1.03, 1.0]
        breatheAnimation.duration = 3.0
        breatheAnimation.repeatCount = .infinity
        breatheAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        breatheAnimation.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.5)
        containerView.layer.add(breatheAnimation, forKey: "breathe")
        
        // 좌우 흔들기 애니메이션
        let wiggleAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        wiggleAnimation.values = [0, 0.05, -0.05, 0.03, 0]
        wiggleAnimation.duration = 4.0
        wiggleAnimation.repeatCount = .infinity
        wiggleAnimation.beginTime = CACurrentMediaTime() + Double.random(in: 0...2)
        wiggleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        containerView.layer.add(wiggleAnimation, forKey: "wiggle")
        
        // 랜덤한 미세 회전
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...4)) {
            let randomRotation = CABasicAnimation(keyPath: "transform.rotation.z")
            randomRotation.toValue = Double.random(in: -0.03...0.03)
            randomRotation.duration = 5.0
            randomRotation.repeatCount = .infinity
            randomRotation.autoreverses = true
            randomRotation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.containerView.layer.add(randomRotation, forKey: "randomRotation")
        }
    }
    
    // 터치 애니메이션
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // 터치 시작 애니메이션
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        })
        
        // 햅틱 피드백
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // 터치 종료 애니메이션 (스프링 효과)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [], animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.containerView.transform = .identity
            })
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        UIView.animate(withDuration: 0.2) {
            self.containerView.transform = .identity
        }
    }
}

// MARK: - 캐릭터 색상 확장
extension PuzzleCharacter {
    var backgroundUIColor: UIColor {
        switch self {
        case .blue: return UIColor.systemBlue.withAlphaComponent(0.1)
        case .cream: return UIColor.systemBrown.withAlphaComponent(0.05)
        case .yellow: return UIColor.systemYellow.withAlphaComponent(0.1)
        case .orange: return UIColor.systemOrange.withAlphaComponent(0.1)
        }
    }
}

// MARK: - UIViewController 예제
class PuzzleCharactersViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupNavigationBar()
        setupCharacters()
    }
    
    private func setupBackground() {
        // 배경 그라데이션
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0).cgColor,
            UIColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupNavigationBar() {
        title = "퍼즐 친구들"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.label
        ]
    }
    
    private func setupCharacters() {
        let characters = PuzzleCharacter.allCases
        let charactersPerRow = 2
        let spacing: CGFloat = 20
        let characterSize: CGFloat = 150
        
        // 설명 라벨
        let descriptionLabel = UILabel()
        descriptionLabel.text = "귀여운 친구들을 터치해보세요!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.frame = CGRect(x: 0, y: 140, width: view.bounds.width, height: 30)
        view.addSubview(descriptionLabel)
        
        // 캐릭터들 배치
        for (index, character) in characters.enumerated() {
            let row = index / charactersPerRow
            let col = index % charactersPerRow
            
            let totalWidth = CGFloat(charactersPerRow) * characterSize + CGFloat(charactersPerRow - 1) * spacing
            let startX = (view.bounds.width - totalWidth) / 2
            
            let x = startX + CGFloat(col) * (characterSize + spacing)
            let y = 190 + CGFloat(row) * (characterSize + 60)
            
            let characterView = PuzzleCharacterImageUIView(character: character)
            characterView.frame = CGRect(x: x, y: y, width: characterSize, height: characterSize)
            view.addSubview(characterView)
            
            // 캐릭터 이름 라벨
            let nameLabel = UILabel()
            nameLabel.text = character.name
            nameLabel.textAlignment = .center
            nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            nameLabel.textColor = .label
            nameLabel.frame = CGRect(x: x, y: y + characterSize + 10, width: characterSize, height: 30)
            view.addSubview(nameLabel)
        }
    }
}


// MARK: - SwiftUI Preview
struct PuzzleCharactersMainView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleCharactersMainView()
            .environmentObject(MyPageViewModel())
    }
}
