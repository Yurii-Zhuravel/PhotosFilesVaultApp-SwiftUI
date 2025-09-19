import SwiftUI

struct AddPhotoTypeItemView: View {
    @Binding var isShowing: Bool
    let onImportPhotoVideoCallback: (() -> Void)
    let onAddNewFolderCallback: (() -> Void)
    
    var body: some View {
        ZStack {
            Color.contentBack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                    Button {
                        self.isShowing = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(Color.contentText)
                    }

                }
                Spacer(minLength: 10)
                
                VStack(spacing: 4) {
                    buildItemView(titleKey: "import_photo_video",
                                  iconName: "photo.stack",
                                  onCallback: onImportPhotoVideoCallback)
                    //self.separatorView
                    
                    buildItemView(titleKey: "add_new_folder",
                                  iconName: "folder.fill",
                                  onCallback: onAddNewFolderCallback)
                }//.background(Color.tabBarBack)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Spacer().frame(height: 20)
            }.padding(20)
        }
    }
    
    var separatorView: some View {
        Rectangle()
            .frame(height: 0.5)
            .foregroundColor(.contentText.opacity(0.6))
    }
    
    func buildItemView(titleKey: LocalizedStringKey,
                       iconName: String,
                       onCallback: @escaping (() -> Void)) -> some View {
        Button {
            onCallback()
        } label: {
            HStack(spacing: 0) {
                Spacer().frame(width: 10)
                
                Text(titleKey)
                    .foregroundColor(Color.contentText)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .regular))
                
                Spacer(minLength: 10)
                
                Circle()
                    .foregroundColor(Color.primaryAccent)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color.buttonText)
                            .clipped()
                            .padding(10)
                    ).padding(.vertical, 10)
                Spacer().frame(width: 10)
            }.background(Color.contentBack)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical, 5)
                .padding(.horizontal, 5)
                .shadow(color: .secondaryAccent.opacity(0.5),
                         radius: 2)
        }.contentShape(Rectangle())
    }
}

#Preview("Light mode") {
    AddPhotoTypeItemView(
        isShowing: .constant(true),
        onImportPhotoVideoCallback: {}, onAddNewFolderCallback: {}
    )
        .environment(\.colorScheme, .light)
        .background(Color.gray)
}
