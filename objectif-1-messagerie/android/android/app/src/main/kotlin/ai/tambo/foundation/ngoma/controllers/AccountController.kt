package ai.tambo.foundation.ngoma.controllers

import ai.tambo.foundation.ngoma.models.users.Credential
import ai.tambo.foundation.ngoma.utils.AuthSession
import ai.tambo.foundation.ngoma.utils.PasswordHasher
import ai.tambo.foundation.ngoma.utils.now
import ai.tambo.tmodeler.field.operation.eq
import ai.tambo.tmodeler.ms.ext.filter
import ai.tambo.tmodeler.ms.ext.lazy
import ai.tambo.tmodeler.scheduler.TmsScope

object AccountController {

    context(_: TmsScope)
    fun changePassword(oldPassword: String, newPassword: String): ActionResult {
        val user  = AuthSession.currentUser() ?: return ActionResult.NotSignedIn
        val login = AuthSession.loginOf(user) ?: return ActionResult.NotSignedIn
        if (!PasswordHasher.verify(oldPassword, login.passwordHash_)) return ActionResult.WrongPassword
        if (newPassword.length < 8) return ActionResult.InvalidInput
        login.passwordHash_ = PasswordHasher.hash(newPassword)
        login.update()
        user.updatedAt_ = now(); user.update()
        return ActionResult.Success
    }

    context(_: TmsScope)
    fun changeEmail(newEmail: String, password: String): ActionResult {
        val user  = AuthSession.currentUser() ?: return ActionResult.NotSignedIn
        val login = AuthSession.loginOf(user) ?: return ActionResult.NotSignedIn
        if (!PasswordHasher.verify(password, login.passwordHash_)) return ActionResult.WrongPassword

        val mail = newEmail.trim().lowercase()
        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(mail).matches()) return ActionResult.InvalidInput
        if (mail == login.email_) return ActionResult.Success

        val l = Credential.tms.lambda
        if (Credential.tms.with(l).lazy().filter(l.email eq mail).build().isNotEmpty())
            return ActionResult.EmailAlreadyUsed

        login.email_ = mail
        login.update()
        user.updatedAt_ = now(); user.update()
        return ActionResult.Success
    }

    // compte désactivé
    context(_: TmsScope)
    fun deactivate(password: String): ActionResult {
        val user  = AuthSession.currentUser() ?: return ActionResult.NotSignedIn
        val login = AuthSession.loginOf(user) ?: return ActionResult.NotSignedIn
        if (!PasswordHasher.verify(password, login.passwordHash_)) return ActionResult.WrongPassword
        user.deletedAt_ = now()
        user.update()
        AuthSession.signOut()
        return ActionResult.Success
    }
}
