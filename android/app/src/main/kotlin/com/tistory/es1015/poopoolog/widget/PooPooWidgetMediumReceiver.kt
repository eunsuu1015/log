package com.tistory.es1015.poopoolog.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/// 홈 화면 위젯 2×1 리시버. PooPooWidget의 Responsive 레이아웃이 크기를 처리한다.
class PooPooWidgetMediumReceiver : HomeWidgetGlanceWidgetReceiver<PooPooWidget>() {
    override val glanceAppWidget = PooPooWidget()
}
