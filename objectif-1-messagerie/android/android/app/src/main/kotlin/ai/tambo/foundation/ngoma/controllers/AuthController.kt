package ai.tambo.foundation.ngoma.controllers

import ai.tambo.foundation.ngoma.models.users.Credential
import ai.tambo.foundation.ngoma.models.users.User
import ai.tambo.foundation.ngoma.models.users.UserStatus
import ai.tambo.foundation.ngoma.utils.AuthSession
import ai.tambo.foundation.ngoma.utils.PasswordHasher
import ai.tambo.foundation.ngoma.utils.UserStatusHelper
import ai.tambo.foundation.ngoma.utils.normalizeEmail
import ai.tambo.foundation.ngoma.utils.now
import ai.tambo.tmodeler.field.operation.eq
import ai.tambo.tmodeler.ms.ext.filter
import ai.tambo.tmodeler.ms.ext.lazy
import ai.tambo.tmodeler.scheduler.TmsScope


object AuthController {
    context(_: TmsScope)
    fun signUp(last: String, first: String, mail: String, phone: String, password: String): SignUpResult {
        // 1) email unique : on vérifie avant d'écrire
        val l = Credential.tms.lambda
        val found = Credential.tms.with(l).lazy().filter(l.email eq normalizeEmail(mail)).build()
        if (found.isNotEmpty()) return SignUpResult.EmailAlreadyUsed(mail)

        // 2) création de l'utilisateur
        val user = User().also {
            it.lastName_     = last.trim()
            it.firstName_    = first.trim()
            it.phone_        = phone.trim()
            it.createdAt_    = now()
            it.save()
        }
        UserStatusHelper.setStatus(user, UserStatus.ACTIVE)

        val passwordHash = PasswordHasher.hash(password)
        // 3) création du login
        val credential = Credential().also {
            it.email_        = normalizeEmail(mail)
            it.passwordHash_ = passwordHash
            it.user_         = user
            it.save()
        }
        return SignUpResult.Success(user._id_, mail)
    }

    context(_: TmsScope)
    fun signIn(mail: String, password: String): SignInResult {
        val l = Credential.tms.lambda
        val credential = Credential.tms.with(l).lazy()
            .filter(l.email eq normalizeEmail(mail)).build().firstOrNull()
            ?: return SignInResult.InvalidCredentials

        val user = credential.user_
        when (UserStatusHelper.getStatus(user)) {
            UserStatus.DELETED -> return SignInResult.AccountDeleted
            UserStatus.BLOCKED -> return SignInResult.AccountBlocked
            UserStatus.SUSPENDED -> return SignInResult.AccountSuspended
            UserStatus.ACTIVE -> { /* Compte actif */ }
            else -> return SignInResult.AccountDisabled
        }

        // Même réponse pour « email inconnu » et « mauvais mot de passe »
        if (!PasswordHasher.verify(password, credential.passwordHash_)) return SignInResult.InvalidCredentials
        if (!credential.user.available()) return SignInResult.InvalidCredentials

        AuthSession.signIn(user)
        return SignInResult.Success(user._id_)
    }

    context(_: TmsScope)
    fun signOut() = AuthSession.signOut()

}