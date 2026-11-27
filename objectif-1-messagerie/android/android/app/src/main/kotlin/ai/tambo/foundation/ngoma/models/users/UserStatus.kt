package ai.tambo.foundation.ngoma.models.users

import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class UserStatus : TModel<UserStatus>() {

    var status    = TextField().default(ACTIVE)
    var user      = ModelField(User::class)
    var createdAt = TimeField()
    var updatedAt = TimeField().nullable()

    @TMignore var status_    by status
    @TMignore var user_      by user
    @TMignore var createdAt_ by createdAt
    @TMignore var updatedAt_ by updatedAt

    companion object {
        const val ACTIVE    = "ACTIVE"
        const val BLOCKED   = "BLOCKED"
        const val SUSPENDED = "SUSPENDED"
        const val DELETED   = "DELETED"

        val tms by lazy { Tms(UserStatus::class) }
    }
}
