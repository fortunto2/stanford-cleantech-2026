import SwiftUI

@main
struct CrewAirApp: App {
    @State private var plan: PlanViewModel
    @State private var reports: ReportViewModel

    init() {
        let service = LiveCrewService()
        let plan = PlanViewModel(service: service)
        _plan = State(initialValue: plan)
        _reports = State(initialValue: ReportViewModel(service: service, plan: plan))
    }

    var body: some Scene {
        WindowGroup {
            RootView(plan: plan, reports: reports)
        }
    }
}

struct RootView: View {
    let plan: PlanViewModel
    let reports: ReportViewModel

    var body: some View {
        TabView {
            Tab("Plan", systemImage: "list.bullet.clipboard") {
                PlanView(model: plan)
            }
            Tab("Sky", systemImage: "camera.viewfinder") {
                SkyView(response: plan.response, checker: StubSkyChecker())
            }
            Tab("Report", systemImage: "exclamationmark.bubble") {
                ReportView(model: reports)
            }
        }
        .tint(Theme.accent)
        .task { await plan.load() }
    }
}
