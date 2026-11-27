package ai.tambo.foundation.ngoma.users.models

import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Login : TModel<Login>() {

    var user = ModelField(User::class).unique()
    var email = TextField().unique().notNull()
    var passwordHash = TextField().notNull()
    var createdAt = TimeField()
    var updatedAt = TimeField().nullable()            // dernier changement de mot de passe

    @TMignore var user_ by user
    @TMignore var email_ by email
    @TMignore var passwordHash_ by passwordHash
    @TMignore var createdAt_ by createdAt
    @TMignore var updatedAt_ by updatedAt

    companion object {
        val tms by lazy { Tms(Login::class) }
    }
}
