import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let barWidth: CGFloat
    let stepWidth: CGFloat
    
    var body: some View {
        ZStack {
            Capsule()
                .foregroundColor(.onboardingProgressBack)
            
            HStack(spacing: 0) {
                Capsule()
                    .foregroundColor(.onboardingProgressTint)
                    .frame(width: stepWidth * CGFloat(currentStep))
                Spacer(minLength: 0)
            }
        }.frame(width: barWidth, height: 8)
    }
}

#Preview {
    OnboardingProgressBar(
        currentStep: 2,
        barWidth: 210,
        stepWidth: 70
    )
}
