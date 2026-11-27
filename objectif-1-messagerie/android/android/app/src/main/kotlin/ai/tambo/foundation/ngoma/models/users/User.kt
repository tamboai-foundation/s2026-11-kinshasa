package ai.tambo.foundation.ngoma.models.users

import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.field.media.ImageField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class User : TModel<User>() {

    var lastName     = TextField()
    var firstName    = TextField()
    var phone        = TextField().default("")
    var bio          = TextField().default("")
    var createdAt    = TimeField()
    var updatedAt    = TimeField().nullable()
    var deletedAt    = TimeField().nullable()

    @TMignore var lastName_     by lastName
    @TMignore var firstName_    by firstName
    @TMignore var phone_        by phone
    @TMignore var bio_          by bio
    @TMignore var createdAt_    by createdAt
    @TMignore var updatedAt_    by updatedAt
    @TMignore var deletedAt_    by deletedAt

    companion object {
        val tms by lazy { Tms(User::class) }
    }
}
