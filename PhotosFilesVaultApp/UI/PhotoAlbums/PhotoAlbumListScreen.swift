import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.contentBack
                    .ignoresSafeArea()
                
                let contentPadding: CGFloat = 20
                
                VStack(spacing: 0) {
                    Spacer().frame(height: contentPadding)
                    
                    // TODO: Albums!
                    HStack {
                        PhotoAlmubItemView(name: "My favorite photos")
                            .frame(width: 150, height: 150)
                        Spacer()
                    }
                    Spacer()
                    
                    Spacer().frame(height: contentPadding)

                }.padding(.horizontal, contentPadding)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button {
                            // TODO:
                        } label: {
                            ZStack {
                                Circle()
                                    .foregroundColor(.accent)
                                Image(systemName: "plus")
                                    .font(.system(size: 34, weight: .regular))
                                    .foregroundColor(.accentText)
                            }.frame(width: 60, height: 60)
                        }.shadow(radius: 10)

                    }.padding(20)
                }.ignoresSafeArea()
            }.navigationTitle("photos")
                .navigationBarTitleDisplayMode(.inline)
//                .navigationDestination(for: HomeTabsNavigationRoutes.self) { route in
//                    switch route {
//                    case .photoAlbumList:
//                        PhotoAlbumListScreen(services: services)
//                    case .settings:
//                        SettingsScreen(services: services)
//                    }
//                }
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    PhotoAlbumListScreen(
        services: services
    )
}
