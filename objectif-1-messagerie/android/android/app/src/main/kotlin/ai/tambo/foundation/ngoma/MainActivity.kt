package ai.tambo.foundation.ngoma

import ai.tambo.foundation.ngoma.flutterBridge.NGomaMethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NGomaMethodChannel.register(flutterEngine)
    }
}
