import SwiftUI

struct SplashScreenView: View {
    @State private var showMain = false
    @State private var fadeIn = false

    var body: some View {
        ZStack {
            if showMain {
                MainTabView()
                    .transition(.opacity)
            } else {
                // Bakgrunn
                LinearGradient(
                    colors: [
                        Color(hex: "#20202A"),
                        Color(hex: "#FF9B52")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Bruker appikonet fra Assets
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .cornerRadius(32)
                        .shadow(radius: 10)
                        .opacity(fadeIn ? 1 : 0)
                        .scaleEffect(fadeIn ? 1 : 0.8)
                        .animation(.easeInOut(duration: 1), value: fadeIn)

                    Text("Beacon")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .opacity(fadeIn ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(0.2), value: fadeIn)
                }
            }
        }
        .onAppear {
            fadeIn = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showMain = true }
            }
        }
    }
}
