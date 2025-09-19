import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    let bottomTabBarHeight: CGFloat
    
    @State private var navigationPath = NavigationPath()
    @State private var isShowingAddingSheet = false
    
    @StateObject private var viewModel = VaultViewModel()

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
                    .navigationDestination(for: PhotoAlbumNavigationRoutes.self) { route in
                        switch route {
                        case .photosList(let folder):
                            PhotosListScreen(
                                services: services,
                                folder: folder,
                                navigationPath: $navigationPath
                            )
                        }
                    }
                    .sheet(isPresented: $isShowingAddingSheet) {
                        AddPhotoTypeItemView(
                            isShowing: $isShowingAddingSheet,
                            onImportPhotoVideoCallback: {
                                // TODO:
                                print("!!! AAA onImportPhotoVideoCallback")
                                self.isShowingAddingSheet = false
                            }, onAddNewFolderCallback: {
                                let newFolderName = "Test Folder"
                                guard !newFolderName.isEmpty
                                else {
                                    self.isShowingAddingSheet = false
                                    return
                                }
                                viewModel.craeteNewFolder(name: newFolderName)
                                self.isShowingAddingSheet = false
                            }
                        )
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                    }.onAppear {
                        viewModel.fetchSubfolders()
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
        if self.viewModel.showsLoading {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.primaryAccent)
                Spacer()
            }
            
        } else if self.viewModel.subfolders.isEmpty {
            self.placeholderView
            
        } else {
            ScrollView {
                Spacer().frame(height: contentPadding)
                
                LazyVGrid(columns: gridColumns,
                          spacing: itemsPadding) {
                    ForEach(viewModel.subfolders, id: \.self) { folder in
                        PhotoAlmubItemView(
                            folder: folder,
                            onAlbumPressed: { albumId in
                                // TODO: !!!
                                /*
                                if let album = self.items.first(where: { $0.id == albumId }) {
                                    let newPath = PhotoAlbumNavigationRoutes.photosList(album)
                                    self.navigationPath.append(newPath)
                                } else {
                                    print("PhotoAlbumListScreen: Can't find album with id: \(albumId)")
                                }
                                 */
                            }
                        ).frame(width: adjustedPositiveItemSize,
                                height: adjustedPositiveItemSize)
                        .contextMenu {
                            if folder.isEditable {
                                Button {
                                    // TODO:
                                } label: {
                                    Label("edit_name", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    viewModel.deleteFolder(folder)
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                        } preview: {
                            // 👇 This defines what appears during the "lift-off" animation
                            PhotoAlmubItemView(
                                folder: folder,
                                onAlbumPressed: { _ in }
                            ).frame(width: adjustedPositiveItemSize,
                                    height: adjustedPositiveItemSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }.id(viewModel.refreshTrigger)
                
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
