package ai.tambo.foundation.ngoma.messaging.models

import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.EnumField
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Conversation : TModel<Conversation>() {

    enum class Kind { DIRECT, GROUP }

    var kind = EnumField(Kind.values()).default(Kind.DIRECT)
    var title = TextField().default("")
    var createdBy = ModelField(User::class)
    var createdAt = TimeField()
    var lastMessageAt = TimeField().nullable()       // trie la boîte de réception

    @TMignore var kind_ by kind
    @TMignore var title_ by title
    @TMignore var createdBy_ by createdBy
    @TMignore var createdAt_ by createdAt
    @TMignore var lastMessageAt_ by lastMessageAt

    companion object {
        val tms by lazy { Tms(Conversation::class) }
    }
}
