package ai.tambo.foundation.ngoma.messaging.models

import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.IntField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Message : TModel<Message>() {

    var conversation = ModelField(Conversation::class)
    var sender = ModelField(User::class)
    var content = TextField().default("")
    var sentAt = TimeField()
    var editedAt = TimeField().nullable()            // non null = modifié
    var deletedAt = TimeField().nullable()           // non null = supprimé
    var clientMessageId = IntField().default(0)      // 0 = non fourni

    @TMignore var conversation_ by conversation
    @TMignore var sender_ by sender
    @TMignore var content_ by content
    @TMignore var sentAt_ by sentAt
    @TMignore var editedAt_ by editedAt
    @TMignore var deletedAt_ by deletedAt
    @TMignore var clientMessageId_ by clientMessageId

    companion object {
        val tms by lazy { Tms(Message::class) }
    }
}
