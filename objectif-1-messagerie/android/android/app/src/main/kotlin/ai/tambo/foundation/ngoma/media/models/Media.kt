package ai.tambo.foundation.ngoma.media.models

import ai.tambo.foundation.ngoma.users.models.User
import ai.tambo.tmodeler.field.advanced.EnumField
import ai.tambo.tmodeler.field.advanced.ModelField
import ai.tambo.tmodeler.field.advanced.TimeField
import ai.tambo.tmodeler.field.common.IntField
import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.field.media.FileField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

class Media : TModel<Media>() {

    enum class Type { IMAGE, VIDEO }

    var file = FileField()
    var type = EnumField(Type.values()).default(Type.IMAGE)
    var mimeType = TextField().default("")
    var sizeBytes = IntField().default(0)
    var uploadedBy = ModelField(User::class)
    var createdAt = TimeField()

    @TMignore var file_ by file
    @TMignore var type_ by type
    @TMignore var mimeType_ by mimeType
    @TMignore var sizeBytes_ by sizeBytes
    @TMignore var uploadedBy_ by uploadedBy
    @TMignore var createdAt_ by createdAt

    companion object {
        val tms by lazy { Tms(Media::class) }
    }
}
