import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    let bottomTabBarHeight: CGFloat
    
    @State private var navigationPath = NavigationPath()
    @State private var isShowingAddingSheet = false
    
    // TODO: ----
    @State private var items: [AlbumItem] = [
        AlbumItem(id: "1", name: "My favorite photos"),
        AlbumItem(id: "2", name: "My car"),
        AlbumItem(id: "3", name: "Family photos"),
        AlbumItem(id: "4", name: "Test 1"),
        AlbumItem(id: "5", name: "Test 2"),
        AlbumItem(id: "6", name: "Test 3"),
        AlbumItem(id: "7", name: "Test 4"),
        AlbumItem(id: "8", name: "Test 5"),
        AlbumItem(id: "9", name: "Test 6"),
        AlbumItem(id: "10", name: "Test 7"),
        AlbumItem(id: "11", name: "Test 9"),
    ]
    private struct AlbumItem: Identifiable {
        let id: String
        let name: String
    }
    // ----------
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    let contentPadding: CGFloat = 20
                    let itemsPadding: CGFloat = 20
                    let itemSize: CGFloat = (geometry.size.width - contentPadding * 3.0 - itemsPadding) / 2.0
                    let adjustedPositiveItemSize = (itemSize >= 0) ? itemSize : 0
                    
                    buildContent(contentPadding: contentPadding,
                                 adjustedPositiveItemSize: adjustedPositiveItemSize,
                                 itemsPadding: itemsPadding)
                        .padding(.horizontal, contentPadding)
                        .ignoresSafeArea(edges: .bottom)
                        .bottomSafeAreaPadding(tabBarHeight:  self.bottomTabBarHeight)
                    
                    buildBottomButtonAdd(contentPadding: contentPadding)
                        .padding(.horizontal, contentPadding)
                        .ignoresSafeArea(edges: .bottom)
                        .bottomSafeAreaPadding(tabBarHeight:  self.bottomTabBarHeight)
                    
                }.ignoresSafeArea(edges: .bottom)
                    .navigationTitle("photos")
                    .navigationBarTitleDisplayMode(.inline)
    //                .navigationDestination(for: HomeTabsNavigationRoutes.self) { route in
    //                    switch route {
    //                    case .photoAlbumList:
    //                        PhotoAlbumListScreen(services: services)
    //                    case .settings:
    //                        SettingsScreen(services: services)
    //                    }
    //                }
                    .sheet(isPresented: $isShowingAddingSheet) {
                        AddPhotoTypeItemView(
                            isShowing: $isShowingAddingSheet,
                            onImportPhotoVideoCallback: {
                                // TODO:
                                print("!!! AAA onImportPhotoVideoCallback")
                                self.isShowingAddingSheet = false
                            }, onAddNewFolderCallback: {
                                // TODO:
                                print("!!! AAA onAddNewFolderCallback")
                                self.isShowingAddingSheet = false
                            }
                        )
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                    }
            }
        }
    }
    
    var placeholderView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("__No items___")
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func buildContent(contentPadding: CGFloat,
                              adjustedPositiveItemSize: CGFloat,
                              itemsPadding: CGFloat) -> some View {
        if self.items.isEmpty {
            self.placeholderView
        } else {
            ScrollView {
                Spacer().frame(height: contentPadding)
                
                LazyVGrid(columns: gridColumns,
                          spacing: itemsPadding) {
                    ForEach(items) { item in
                        PhotoAlmubItemView(name: item.name)
                            .frame(width: adjustedPositiveItemSize,
                                   height: adjustedPositiveItemSize)
                    }
                }
                
                Spacer().frame(height: contentPadding)
            }
        }
    }
    
    private func buildBottomButtonAdd(contentPadding: CGFloat) -> some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                Button {
                    self.isShowingAddingSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .foregroundColor(.accent)
                        Image(systemName: "plus")
                            .font(.system(size: 34, weight: .regular))
                            .foregroundColor(.buttonText)
                    }.frame(width: 60, height: 60)
                        .contentShape(Rectangle())
                }.shadow(color: .secondaryAccent.opacity(0.7),
                         radius: 8)
                .contentShape(Rectangle())

            }
            Spacer().frame(height: contentPadding)
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    PhotoAlbumListScreen(
        services: services,
        bottomTabBarHeight: 60
    )
}
