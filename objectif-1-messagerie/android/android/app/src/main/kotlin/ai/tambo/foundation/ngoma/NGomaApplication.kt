package ai.tambo.foundation.ngoma

import ai.tambo.foundation.ngoma.controllers.AuthController
import ai.tambo.foundation.ngoma.controllers.UserController
import ai.tambo.foundation.ngoma.controllers.UserController.getProfile
import ai.tambo.tmodeler.scheduler.TGate
import android.app.Application
import android.util.Log

class NGomaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NGomaTm.start(this)
        TGate.data {
            Log.d("NGOMA-1","signUp = ${AuthController.signUp("Mahaliana", "Fitiavana", "test@mail.com", "hash-test")}")
            Log.d("NGOMA-1", "signIn  = ${AuthController.signIn("test@mail.com", "hash-test")}")
            Log.d("NGOMA-1", "profil  = ${UserController.getProfile()}")
            Log.d("NGOMA-1", "edit    = ${UserController.updateProfile("Nouveau", "Nom")}")
            Log.d("NGOMA-1", "search  = ${UserController.searchUsers("nou")}")
            Log.d("NGOMA-1", "signOut -> profil = ${AuthController.run { signOut(); getProfile() }}")
        }
    }

}
