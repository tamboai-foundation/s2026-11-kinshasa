package ai.tambo.foundation.ngoma.social.models

import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class CommentLike : TModel<CommentLike>() {

    var comment = ModelField(Comment::class)
    var user = ModelField(User::class)
    var createdAt = TimeField()

    @TMignore var comment_ by comment
    @TMignore var user_ by user
    @TMignore var createdAt_ by createdAt

    companion object {
        val tms by lazy { Tms(CommentLike::class) }
    }
}
