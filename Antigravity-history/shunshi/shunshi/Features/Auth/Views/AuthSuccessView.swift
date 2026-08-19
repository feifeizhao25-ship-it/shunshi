import SwiftUI

struct AuthSuccessView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated Success Icon
            ZStack {
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.shunshiPrimary)
                    .symbolEffect(.bounce, options: .repeating)
            }
            
            VStack(spacing: 12) {
                Text("开启自然之门")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.shunshiPrimary)
                
                Text("从此以后，你的养生之旅将与时俱进")
                    .font(AppTypography.body())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("开始探索")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.shunshiPrimary)
                    )
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
        .background(AppBackground.light.ignoresSafeArea())
    }
}

#Preview {
    AuthSuccessView(onDismiss: {})
}
