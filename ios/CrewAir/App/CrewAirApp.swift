import CrewKit
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
    enum Screen: Hashable { case plan, sky, report }

    let plan: PlanViewModel
    let reports: ReportViewModel
    @State private var screen: Screen = .plan

    var body: some View {
        TabView(selection: $screen) {
            Tab("Plan", systemImage: "list.bullet.clipboard", value: .plan) {
                PlanView(model: plan)
            }
            Tab("Sky", systemImage: "sun.horizon", value: .sky) {
                SkyView(response: plan.response, checker: StubSkyChecker()) {
                    reports.selected = .smoke
                    reports.isLead = false
                    screen = .report
                }
            }
            Tab("Report", systemImage: "flag", value: .report) {
                ReportView(model: reports)
            }
        }
        .tint(screen == .sky ? Theme.skyInk : Theme.ink)
        // The design is one warm light theme; Sky darkens its own tab bar over the camera.
        .preferredColorScheme(.light)
        .task { await plan.load() }
        .onChange(of: plan.response?.place.name) { Task { await reports.refresh() } }
    }
}
