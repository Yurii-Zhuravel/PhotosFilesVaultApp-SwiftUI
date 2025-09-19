import SwiftUI

struct PhotoAlmubItemView: View {
    let name: String
    
    var body: some View {
        let cornerRadius: CGFloat = 12
        
        RoundedRectangle(cornerRadius: cornerRadius)
            .foregroundColor(.secondaryAccent.opacity(0.2))
            .overlay {
                ZStack {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        ZStack {
                            Color.secondaryAccent
                            
                            Text(name)
                                .foregroundColor(Color.albumText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 0)
                        }
                            .frame(height: 38)
                    }
                }.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .clipped()
    }
}

#Preview("Light mode") {
    PhotoAlmubItemView(name: "My favorite photos")
        .frame(width: 150, height: 150)
        .environment(\.colorScheme, .light)
}

#Preview("Dark mode long name") {
    PhotoAlmubItemView(name: "Long name name name name name name name name name name name name name name name name name name name name name name name name name")
        .frame(width: 150, height: 150)
        .environment(\.colorScheme, .dark)
}
