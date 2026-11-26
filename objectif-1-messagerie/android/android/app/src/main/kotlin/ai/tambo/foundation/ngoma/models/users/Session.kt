package ai.tambo.foundation.ngoma.models.users

import ai.tambo.tmodeler.field.common.IntField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Session : TModel<Session>() {
    var currentUserId = IntField().default(0)

    @TMignore var currentUserId_ by currentUserId

    companion object { val tms by lazy { Tms(Session::class) } }
}
