package ai.tambo.foundation.ngoma

import ai.tambo.foundation.ngoma.models.Note
import ai.tambo.tmodeler.db.Tcontext
import ai.tambo.tmodeler.db.Tdb
import ai.tambo.tmodeler.modeler.TModeler
import android.app.Application

/**
 * TModeler initialisation (Maven Central: co.tamboai:TModeler).
 * Local SQLite only: the UI currently talks to mocks (see README.md).
 */
object NGomaTm {
    /** Increment to restart every device from an empty database. */
    const val DB_VERSION = 1

    private var started = false

    @Synchronized
    fun start(app: Application) {
        if (started) return
        started = true

        TModeler
            .start()
            .connect(
                Tdb.Builder()
                    .type(Tdb.Type.SQLITE)
                    .context(Tcontext(app))
                    .dbDir("db/")
                    .dbName("ngoma-$DB_VERSION")
                    .accept(Note().clazz().getPackage())
                    .start()!!
            )

        Note.tms.commit()
    }
}
