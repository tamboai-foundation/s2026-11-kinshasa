package ai.tambo.foundation.ngoma.messaging.controllers

object MessagingSignals {
    const val CONVERSATIONS = "conversations"
    const val UNREAD = "unread"

    fun messages(conversationId: Long) = "messages:$conversationId"

    @Volatile
    var listener: ((String) -> Unit)? = null

    fun emit(signal: String) {
        listener?.invoke(signal)
    }
}
