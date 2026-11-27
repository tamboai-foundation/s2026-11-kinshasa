package ai.tambo.foundation.ngoma.messaging.controllers

import ai.tambo.foundation.ngoma.messaging.models.Conversation
import ai.tambo.foundation.ngoma.messaging.models.Message
import ai.tambo.foundation.ngoma.messaging.models.Participant
import ai.tambo.foundation.ngoma.users.models.Session
import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.operation.*
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.ext.*
import ai.tambo.tmodeler.scheduler.TmsScope
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toInstant
import kotlinx.datetime.toLocalDateTime

object MessagingController {

    const val CONVERSATIONS_PAGE = 20
    const val MESSAGES_PAGE = 30
    const val RECIPIENTS_PAGE = 30
    const val MAX_TEXT_LENGTH = 4000

    val FEATURES = listOf("newConversation", "edit", "deleteForEveryone", "copy")

    /** Filtres demandés par l'écran pour la liste des conversations. */
    data class ConversationFilter(
        val service: String? = null,
        val kind: String? = null,
        val search: String? = null,
        val archived: Boolean = false,
        val unreadOnly: Boolean = false,
    )

    private class ConversationCursor(val filter: ConversationFilter, var offset: Int)

    private val conversationCursors = mutableMapOf<String, ConversationCursor>()

    /** Plus ancien message déjà envoyé à l'écran, par scope et conversation. */
    private val messageCursors = mutableMapOf<String, Long>()

    // ─── Capacités ──────────────────────────────────────────────────────────

    fun capabilities(): Map<String, Any?> = mapOf(
        "features" to FEATURES,
        "reactions" to emptyList<String>(),
        "editWindowSeconds" to null,
        "maxAttachmentBytes" to null,
        "maxTextLength" to MAX_TEXT_LENGTH,
    )

    // ─── Boîte de réception (historique des conversations) ─────────────────

    context(_: TmsScope)
    fun loadConversations(scope: String, filter: ConversationFilter): Map<String, Any?> {
        val cursor = ConversationCursor(filter, 0)
        conversationCursors[scope] = cursor
        return conversationsPage(cursor)
    }

    context(_: TmsScope)
    fun loadMoreConversations(scope: String): Map<String, Any?> {
        val cursor = conversationCursors[scope] ?: return page(emptyList(), false)
        return conversationsPage(cursor)
    }

    context(_: TmsScope)
    private fun conversationsPage(cursor: ConversationCursor): Map<String, Any?> {
        val me = me()
        val kind = when (cursor.filter.kind) {
            null -> null
            "direct" -> Conversation.Kind.DIRECT
            "group" -> Conversation.Kind.GROUP
            else -> return page(emptyList(), false) // pas de canaux
        }
        val ids = myConversationIds(me, cursor.filter)
        if (ids.isEmpty()) return page(emptyList(), false)
        val c = Conversation.tms.lambda
        val condition = if (kind == null) (c._id into ids) else (c._id into ids) and (c.kind eq kind)
        val items = Conversation.tms.with(c).lazy()
            .filter(condition)
            .order(-c.lastMessageAt)
            .sub(CONVERSATIONS_PAGE, cursor.offset)
            .build()
            .toList()
        cursor.offset += items.size
        return page(items.map { conversationDto(it, me) }, items.size >= CONVERSATIONS_PAGE)
    }

    context(_: TmsScope)
    private fun myConversationIds(me: User, filter: ConversationFilter): List<Long> {
        // Pas d'archives ni de conversations de service (non demandé).
        if (filter.archived) return emptyList()
        if (filter.service != null && filter.service != "other") return emptyList()
        var conversations = myParticipations(me).map { it.conversation_ }
        val search = filter.search?.trim().orEmpty()
        if (search.isNotEmpty()) {
            val matching = usersMatching(search, me).map { localId(it) }.toSet()
            conversations = conversations.filter { conversation ->
                conversation.title_.contains(search, ignoreCase = true) ||
                    otherParticipants(conversation, me).any { localId(it.user_) in matching }
            }
        }
        if (filter.unreadOnly) conversations = conversations.filter { unreadCount(it, me) > 0 }
        return conversations.map { localId(it) }
    }

    context(_: TmsScope)
    fun getUnreadCount(): Long {
        val me = me()
        return myParticipations(me).sumOf { unreadCount(it.conversation_, me) }
    }

    /** Non lus par sorte de conversation (onglets Privées / Groupes). */
    context(_: TmsScope)
    fun getUnreadCountsByKind(): Map<String, Any?> {
        val me = me()
        var direct = 0L
        var group = 0L
        for (participation in myParticipations(me)) {
            val conversation = participation.conversation_
            val unread = unreadCount(conversation, me)
            if (conversation.kind_ == Conversation.Kind.GROUP) group += unread else direct += unread
        }
        return mapOf("direct" to direct, "group" to group, "channel" to 0L)
    }

    // ─── Ouvrir / créer une conversation ───────────────────────────────────

    context(_: TmsScope)
    fun openConversation(conversationId: Long): Map<String, Any?> {
        val me = me()
        val conversation = conversationOf(conversationId, me)
        return conversationDto(conversation, me)
    }

    /** Ouvre une conversation depuis une référence : ici, son identifiant en texte. */
    context(_: TmsScope)
    fun resolveConversation(reference: String): Map<String, Any?> {
        val id = reference.trim().toLongOrNull()
            ?: throw MessagingException(MessagingException.CONVERSATION_NOT_FOUND, "Conversation introuvable")
        return openConversation(id)
    }

    context(_: TmsScope)
    fun openDirectConversation(recipientId: Long): Map<String, Any?> {
        val me = me()
        val recipient = userById(recipientId)
        if (recipient == null || recipient.deletedAt_ != null || localId(recipient) == localId(me)) {
            throw MessagingException(MessagingException.RECIPIENT_NOT_FOUND, "Destinataire introuvable")
        }
        val existing = myParticipations(me)
            .map { it.conversation_ }
            .firstOrNull { conversation ->
                conversation.kind_ == Conversation.Kind.DIRECT &&
                    participantsOf(conversation).any { localId(it.user_) == recipientId }
            }
        if (existing != null) return conversationDto(existing, me)

        val now = now()
        val conversation = Conversation().apply {
            kind_ = Conversation.Kind.DIRECT
            title_ = ""
            createdBy_ = me
            createdAt_ = now
        }
        conversation.save()
        for (user in listOf(me, recipient)) {
            Participant().apply {
                conversation_ = conversation
                user_ = user
                joinedAt_ = now
            }.save()
        }
        MessagingSignals.emit(MessagingSignals.CONVERSATIONS)
        return conversationDto(conversation, me)
    }

    /** Destinataires pour « Nouvelle conversation » : comptes actifs, sauf moi. */
    context(_: TmsScope)
    fun searchRecipients(query: String): Map<String, Any?> {
        val me = me()
        val users = usersMatching(query.trim(), me)
        return page(
            users.map { user ->
                mapOf(
                    "id" to localId(user),
                    "displayName" to user.name_,
                    "subtitle" to user.bio_.ifBlank { null },
                    "avatar" to null,
                )
            },
            false,
        )
    }

    // ─── Messages ───────────────────────────────────────────────────────────

    /** Dernière page de la conversation, du plus ancien au plus récent. */
    context(_: TmsScope)
    fun loadMessages(scope: String, conversationId: Long): Map<String, Any?> {
        val me = me()
        val conversation = conversationOf(conversationId, me)
        val m = Message.tms.lambda
        val items = Message.tms.with(m).lazy()
            .filter(m.conversation eq conversation)
            .order(-m._id)
            .sub(MESSAGES_PAGE, 0)
            .build()
            .toList()
            .reversed()
        rememberOldest(scope, conversationId, items)
        return page(items.map { messageDto(it, me) }, items.size >= MESSAGES_PAGE)
    }

    /** Page plus ancienne que celle déjà affichée (curseur sur l'identifiant). */
    context(_: TmsScope)
    fun loadMoreMessages(scope: String, conversationId: Long): Map<String, Any?> {
        val me = me()
        val conversation = conversationOf(conversationId, me)
        val oldest = messageCursors[cursorKey(scope, conversationId)] ?: return page(emptyList(), false)
        val m = Message.tms.lambda
        val items = Message.tms.with(m).lazy()
            .filter((m.conversation eq conversation) and (m._id lt oldest))
            .order(-m._id)
            .sub(MESSAGES_PAGE, 0)
            .build()
            .toList()
            .reversed()
        rememberOldest(scope, conversationId, items)
        return page(items.map { messageDto(it, me) }, items.size >= MESSAGES_PAGE)
    }

    context(_: TmsScope)
    fun sendMessage(
        conversationId: Long,
        text: String,
        clientMessageId: Long?,
        replyToId: Long?,
        attachmentIds: List<Long>,
    ): Map<String, Any?> {
        val me = me()
        val conversation = conversationOf(conversationId, me)
        if (replyToId != null || attachmentIds.isNotEmpty()) {
            throw MessagingException(MessagingException.FEATURE_DISABLED, "Réponses et pièces jointes : hors Module 1")
        }
        if (!canSend(conversation, me)) {
            throw MessagingException(MessagingException.SEND_FORBIDDEN, "Impossible d'écrire dans cette conversation")
        }
        val content = validText(text)

        if (clientMessageId != null && clientMessageId != 0L) {
            val m = Message.tms.lambda
            val already = Message.tms.with(m).lazy()
                .filter(
                    (m.conversation eq conversation) and (m.sender eq me) and
                        (m.clientMessageId eq clientMessageId),
                )
                .sub(1, 0)
                .build()
                .toList()
                .firstOrNull()
            if (already != null) return messageDto(already, me)
        }

        val now = now()
        val message = Message().apply {
            conversation_ = conversation
            sender_ = me
            content_ = content
            sentAt_ = now
            clientMessageId_ = clientMessageId ?: 0L
        }
        message.save()

        conversation.lastMessageAt_ = now
        conversation.update()
        // Mon propre message ne compte pas comme non lu pour moi.
        participationOf(conversation, me)?.let {
            it.lastReadAt_ = now
            it.update()
        }
        MessagingSignals.emit(MessagingSignals.messages(conversationId))
        MessagingSignals.emit(MessagingSignals.CONVERSATIONS)
        MessagingSignals.emit(MessagingSignals.UNREAD)
        return messageDto(message, me)
    }

    /** Seul l'expéditeur modifie son message, s'il n'est pas supprimé. */
    context(_: TmsScope)
    fun editMessage(conversationId: Long, messageId: Long, text: String): Map<String, Any?> {
        val me = me()
        val conversation = conversationOf(conversationId, me)
        val message = myEditableMessage(conversation, messageId, me)
        message.content_ = validText(text)
        message.editedAt_ = now()
        message.update()
        MessagingSignals.emit(MessagingSignals.messages(conversationId))
        MessagingSignals.emit(MessagingSignals.CONVERSATIONS)
        return messageDto(message, me)
    }

    context(_: TmsScope)
    fun deleteMessage(conversationId: Long, messageId: Long, forEveryone: Boolean) {
        if (!forEveryone) {
            throw MessagingException(MessagingException.FEATURE_DISABLED, "Supprimer pour moi : hors Module 1")
        }
        val me = me()
        val conversation = conversationOf(conversationId, me)
        val message = myEditableMessage(conversation, messageId, me)
        message.deletedAt_ = now()
        message.content_ = ""
        message.update()
        MessagingSignals.emit(MessagingSignals.messages(conversationId))
        MessagingSignals.emit(MessagingSignals.CONVERSATIONS)
        MessagingSignals.emit(MessagingSignals.UNREAD)
    }

    /** Ouvrir la conversation met lastReadAt à maintenant : plus de non lus. */
    context(_: TmsScope)
    fun markConversationRead(conversationId: Long) {
        val me = me()
        val conversation = conversationOf(conversationId, me)
        val participation = participationOf(conversation, me) ?: return
        participation.lastReadAt_ = now()
        participation.update()
        MessagingSignals.emit(MessagingSignals.UNREAD)
        MessagingSignals.emit(MessagingSignals.CONVERSATIONS)
    }

    // ─── Lectures internes ─────────────────────────────────────────────────

    /** L'utilisateur connecté (lu dans Session, rempli par le module 1). */
    context(_: TmsScope)
    private fun me(): User {
        val s = Session.tms.lambda
        val session = Session.tms.with(s).lazy().order(-s._id).sub(1, 0).build().toList().firstOrNull()
        val user: User? = if (session != null && session.currentUser.available()) session.currentUser_ else null
        if (user == null || user.deletedAt_ != null) {
            throw MessagingException(MessagingException.NOT_AUTHENTICATED, "Aucun utilisateur connecté")
        }
        return user
    }

    context(_: TmsScope)
    private fun userById(id: Long): User? {
        val u = User.tms.lambda
        return User.tms.with(u).lazy().filter(u._id eq id).sub(1, 0).build().toList().firstOrNull()
    }

    /** Comptes actifs (sauf moi) dont le nom contient [query]. */
    context(_: TmsScope)
    private fun usersMatching(query: String, me: User): List<User> {
        val u = User.tms.lambda
        val active = (u.deletedAt eq null) and (u._id ne localId(me))
        val condition = if (query.isEmpty()) active else active and (u.name like "%$query%")
        return User.tms.with(u).lazy().filter(condition).order(+u.name).sub(RECIPIENTS_PAGE, 0).build().toList()
    }

    context(_: TmsScope)
    private fun myParticipations(me: User): List<Participant> {
        val p = Participant.tms.lambda
        return Participant.tms.with(p).lazy().filter(p.user eq me).build().toList()
            .filter { it.conversation.available() }
    }

    context(_: TmsScope)
    private fun participantsOf(conversation: Conversation): List<Participant> {
        val p = Participant.tms.lambda
        return Participant.tms.with(p).lazy().filter(p.conversation eq conversation).build().toList()
            .filter { it.user.available() }
    }

    context(_: TmsScope)
    private fun otherParticipants(conversation: Conversation, me: User): List<Participant> =
        participantsOf(conversation).filter { localId(it.user_) != localId(me) }

    context(_: TmsScope)
    private fun participationOf(conversation: Conversation, me: User): Participant? {
        val p = Participant.tms.lambda
        return Participant.tms.with(p).lazy()
            .filter((p.conversation eq conversation) and (p.user eq me))
            .sub(1, 0)
            .build()
            .toList()
            .firstOrNull()
    }

    /** Vérifie que la conversation existe et que j'en fais partie. */
    context(_: TmsScope)
    private fun conversationOf(conversationId: Long, me: User): Conversation {
        val c = Conversation.tms.lambda
        val conversation = Conversation.tms.with(c).lazy().filter(c._id eq conversationId)
            .sub(1, 0).build().toList().firstOrNull()
        if (conversation == null || participationOf(conversation, me) == null) {
            throw MessagingException(MessagingException.CONVERSATION_NOT_FOUND, "Conversation introuvable")
        }
        return conversation
    }

    context(_: TmsScope)
    private fun myEditableMessage(conversation: Conversation, messageId: Long, me: User): Message {
        val m = Message.tms.lambda
        val message = Message.tms.with(m).lazy()
            .filter((m._id eq messageId) and (m.conversation eq conversation))
            .sub(1, 0)
            .build()
            .toList()
            .firstOrNull()
            ?: throw MessagingException(MessagingException.MESSAGE_NOT_FOUND, "Message introuvable")
        if (localId(message.sender_) != localId(me) || message.deletedAt_ != null) {
            throw MessagingException(MessagingException.ACTION_NOT_ALLOWED, "Seul l'auteur modifie ou supprime son message")
        }
        return message
    }

    context(_: TmsScope)
    private fun unreadCount(conversation: Conversation, me: User): Long {
        val lastReadAt = participationOf(conversation, me)?.lastReadAt_
        val m = Message.tms.lambda
        var condition = (m.conversation eq conversation) and (m.sender ne me) and (m.deletedAt eq null)
        if (lastReadAt != null) condition = condition and (m.sentAt gt lastReadAt)
        return Message.tms.with(m).lazy().filter(condition).build().toList().size.toLong()
    }

    context(_: TmsScope)
    private fun lastMessage(conversation: Conversation): Message? {
        val m = Message.tms.lambda
        return Message.tms.with(m).lazy().filter(m.conversation eq conversation)
            .order(-m._id).sub(1, 0).build().toList().firstOrNull()
    }

    /** En DIRECT, on ne peut plus écrire à un compte supprimé. */
    context(_: TmsScope)
    private fun canSend(conversation: Conversation, me: User): Boolean {
        if (participationOf(conversation, me) == null) return false
        if (conversation.kind_ != Conversation.Kind.DIRECT) return true
        val other = otherParticipants(conversation, me).firstOrNull()?.user_ ?: return false
        return other.deletedAt_ == null
    }

    // ─── Données envoyées à l'écran ────────────────────────────────────────

    context(_: TmsScope)
    private fun conversationDto(conversation: Conversation, me: User): Map<String, Any?> {
        val others = otherParticipants(conversation, me).map { it.user_ }
        val isGroup = conversation.kind_ == Conversation.Kind.GROUP
        val peer = if (isGroup) null else others.firstOrNull()
        val title = when {
            isGroup -> conversation.title_
            peer == null -> "Conversation"
            else -> displayName(peer)
        }
        val subtitle = when {
            isGroup -> "${others.size + 1} participants"
            peer == null || peer.deletedAt_ != null -> ""
            else -> peer.bio_
        }
        val last = lastMessage(conversation)
        val lastIsMine = last != null && localId(last.sender_) == localId(me)
        return mapOf(
            "id" to localId(conversation),
            "service" to "other",
            "kind" to if (isGroup) "group" else "direct",
            "peerId" to peer?.let { localId(it) },
            "title" to title,
            "subtitle" to subtitle,
            "avatar" to null,
            "lastMessage" to last?.let { if (it.deletedAt_ != null) "Message supprimé" else it.content_ },
            "lastMessageAt" to last?.let { iso(it.sentAt_) },
            "lastMessageIsMine" to lastIsMine,
            "lastMessageDelivery" to if (lastIsMine) "sent" else null,
            "unreadCount" to unreadCount(conversation, me),
            "isMarkedUnread" to false,
            "isMuted" to false,
            "isArchived" to false,
            "isPinned" to false,
            "isBlocked" to false,
            "draft" to null,
            "canSend" to canSend(conversation, me),
            "quickReplies" to emptyList<String>(),
            "maxTextLength" to MAX_TEXT_LENGTH,
            // Messages textuels seulement (fiche) : ni pièces jointes ni appels.
            "inputMethods" to emptyList<String>(),
            "callMethods" to emptyList<String>(),
            "features" to FEATURES,
        )
    }

    private fun messageDto(message: Message, me: User): Map<String, Any?> {
        val sender = message.sender_
        val isMine = localId(sender) == localId(me)
        val isDeleted = message.deletedAt_ != null
        val clientId = message.clientMessageId_
        return mapOf(
            "id" to localId(message),
            "clientMessageId" to if (clientId == 0L) null else clientId,
            "conversationId" to localId(message.conversation_),
            "content" to if (isDeleted) "" else message.content_,
            "type" to "text",
            "senderLabel" to displayName(sender),
            "isMine" to isMine,
            "createdAt" to iso(message.sentAt_),
            "editedAt" to message.editedAt_?.let { iso(it) },
            "isDeleted" to isDeleted,
            "isForwarded" to false,
            "delivery" to "sent",
            "reactions" to emptyList<Map<String, Any?>>(),
            "attachments" to emptyList<Map<String, Any?>>(),
            "canEdit" to (isMine && !isDeleted),
            "canDeleteForEveryone" to (isMine && !isDeleted),
            // Ordre d'affichage : l'identifiant local (croissant).
            "seq" to localId(message),
        )
    }

    // ─── Outils ─────────────────────────────────────────────────────────────

    private fun displayName(user: User): String =
        if (user.deletedAt_ != null) "Compte supprimé" else user.name_

    private fun validText(text: String): String {
        val content = text.trim()
        if (content.isEmpty() || content.length > MAX_TEXT_LENGTH) {
            throw MessagingException(MessagingException.INVALID_MESSAGE, "Message vide ou trop long")
        }
        return content
    }

    private fun rememberOldest(scope: String, conversationId: Long, items: List<Message>) {
        val oldest = items.firstOrNull() ?: return
        messageCursors[cursorKey(scope, conversationId)] = localId(oldest)
    }

    private fun cursorKey(scope: String, conversationId: Long) = "$scope|$conversationId"

    private fun page(items: List<Map<String, Any?>>, hasMore: Boolean): Map<String, Any?> =
        mapOf("items" to items, "hasMore" to hasMore)

    /** Identifiant local TModeler (`_id`). */
    private fun localId(model: TModel<*>): Long = (model._id_ as Number?)?.toLong() ?: 0L

    private fun now(): LocalDateTime = Clock.System.now().toLocalDateTime(TimeZone.UTC)

    private fun iso(time: LocalDateTime?): String? = time?.toInstant(TimeZone.UTC)?.toString()
}
