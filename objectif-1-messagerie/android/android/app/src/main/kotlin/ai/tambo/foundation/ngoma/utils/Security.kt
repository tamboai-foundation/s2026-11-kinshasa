package ai.tambo.foundation.ngoma.utils

import ai.tambo.foundation.ngoma.models.users.Credential
import ai.tambo.foundation.ngoma.models.users.Session
import ai.tambo.foundation.ngoma.models.users.User
import ai.tambo.foundation.ngoma.models.users.UserStatus
import ai.tambo.tmodeler.field.operation.eq
import ai.tambo.tmodeler.ms.ext.all
import ai.tambo.tmodeler.ms.ext.filter
import ai.tambo.tmodeler.ms.ext.lazy
import ai.tambo.tmodeler.scheduler.TmsScope
import android.util.Base64
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec


// date et heure actuelles
internal fun now() =
    Clock.System.now().toLocalDateTime(TimeZone.UTC)

internal fun normalizeEmail(mail: String) = mail.trim().lowercase()

object PasswordHasher {
    fun hash(password: String): String {
        val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
        return enc(salt) + ":" + enc(derive(password, salt))
    }

    fun verify(password: String, stored: String): Boolean {
        val parts = stored.split(":")
        if (parts.size != 2) return false
        return MessageDigest.isEqual(dec(parts[1]), derive(password, dec(parts[0])))
    }

    private fun derive(password: String, salt: ByteArray): ByteArray =
        SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            .generateSecret(PBEKeySpec(password.toCharArray(), salt, 120_000, 256)).encoded

    private fun enc(b: ByteArray) = Base64.encodeToString(b, Base64.NO_WRAP)
    private fun dec(s: String) = Base64.decode(s, Base64.NO_WRAP)
}

object UserStatusHelper {
    context(_: TmsScope)
    fun getStatus(user: User): String {
        val s = UserStatus.tms.lambda
        val statusObj = UserStatus.tms.with(s).lazy().filter(s.user eq user).build().firstOrNull()
        return statusObj?.status_ ?: UserStatus.ACTIVE
    }

    context(_: TmsScope)
    fun setStatus(user: User, statusValue: String) {
        val s = UserStatus.tms.lambda
        val statusObj = UserStatus.tms.with(s).lazy().filter(s.user eq user).build().firstOrNull()
        if (statusObj == null) {
            UserStatus().also {
                it.user_ = user
                it.status_ = statusValue
                it.createdAt_ = now()
                it.save()
            }
        } else {
            statusObj.status_ = statusValue
            statusObj.updatedAt_ = now()
            statusObj.update()
        }
    }

    context(_: TmsScope)
    fun isUserActive(user: User): Boolean {
        return getStatus(user) == UserStatus.ACTIVE
    }
}

object AuthSession {
    context(_: TmsScope)
    private fun session(): Session =
        Session.tms.all().firstOrNull() ?: Session().also { it.save() }

    context(_: TmsScope)
    fun currentUser(): User? {
        val s = session()
        if (!s.currentUser.available()) return null       // personne n'est connecté
        val user = s.currentUser_ ?: return null
        return if (UserStatusHelper.isUserActive(user)) user else null      // vérification statut
    }


    context(_: TmsScope)
    fun signIn(user: User) { val s = session(); s.currentUser_ = user; s.update() }

    context(_: TmsScope)
    fun signOut() { Session.tms.all().forEach { it.delete() } }

    // Les identifiants (Login) d'un utilisateur
    context(_: TmsScope)
    fun loginOf(user: User): Credential? {
        val l = Credential.tms.lambda
        return Credential.tms.with(l).lazy().filter(l.user eq user).build().firstOrNull()
    }
}
