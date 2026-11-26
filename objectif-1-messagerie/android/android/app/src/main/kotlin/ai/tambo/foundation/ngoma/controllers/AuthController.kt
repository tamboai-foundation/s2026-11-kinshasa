package ai.tambo.foundation.ngoma.controllers

import ai.tambo.foundation.ngoma.controllers.UserController.isDisabled
import ai.tambo.foundation.ngoma.models.users.Login
import ai.tambo.foundation.ngoma.models.users.User
import ai.tambo.foundation.ngoma.utils.AuthSession
import ai.tambo.foundation.ngoma.utils.PasswordHasher
import ai.tambo.foundation.ngoma.utils.now
import ai.tambo.tmodeler.field.operation.eq
import ai.tambo.tmodeler.ms.ext.filter
import ai.tambo.tmodeler.ms.ext.lazy
import ai.tambo.tmodeler.scheduler.TmsScope
import android.util.Log


object AuthController {
    context(_: TmsScope)
    fun signUp(last: String, first: String, mail: String, password: String): SignUpResult {
        // 1) email unique : on vérifie avant d'écrire
        val l = Login.tms.lambda
        val found = Login.tms.with(l).lazy().filter(l.email eq mail.trim()).build()
        if (found.isNotEmpty()) return SignUpResult.EmailAlreadyUsed(mail)

        // 2) création de l'utilisateur
        val user = User().also {
            it.lastName_     = last.trim()
            it.firstName_    = first.trim()
            it.createdAt_    = now()
            it.save()
        }
        val passwordHash = PasswordHasher.hash(password)
        // 3) création du login
        val login = Login().also {
            it.email_        = mail.trim()
            it.passwordHash_ = passwordHash
            it.user_         = user
            it.save()
        }
        return SignUpResult.Success(user._id_, mail)
    }

    context(_: TmsScope)
    fun signIn(mail: String, password: String): SignInResult {
        val l = Login.tms.lambda
        val login = Login.tms.with(l)
            .filter(l.email eq mail.trim().lowercase()).build().firstOrNull()
            ?: return SignInResult.InvalidCredentials

        Log.d("NGOMA", "Login ID: ${login._id_}")
        Log.d("NGOMA", "Email: ${login.email_}")

        // Même réponse pour « email inconnu » et « mauvais mot de passe »
        if (!PasswordHasher.verify(password, login.passwordHash_)) return SignInResult.InvalidCredentials
//        if (!login.user.available()) return SignInResult.InvalidCredentials

        val user = login.user_
        if (isDisabled(user)) return SignInResult.AccountDisabled

        AuthSession.signIn(user)
        return SignInResult.Success(user._id_)
    }

    context(_: TmsScope)
    fun signOut() = AuthSession.signOut()

}