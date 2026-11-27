package ai.tambo.foundation.ngoma.models.users

import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Session : TModel<Session>() {
    var currentUser = ModelField(User::class)

    @TMignore var currentUser_ by currentUser

    companion object { val tms by lazy { Tms(Session::class) } }
}
