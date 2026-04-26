package com.example.pikmin_postcard_book

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "postcard_actions"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openBlueMap" -> {
                    val lat = call.argument<Double>("lat")
                    val lng = call.argument<Double>("lng")

                    if (lat == null || lng == null) {
                        result.error("INVALID_ARGS", "缺少座標參數。", null)
                        return@setMethodCallHandler
                    }

                    try {
                        openBlueMap(lat, lng)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error(
                            "BLUEMAP_ERROR",
                            error.message ?: "無法開啟藍色地圖。",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openBlueMap(lat: Double, lng: Double) {
        val receiverIntent = Intent("com.xmap.bluemap.TELEPORT").apply {
            component = ComponentName(
                "com.xmap.bluemap",
                "com.xmap.bluemap.remote.RemoteControlReceiver"
            )
            putExtra("lat", lat.toFloat())
            putExtra("lng", lng.toFloat())
        }

        sendBroadcast(receiverIntent)

        val launchIntent = packageManager.getLaunchIntentForPackage("com.xmap.bluemap")
            ?: throw IllegalStateException("找不到藍色地圖 App。")

        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(launchIntent)
    }
}
