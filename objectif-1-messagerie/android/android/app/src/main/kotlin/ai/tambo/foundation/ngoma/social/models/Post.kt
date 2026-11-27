package ai.tambo.foundation.ngoma.social.models

import ai.tambo.foundation.ngoma.media.models.Media
import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Post : TModel<Post>() {

    var author = ModelField(User::class)
    var caption = TextField().default("")
    var media = ModelField(Media::class).nullable()  // photo ou vidéo facultative
    var createdAt = TimeField()
    var updatedAt = TimeField().nullable()
    var deletedAt = TimeField().nullable()

    @TMignore var author_ by author
    @TMignore var caption_ by caption
    @TMignore var media_ by media
    @TMignore var createdAt_ by createdAt
    @TMignore var updatedAt_ by updatedAt
    @TMignore var deletedAt_ by deletedAt

    companion object {
        val tms by lazy { Tms(Post::class) }
    }
}
