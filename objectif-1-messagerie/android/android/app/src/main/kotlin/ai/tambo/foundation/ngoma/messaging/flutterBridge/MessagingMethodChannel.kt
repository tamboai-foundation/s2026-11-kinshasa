package ai.tambo.foundation.ngoma.messaging.flutterBridge

import ai.tambo.foundation.ngoma.flutterBridge.argBool
import ai.tambo.foundation.ngoma.flutterBridge.argLong
import ai.tambo.foundation.ngoma.flutterBridge.argLongList
import ai.tambo.foundation.ngoma.flutterBridge.argString
import ai.tambo.foundation.ngoma.messaging.controllers.MessagingController
import ai.tambo.foundation.ngoma.messaging.controllers.MessagingController.ConversationFilter
import ai.tambo.foundation.ngoma.messaging.controllers.MessagingException
import ai.tambo.foundation.ngoma.messaging.controllers.MessagingSignals
import ai.tambo.tmodeler.scheduler.TGate
import ai.tambo.tmodeler.scheduler.TmsScope
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object MessagingMethodChannel {

    private const val METHODS = "com.ngoma/messaging"
    private const val EVENTS = "com.ngoma/messaging/events"

    private var sink: EventChannel.EventSink? = null

    fun register(engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger
        MethodChannel(messenger, METHODS).setMethodCallHandler { call, result -> handle(call, result) }
        EventChannel(messenger, EVENTS).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                sink = events
                MessagingSignals.listener = { signal -> TGate.main { sink?.success(signal) } }
            }

            override fun onCancel(arguments: Any?) {
                sink = null
                MessagingSignals.listener = null
            }
        })
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        // Liste concernée (inbox:all, conversation:12…) : sert à retrouver la page suivante.
        val scope = call.argString("scope") ?: "background"
        when (call.method) {
            "getCapabilities" -> result.success(MessagingController.capabilities())

            // Historique des conversations
            "loadConversations" -> data(result) {
                MessagingController.loadConversations(
                    scope,
                    ConversationFilter(
                        service = call.argString("service"),
                        kind = call.argString("kind"),
                        search = call.argString("search"),
                        archived = call.argBool("archived") ?: false,
                        unreadOnly = call.argBool("unreadOnly") ?: false,
                    ),
                )
            }
            "loadMoreConversations" -> data(result) { MessagingController.loadMoreConversations(scope) }
            "getUnreadCount" -> data(result) { MessagingController.getUnreadCount() }
            "getUnreadCountsByKind" -> data(result) { MessagingController.getUnreadCountsByKind() }

            // Création / ouverture de conversations
            "openConversation" -> data(result) {
                MessagingController.openConversation(required(call, "conversationId"))
            }
            "resolveConversation" -> data(result) {
                MessagingController.resolveConversation(call.argString("reference") ?: "")
            }
            "openDirectConversation" -> data(result) {
                MessagingController.openDirectConversation(required(call, "recipientId"))
            }
            "searchRecipients" -> data(result) {
                MessagingController.searchRecipients(call.argString("query") ?: "")
            }

            // Messages : réception, envoi, modification, suppression
            "loadMessages" -> data(result) {
                MessagingController.loadMessages(scope, required(call, "conversationId"))
            }
            "loadMoreMessages" -> data(result) {
                MessagingController.loadMoreMessages(scope, required(call, "conversationId"))
            }
            "sendMessage" -> data(result) {
                MessagingController.sendMessage(
                    conversationId = required(call, "conversationId"),
                    text = call.argString("text") ?: "",
                    clientMessageId = call.argLong("clientMessageId"),
                    replyToId = call.argLong("replyToId"),
                    attachmentIds = call.argLongList("attachmentIds"),
                )
            }
            "editMessage" -> data(result) {
                MessagingController.editMessage(
                    conversationId = required(call, "conversationId"),
                    messageId = required(call, "messageId"),
                    text = call.argString("text") ?: "",
                )
            }
            "deleteMessage" -> data(result) {
                MessagingController.deleteMessage(
                    conversationId = required(call, "conversationId"),
                    messageId = required(call, "messageId"),
                    forEveryone = call.argBool("forEveryone") ?: false,
                )
                null
            }
            "markConversationRead" -> data(result) {
                MessagingController.markConversationRead(required(call, "conversationId"))
                null
            }

            // Appelées par l'écran même si la fonction est désactivée : on répond « rien ».
            "loadPeerStatus" -> result.success(emptyMap<String, Any?>()) // ni présence ni « écrit… »
            "setTyping", "saveDraft" -> result.success(null)
            "loadOutbox", "loadMoreOutbox" -> result.success(mapOf("items" to emptyList<Any>(), "hasMore" to false))
            "loadActiveCall" -> result.success(null)
            "getUnreadForSubject" -> result.success(0)

            // Non demandées par la fiche : fonctions désactivées.
            "reactToMessage", "forwardMessage", "setPinned", "setMuted", "setArchived",
            "setBlocked", "markConversationUnread", "reportConversation", "searchMessages",
            "prepareAttachment", "discardAttachment", "retryMessage",
            "sendCard", "performCardAction", "sendPoll", "votePoll", "sendPost", "openPostSpace",
            "startCall", "acceptCall", "declineCall", "endCall",
            "setCallMuted", "setCallCameraEnabled", "setCallSpeakerEnabled",
            -> result.error(MessagingException.FEATURE_DISABLED, "Hors périmètre du Module 1 : ${call.method}", null)

            else -> result.notImplemented()
        }
    }

    /** Lit un identifiant obligatoire (avec argLong, voir MethodCallArgs). */
    private fun required(call: MethodCall, key: String): Long =
        call.argLong(key) ?: throw MessagingException(MessagingException.INVALID_ARGS, "$key manquant")

    private fun data(result: MethodChannel.Result, block: context(TmsScope) () -> Any?) {
        TGate.data {
            val outcome = runCatching { block() }
            TGate.main {
                outcome.fold(
                    onSuccess = { value -> result.success(value) },
                    onFailure = { e ->
                        if (e is MessagingException) {
                            result.error(e.code, e.message, null)
                        } else {
                            result.error("MESSAGING_ERROR", e.message ?: e.javaClass.simpleName, null)
                        }
                    },
                )
            }
        }
    }
}
