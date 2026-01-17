package com.example.farm_manager

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class StatusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val printingCount = widgetData.getInt("printing_count", 0)
                val idleCount = widgetData.getInt("idle_count", 0)
                
                setTextViewText(R.id.widget_printing, "Printing: $printingCount")
                setTextViewText(R.id.widget_idle, "Idle: $idleCount")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
