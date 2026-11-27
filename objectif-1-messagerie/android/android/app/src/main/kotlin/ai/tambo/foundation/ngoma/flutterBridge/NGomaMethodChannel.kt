package ai.tambo.foundation.ngoma.flutterBridge

import ai.tambo.foundation.ngoma.messaging.flutterBridge.MessagingMethodChannel
import io.flutter.embedding.engine.FlutterEngine

object NGomaMethodChannel {
    fun register(engine: FlutterEngine) {
        // Module 2 · Conversations et messages : com.ngoma/messaging
        MessagingMethodChannel.register(engine)
        // Module 1 (com.ngoma/account) et module 3 : à enregistrer ici par leurs binômes.
    }
}
