import SwiftUI

struct OnboardingProgressBar: View {
    let numberOfSteps: Int
    let currentStep: Int
    let barWidth: CGFloat
    let stepWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 5) {
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
            
            Text("\(currentStep) / \(numberOfSteps)")
                .foregroundColor(Color.contentText)
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .regular))
        }
    }
}

#Preview {
    OnboardingProgressBar(
        numberOfSteps: 3,
        currentStep: 2,
        barWidth: 210,
        stepWidth: 70
    )
}
