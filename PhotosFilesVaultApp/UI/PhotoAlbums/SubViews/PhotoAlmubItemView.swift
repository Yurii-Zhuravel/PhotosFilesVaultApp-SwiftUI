import SwiftUI

struct PhotoAlmubItemView: View {
    let folder: FolderModel
    let onAlbumPressed: ((FolderModel) -> Void)
    
    var body: some View {
        let cornerRadius: CGFloat = 12
        
        Button {
            onAlbumPressed(self.folder)
        } label: {
            RoundedRectangle(cornerRadius: cornerRadius)
                .foregroundColor(.albumBack)
                .overlay {
                    ZStack {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.secondaryAccent)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 20)
                                    .rotationEffect(Angle(degrees: 90))
                            }
                            Spacer(minLength: 0)
                        }.opacity(folder.isEditable ? 1 : 0)
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            ZStack {
                                Color.secondaryAccent
                                
                                Text(self.folder.name)
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
    let folder = FolderModel(path: "",
                             name: "Test 1",
                             items: [],
                             timeStamp: Date(),
                             thubnailPath: nil,
                             filesCount: 0,
                             foldersCount: 0,
                             isEditable: true)
    PhotoAlmubItemView(folder: folder,
                       onAlbumPressed: {_ in })
        .frame(width: 150, height: 150)
        .environment(\.colorScheme, .light)
}

#Preview("Dark mode long name") {
    let folder = FolderModel(path: "",
                             name: "Long name name name name name name name name name name name name name name name name name name name",
                             items: [],
                             timeStamp: Date(),
                             thubnailPath: nil,
                             filesCount: 0,
                             foldersCount: 0,
                             isEditable: true)
    PhotoAlmubItemView(folder: folder,
                       onAlbumPressed: {_ in })
        .frame(width: 150, height: 150)
        .environment(\.colorScheme, .dark)
}
