import Foundation
import Combine
import CoreLocation
import Supabase

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allReports: [CatReport] = []
    @Published var lostReports: [CatReport] = []
    @Published var foundReports: [CatReport] = []
    @Published var isLoading = false

    @Published var userLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?

    init() {
        LocationManager.shared.$userLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.userLocation = location
            }
            .store(in: &cancellables)
    }

    deinit {
        realtimeTask?.cancel()
    }

    // MARK: - Load reports (first load shows cached instantly, then refreshes)
    func loadReports() {
        LocationManager.shared.requestLocation()

        Task {
            // Only show skeleton on very first load (no data yet)
            if allReports.isEmpty { isLoading = true }

            do {
                let reports = try await SupabaseManager.shared.getAllReportsAsync()
                applyReports(reports)
            } catch {
                print("Error loading reports: \(error)")
            }
            isLoading = false

            // Start realtime after initial load
            startRealtimeSubscription()
        }
    }

    // MARK: - Optimistic insert — called right after user posts a new report
    func optimisticallyInsert(_ report: CatReport) {
        var updated = allReports
        // Avoid duplicates
        guard !updated.contains(where: { $0.id == report.id }) else { return }
        updated.insert(report, at: 0)
        applyReports(updated)
    }

    // MARK: - Realtime subscription so new reports from others appear live
    private func startRealtimeSubscription() {
        realtimeTask?.cancel()
        realtimeTask = Task {
            do {
                let channel = SupabaseManager.shared.client.realtimeV2.channel("public:reports")

                let changes = await channel.postgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "reports"
                )

                await channel.subscribe()

                for await change in changes {
                    guard !Task.isCancelled else { break }
                    switch change {
                    case .insert(let action):
                        if let newReport = try? action.decodeRecord(as: CatReport.self, decoder: .init()) {
                            if !self.allReports.contains(where: { $0.id == newReport.id }) {
                                var updated = self.allReports
                                updated.insert(newReport, at: 0)
                                self.applyReports(updated)
                            }
                        }
                    case .delete(let action):
                        if let old = try? action.decodeOldRecord(as: CatReport.self, decoder: .init()) {
                            let updated = self.allReports.filter { $0.id != old.id }
                            self.applyReports(updated)
                        }
                    case .update(let action):
                        if let updated = try? action.decodeRecord(as: CatReport.self, decoder: .init()) {
                            var list = self.allReports
                            if let idx = list.firstIndex(where: { $0.id == updated.id }) {
                                list[idx] = updated
                                self.applyReports(list)
                            }
                        }
                    }
                }
            } catch {
                print("Realtime subscription error: \(error)")
            }
        }
    }

    // MARK: - Apply sorted reports to all derived lists
    private func applyReports(_ reports: [CatReport]) {
        let sorted = reports.sorted { $0.date > $1.date }
        allReports = sorted
        lostReports = sorted.filter { $0.reportType == "lost" }
        foundReports = sorted.filter { $0.reportType == "found" }
    }
}
