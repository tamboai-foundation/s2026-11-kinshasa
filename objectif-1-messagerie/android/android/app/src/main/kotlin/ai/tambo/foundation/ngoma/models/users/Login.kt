package ai.tambo.foundation.ngoma.models.users

import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Login : TModel<Login>() {

    var email        = TextField().unique().notNull()
    var passwordHash = TextField().notNull()
    var user         = ModelField(User::class)

    @TMignore
    var email_        by email
    @TMignore
    var passwordHash_ by passwordHash
    @TMignore
    var user_         by user

    companion object{
        val tms by lazy { Tms(Login::class) }
    }

}