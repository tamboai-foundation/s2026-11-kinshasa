package ai.tambo.foundation.ngoma

import ai.tambo.foundation.ngoma.media.models.Media
import ai.tambo.foundation.ngoma.messaging.models.Conversation
import ai.tambo.foundation.ngoma.messaging.models.Message
import ai.tambo.foundation.ngoma.messaging.models.Participant
import ai.tambo.foundation.ngoma.social.models.Comment
import ai.tambo.foundation.ngoma.social.models.CommentLike
import ai.tambo.foundation.ngoma.social.models.Post
import ai.tambo.foundation.ngoma.social.models.PostLike
import ai.tambo.foundation.ngoma.users.models.Login
import ai.tambo.foundation.ngoma.users.models.Session
import ai.tambo.foundation.ngoma.users.models.User
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
    const val DB_VERSION = 2

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
                    // Module 1 · Gestion des utilisateurs
                    .accept(User().clazz().getPackage())
                    // Socle commun · Médias
                    .accept(Media().clazz().getPackage())
                    // Module 2 · Conversations et messages
                    .accept(Conversation().clazz().getPackage())
                    // Module 3 · Publications et interactions
                    .accept(Post().clazz().getPackage())
                    .start()!!
            )

        // Module 1 · Gestion des utilisateurs
        User.tms.commit()
        Login.tms.commit()
        Session.tms.commit()
        // Socle commun · Médias
        Media.tms.commit()
        // Module 2 · Conversations et messages
        Conversation.tms.commit()
        Participant.tms.commit()
        Message.tms.commit()
        // Module 3 · Publications et interactions
        Post.tms.commit()
        PostLike.tms.commit()
        Comment.tms.commit()
        CommentLike.tms.commit()
    }
}
