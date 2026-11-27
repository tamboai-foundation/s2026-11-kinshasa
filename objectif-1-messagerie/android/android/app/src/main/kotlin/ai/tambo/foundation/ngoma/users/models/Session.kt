package ai.tambo.foundation.ngoma.users.models

import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Session : TModel<Session>() {

    var currentUser = ModelField(User::class).nullable()
    var startedAt = TimeField()

    @TMignore var currentUser_ by currentUser
    @TMignore var startedAt_ by startedAt

    companion object {
        val tms by lazy { Tms(Session::class) }
    }
}
