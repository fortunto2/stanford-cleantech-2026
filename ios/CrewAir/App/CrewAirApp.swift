import CrewKit
import SuperDuperAnalytics
import SwiftUI

@main
struct CrewAirApp: App {
    @State private var plan: PlanViewModel
    @State private var reports: ReportViewModel
    @State private var sky = SkyCheckModel(checker: LiveSkyChecker())
    @State private var heading = HeadingProvider()

    init() {
        // The counter: three events, an install-scoped UUID, nothing else. A debug build says
        // it is a machine so simulator runs never count as people (the flag rides on the event).
        #if DEBUG
        Analytics.configure(source: "crewair", automated: true)
        #else
        Analytics.configure(source: "crewair")
        #endif
        Analytics.track("app_launched")
        let service = LiveCrewService()
        let plan = PlanViewModel(service: service)
        _plan = State(initialValue: plan)
        _reports = State(initialValue: ReportViewModel(service: service, plan: plan))
    }

    var body: some Scene {
        WindowGroup {
            RootView(plan: plan, reports: reports, sky: sky, heading: heading)
        }
    }
}

struct RootView: View {
    enum Screen: Hashable { case plan, sky, report }

    let plan: PlanViewModel
    let reports: ReportViewModel
    let sky: SkyCheckModel
    let heading: HeadingProvider
    @State private var screen: Screen = .plan
    @State private var showGuide = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("guideSeen") private var guideSeen = false

    var body: some View {
        TabView(selection: $screen) {
            Tab("Plan", systemImage: "list.bullet.clipboard", value: .plan) {
                PlanView(model: plan, location: heading) { showGuide = true }
            }
            Tab("Sky", systemImage: "sun.horizon", value: .sky) {
                SkyView(response: plan.response, sky: sky, reports: reports, heading: heading) { screen = .plan }
            }
            Tab("Report", systemImage: "flag", value: .report) {
                ReportView(model: reports)
            }
        }
        .tint(screen == .sky ? Theme.skyInk : Theme.ink)
        // The design is one warm light theme; Sky darkens its own tab bar over the camera.
        .preferredColorScheme(.light)
        .sheet(isPresented: $showGuide) {
            GuideView { path in
                guideSeen = true
                showGuide = false
                // After the guide, ask once, so the first plan can be for where the phone is.
                heading.startLocation()
                if let path { reports.isLead = path == .employer }
            }
        }
        .task {
            if !guideSeen { showGuide = true } else { heading.startLocation() }
            reports.originProvider = { [heading] in heading.origin(cameraHeading: false) }
            await plan.load()
        }
        .onChange(of: plan.response?.place.name) { Task { await reports.refresh() } }
        .onChange(of: heading.location) {
            if let fix = heading.location?.coordinate { plan.located(lat: fix.latitude, lon: fix.longitude) }
        }
        // Location is asked for when it is first useful: after the guide, or on Sky or Report.
        .onChange(of: screen) { if screen != .plan { heading.startLocation() } }
        // Buffered events die with the process; the background edge is the moment to send them.
        .onChange(of: scenePhase) { if scenePhase == .background { Analytics.flush() } }
    }
}
