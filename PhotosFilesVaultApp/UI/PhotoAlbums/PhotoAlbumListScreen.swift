import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.contentBack
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // TODO: Albums!

                }.ignoresSafeArea()
                
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

#Preview {
    let services = MockedServices.standard()
    
    PhotoAlbumListScreen(
        services: services
    )
}
