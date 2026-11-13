package ai.tambo.foundation.ngoma.models

import ai.tambo.tmodeler.field.common.TextField
import ai.tambo.tmodeler.model.TMignore
import ai.tambo.tmodeler.model.TModel
import ai.tambo.tmodeler.ms.Tms

/** Example TModeler model: copy this pattern for the models of the project. */
class Note : TModel<Note>() {

    var title = TextField().default("")
    var content = TextField().default("")

    @TMignore var title_ by title
    @TMignore var content_ by content

    companion object {
        val tms by lazy { Tms(Note::class) }
    }
}
