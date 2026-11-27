package ai.tambo.foundation.ngoma.controllers

import ai.tambo.foundation.ngoma.models.users.User
import ai.tambo.foundation.ngoma.utils.AuthSession
import ai.tambo.foundation.ngoma.utils.now
import ai.tambo.tmodeler.field.operation.eq
import ai.tambo.tmodeler.field.operation.like
import ai.tambo.tmodeler.field.operation.unaryPlus
import ai.tambo.tmodeler.ms.ext.filter
import ai.tambo.tmodeler.ms.ext.lazy
import ai.tambo.tmodeler.scheduler.TmsScope

object UserController {

    context(_: TmsScope)
    fun getProfile(): Profile? {
        val user = AuthSession.currentUser() ?: return null
        val login = AuthSession.loginOf(user) ?: return null
        return Profile(user._id_, user.lastName_, user.firstName_, login.email_, user.createdAt_.toString())
    }

    context(_: TmsScope)
    fun updateProfile(last: String, first: String): ActionResult {
        val user = AuthSession.currentUser() ?: return ActionResult.NotSignedIn
        if (last.isBlank() || first.isBlank()) return ActionResult.InvalidInput
        user.lastName_  = last.trim()
        user.firstName_ = first.trim()
        user.updatedAt_ = now()
        user.update()
        return ActionResult.Success
    }

    context(_: TmsScope)
    fun searchUsers(query: String, limit: Int = 20, offset: Int = 0): List<UserSummary> {
        val q = query.trim()
        if (q.length < 2) return emptyList()
        val p = "%$q%"
        val u = User.tms.lambda
        return User.tms.with(u).lazy()
            .filter(((u.lastName like p) or (u.firstName like p)) and (u.deletedAt eq null))
            .order(+u.lastName)
            .sub(limit, offset)
            .build()
            .map { UserSummary(it._id_, "${it.firstName_} ${it.lastName_}") }
    }
}
