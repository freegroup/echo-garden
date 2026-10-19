package com.example.echo_garden

import android.content.Context
import android.view.InputDevice
import android.view.MotionEvent
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var exploreTouchSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "echo_garden/explore_touch")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    exploreTouchSink = events
                }

                override fun onCancel(arguments: Any?) {
                    exploreTouchSink = null
                }
            })
    }

    // With TalkBack on, a finger moved over the screen does not arrive as touch
    // events but as hover events (touch exploration). Flutter hands those only
    // to its accessibility bridge, so the game never sees them. Here they are
    // also sent to Dart, so one finger can steer the player with TalkBack on.
    // The events still go on to Flutter, so TalkBack keeps working as usual.
    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        val sink = exploreTouchSink
        if (sink != null && isTouchExplorationOn() &&
            event.isFromSource(InputDevice.SOURCE_TOUCHSCREEN)
        ) {
            val kind = when (event.actionMasked) {
                MotionEvent.ACTION_HOVER_ENTER -> "start"
                MotionEvent.ACTION_HOVER_MOVE -> "move"
                MotionEvent.ACTION_HOVER_EXIT -> "end"
                else -> null
            }
            if (kind != null) {
                // Flutter works in logical pixels
                val density = resources.displayMetrics.density
                sink.success(mapOf("kind" to kind, "x" to event.x / density, "y" to event.y / density))
            }
        }
        return super.dispatchGenericMotionEvent(event)
    }

    private fun isTouchExplorationOn(): Boolean {
        val manager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        return manager.isTouchExplorationEnabled
    }
}
