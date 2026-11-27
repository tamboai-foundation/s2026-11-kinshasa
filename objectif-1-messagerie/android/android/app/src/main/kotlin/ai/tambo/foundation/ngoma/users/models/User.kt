package ai.tambo.foundation.ngoma.users.models

import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class User : TModel<User>() {

    var name = TextField().default("")
    var bio = TextField().default("")
    var phone = TextField().default("")
    var joinedAt = TimeField()
    var updatedAt = TimeField().nullable()            // dernière modification du profil
    var deletedAt = TimeField().nullable()            // non null = compte supprimé

    @TMignore var name_ by name
    @TMignore var bio_ by bio
    @TMignore var phone_ by phone
    @TMignore var joinedAt_ by joinedAt
    @TMignore var updatedAt_ by updatedAt
    @TMignore var deletedAt_ by deletedAt

    companion object {
        val tms by lazy { Tms(User::class) }
    }
}
