import Foundation
import Combine
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allReports: [CatReport] = []
    @Published var lostReports: [CatReport] = []
    @Published var foundReports: [CatReport] = []
    @Published var isLoading = false
    
    @Published var userLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        LocationManager.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.userLocation = location
            }
            .store(in: &cancellables)
    }
    
    func loadReports() {
        LocationManager.shared.requestLocation()
        Task {
            isLoading = true
            do {
                let reports = try await SupabaseManager.shared.getAllReportsAsync()
                self.allReports = reports.sorted { $0.date > $1.date }
                self.lostReports = self.allReports.filter { $0.reportType == "lost" }
                self.foundReports = self.allReports.filter { $0.reportType == "found" }
            } catch {
                print("Error loading reports: \(error)")
            }
            isLoading = false
        }
    }
}
