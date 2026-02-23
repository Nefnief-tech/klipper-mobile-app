package com.example.farm_manager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class StatusWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

        // Choose layout based on size
        val layoutId = if (minWidth < 150 || minHeight < 100) R.layout.widget_layout_small else R.layout.widget_layout
        
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, layoutId).apply {
            val name = widgetData.getString("printer_name", "No Printer")
            val status = widgetData.getString("printer_status", "OFFLINE")?.uppercase() ?: "OFFLINE"
            val fileName = widgetData.getString("current_file", "")
            val nozzle = widgetData.getString("nozzle_temp", "0")
            val bed = widgetData.getString("bed_temp", "0")
            val imagePath = widgetData.getString("image_path", null)

            setTextViewText(R.id.widget_printer_name, name?.uppercase() ?: "NO PRINTER")
            setTextViewText(R.id.widget_printer_status, status)
            
            val statusColor = when (status) {
                "PRINTING" -> Color.parseColor("#00E676")
                "PAUSED" -> Color.parseColor("#FFAB40")
                "COMPLETE" -> Color.parseColor("#448AFF")
                "ERROR" -> Color.parseColor("#FF5252")
                else -> Color.WHITE
            }
            setTextColor(R.id.widget_printer_status, statusColor)

            // These views might not exist in the small layout
            try { setTextViewText(R.id.widget_file_name, fileName ?: "") } catch(e: Exception) {}
            try { setTextViewText(R.id.widget_nozzle_temp, "${nozzle}°C") } catch(e: Exception) {}
            try { setTextViewText(R.id.widget_bed_temp, "${bed}°C") } catch(e: Exception) {}

            if (imagePath != null && File(imagePath).exists() && layoutId == R.layout.widget_layout) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                val roundedBitmap = getRoundedCornerBitmap(bitmap, 32) // Rounded corners
                setImageViewBitmap(R.id.widget_image, roundedBitmap)
                setViewVisibility(R.id.widget_image, View.VISIBLE)
            } else {
                try { setViewVisibility(R.id.widget_image, View.GONE) } catch(e: Exception) {}
            }

            val intent = Intent(context, MainActivity::class.java).apply { action = "SELECT_PRINTER" }
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getRoundedCornerBitmap(bitmap: Bitmap, pixels: Int): Bitmap {
        val output = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint()
        val rect = Rect(0, 0, bitmap.width, bitmap.height)
        val rectF = RectF(rect)
        val roundPx = pixels.toFloat()
        paint.isAntiAlias = true
        canvas.drawARGB(0, 0, 0, 0)
        canvas.drawRoundRect(rectF, roundPx, roundPx, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(bitmap, rect, rect, paint)
        return output
    }
}