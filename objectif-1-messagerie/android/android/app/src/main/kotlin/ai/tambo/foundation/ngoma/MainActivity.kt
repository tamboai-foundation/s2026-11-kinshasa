package ai.tambo.foundation.ngoma

import ai.tambo.foundation.ngoma.controllers.AccountController
import ai.tambo.foundation.ngoma.controllers.AuthController
import ai.tambo.foundation.ngoma.controllers.Profile
import ai.tambo.foundation.ngoma.controllers.SignInResult
import ai.tambo.foundation.ngoma.controllers.SignUpResult
import ai.tambo.foundation.ngoma.controllers.UserController
import ai.tambo.tmodeler.scheduler.TGate
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ngoma/account"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            TGate.data {
                when (call.method) {
                    "restoreSession", "getSessionSnapshot" -> {
                        val profile = UserController.getProfile()
                        result.success(buildSessionResponse(profile))
                    }
                    "login" -> {
                        val email = call.argument<String>("identifier") ?: ""
                        val password = call.argument<String>("password") ?: ""
                        when (val res = AuthController.signIn(email, password)) {
                            is SignInResult.Success -> {
                                val profile = UserController.getProfile()
                                result.success(buildSessionResponse(profile))
                            }
                            SignInResult.InvalidCredentials -> {
                                result.error("INVALID_CREDENTIALS", "Email ou mot de passe incorrect.", null)
                            }
                            SignInResult.AccountBlocked -> {
                                result.error("ACCOUNT_BLOCKED", "Votre compte a été bloqué.", null)
                            }
                            SignInResult.AccountSuspended -> {
                                result.error("ACCOUNT_SUSPENDED", "Votre compte est temporairement suspendu.", null)
                            }
                            SignInResult.AccountDeleted -> {
                                result.error("ACCOUNT_DELETED", "Ce compte a été supprimé.", null)
                            }
                            SignInResult.AccountDisabled -> {
                                result.error("ACCOUNT_DISABLED", "Ce compte est désactivé.", null)
                            }
                        }
                    }
                    "register" -> {
                        val fullName = call.argument<String>("fullName") ?: ""
                        val email = call.argument<String>("email") ?: ""
                        val phone = call.argument<String>("phone") ?: ""
                        val password = call.argument<String>("password") ?: ""
                        val parts = fullName.split(" ", limit = 2)
                        val last = parts.getOrNull(1) ?: ""
                        val first = parts.firstOrNull() ?: ""

                        when (val res = AuthController.signUp(last, first, email, phone, password)) {
                            is SignUpResult.Success -> {
                                val profile = UserController.getProfile()
                                result.success(buildSessionResponse(profile))
                            }
                            is SignUpResult.EmailAlreadyUsed -> {
                                result.error("EMAIL_ALREADY_USED", "Cet email est déjà utilisé par un autre compte.", null)
                            }
                        }
                    }
                    "logout" -> {
                        AuthController.signOut()
                        result.success(buildSessionResponse(null))
                    }
                    "updateProfile" -> {
                        val fields = call.argument<Map<String, Any?>>("fields") ?: emptyMap()
                        val firstName = fields["firstName"] as? String ?: ""
                        val lastName = fields["lastName"] as? String ?: ""
                        val phone = fields["phone"] as? String
                        val bio = fields["bio"] as? String
                        if (firstName.isNotBlank() && lastName.isNotBlank()) {
                            UserController.updateProfile(lastName, firstName, phone, bio)
                        }
                        val profile = UserController.getProfile()
                        result.success(buildSessionResponse(profile))
                    }
                    "deleteAccount" -> {
                        AccountController.deleteAccount()
                        val profile = UserController.getProfile()
                        result.success(buildSessionResponse(profile))
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun buildSessionResponse(profile: Profile?): Map<String, Any?> {
        val isAuthenticated = profile != null
        val actions = listOf("explore", "message", "save", "pay", "manageAccount", "manageService")
        
        val accessList = actions.map { action ->
            val allowed = action == "explore" || isAuthenticated
            mapOf(
                "action" to action,
                "allowed" to allowed,
                "blocker" to if (allowed) "none" else "authentication",
                "resolutionRoute" to if (allowed) null else "/auth"
            )
        }

        val userMap = if (profile != null) {
            mapOf(
                "id" to profile.userId.toInt(),
                "firstName" to profile.firstName,
                "lastName" to profile.lastName,
                "email" to profile.email,
                "bio" to profile.bio,
                "phone" to profile.phone,
                "kycStatus" to "verified",
                "preferredLanguage" to "fr",
                "activeServices" to listOf("hub", "activity")
            )
        } else {
            null
        }

        return mapOf(
            "status" to if (isAuthenticated) "authenticated" else "guest",
            "destination" to if (isAuthenticated) "/hub" else "/auth",
            "user" to userMap,
            "access" to accessList
        )
    }
}
