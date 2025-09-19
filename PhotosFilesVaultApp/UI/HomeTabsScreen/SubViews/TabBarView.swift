import SwiftUI

/// Enum representing the various tabs in the TabBarView.
/// Each case corresponds to a specific section of the app.
///
enum TabItem: CaseIterable {
    case photos
    case settings
    
    /// Computes the image name associated with each tab.
    ///
    /// - Returns: A string representing the name of the image resource that corresponds to the tab.
    ///
    var sfImage: String {
        let resultIcon: String
        
        switch self {
        case .photos:
            resultIcon = "photo"
        case .settings:
            resultIcon = "gearshape"
        }
        return resultIcon
    }
    
    var title: String {
        let resultTitle: String
        
        switch self {
        case .photos:
            resultTitle = NSLocalizedString("photos", comment: "")
        case .settings:
            resultTitle = NSLocalizedString("settings", comment: "")
        }
        return resultTitle
    }
}

/// A view that represents a custom tab bar for the app.
///
/// The `TabBarView` allows the user to navigate between different sections of the app by selecting a tab. Each tab is represented by an icon and a label.
/// The currently selected tab is visually distinguished with a different color style.
///
struct TabBarView: View {
    //MARK: Variables
    @Binding var selectedTab: TabItem
    
    let impact = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        tabContent
    }
    
    //MARK: - UI Components
    private var tabContent: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { item in
                    Spacer()
                    tabBarButton(item: item)
                    Spacer()
                }
            }
            //.frame(width: Config.System.windowWidth, height: 80)
            .frame(height: 60)
            .background(.tabBarBack)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(.gray.opacity(0.2), lineWidth: 0.5)
                    .frame(height: 1)
                    .offset(y: -1)
            }
        }
    }
    
    /// Creates a tab button for each `TabItem` with an icon and label.
    ///
    /// - Parameter item: The `TabItem` that represents the current tab.
    ///
    private func tabBarButton(item: TabItem) -> some View {
        VStack(spacing: 5, content: {
            Image(systemName: item.sfImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(selectedTab == item ? .primaryAccent : .secondaryAccent)
            
            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedTab == item ? .primaryAccent : .secondaryAccent)
        })
        .frame(minWidth: 50)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = item
            impact.impactOccurred()
        }
        .animation(.easeIn(duration: 0.2), value: selectedTab)
    }
    
}

#Preview {
    TabBarView(selectedTab: .constant(TabItem.photos))
}
