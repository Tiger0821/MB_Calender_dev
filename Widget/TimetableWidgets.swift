import SwiftUI
import WidgetKit

@main
struct TimetableWidgets: WidgetBundle {
    var body: some Widget {
        NowNextWidget()
        TodayWidget()
        HolidayWidget()
        ClassLiveActivity()
    }
}
