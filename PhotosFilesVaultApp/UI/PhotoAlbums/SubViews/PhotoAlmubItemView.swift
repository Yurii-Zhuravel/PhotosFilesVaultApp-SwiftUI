import SwiftUI

struct PhotoAlmubItemView: View {
    let id: String
    let name: String
    let onAlbumPressed: ((String) -> Void)
    
    var body: some View {
        let cornerRadius: CGFloat = 12
        
        Button {
            onAlbumPressed(self.id)
        } label: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .foregroundColor(.albumBack)
                .overlay {
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            ZStack {
                                Color.secondaryAccent
                                
                                Text(self.name)
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
}

#Preview("Light mode") {
    PhotoAlmubItemView(id: "1",
                       name: "My favorite photos",
                       onAlbumPressed: {_ in })
        .frame(width: 150, height: 150)
        .environment(\.colorScheme, .light)
}

#Preview("Dark mode long name") {
    PhotoAlmubItemView(id: "1",
                       name: "Long name name name name name name name name name name name name name name name name name name name name name name name name name",
                       onAlbumPressed: {_ in })
        .frame(width: 150, height: 150)
        .environment(\.colorScheme, .dark)
}
