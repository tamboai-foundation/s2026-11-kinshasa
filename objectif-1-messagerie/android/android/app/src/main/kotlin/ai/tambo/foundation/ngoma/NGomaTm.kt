package ai.tambo.foundation.ngoma

import ai.tambo.foundation.ngoma.models.users.Credential
import ai.tambo.foundation.ngoma.models.users.Session
import ai.tambo.foundation.ngoma.models.users.User
import ai.tambo.foundation.ngoma.models.users.UserStatus
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
                    .accept(User().clazz().getPackage())
                    .start()!!
            )

        User.tms.commit()
        Credential.tms.commit()
        Session.tms.commit()
        UserStatus.tms.commit()
    }
}
