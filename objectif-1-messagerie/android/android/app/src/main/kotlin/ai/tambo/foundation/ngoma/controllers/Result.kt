package ai.tambo.foundation.ngoma.controllers

sealed class SignUpResult {
    data class Success(val userId: Long, val email: String) : SignUpResult()
    data class EmailAlreadyUsed(val email: String) : SignUpResult()
}

sealed class SignInResult {
    data class Success(val userId: Long) : SignInResult()
    object InvalidCredentials : SignInResult()
    object AccountDisabled : SignInResult()
}

sealed class ActionResult {
    object Success : ActionResult()
    object NotSignedIn : ActionResult()
    object WrongPassword : ActionResult()
    object EmailAlreadyUsed : ActionResult()
    object InvalidInput : ActionResult()
}

data class Profile(
    val userId: Long,
    val lastName: String,
    val firstName: String,
    val email: String,
    val phone: String,
    val bio: String,
    val createdAt: String
)

data class UserSummary(val userId: Long, val fullName: String)
