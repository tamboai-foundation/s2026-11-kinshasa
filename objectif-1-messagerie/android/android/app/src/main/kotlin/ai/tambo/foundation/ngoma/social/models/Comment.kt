package ai.tambo.foundation.ngoma.social.models

import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Comment : TModel<Comment>() {

    var post = ModelField(Post::class)
    var author = ModelField(User::class)
    var parent = ModelField(Comment::class).nullable()
    var text = TextField().default("")
    var createdAt = TimeField()
    var updatedAt = TimeField().nullable()
    var deletedAt = TimeField().nullable()

    @TMignore var post_ by post
    @TMignore var author_ by author
    @TMignore var parent_ by parent
    @TMignore var text_ by text
    @TMignore var createdAt_ by createdAt
    @TMignore var updatedAt_ by updatedAt
    @TMignore var deletedAt_ by deletedAt

    companion object {
        val tms by lazy { Tms(Comment::class) }
    }
}
