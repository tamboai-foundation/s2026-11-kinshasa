package ai.tambo.foundation.ngoma.messaging.models

import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Participant : TModel<Participant>() {

    var conversation = ModelField(Conversation::class)
    var user = ModelField(User::class)
    var joinedAt = TimeField()
    var lastReadAt = TimeField().nullable()

    @TMignore var conversation_ by conversation
    @TMignore var user_ by user
    @TMignore var joinedAt_ by joinedAt
    @TMignore var lastReadAt_ by lastReadAt

    companion object {
        val tms by lazy { Tms(Participant::class) }
    }
}
