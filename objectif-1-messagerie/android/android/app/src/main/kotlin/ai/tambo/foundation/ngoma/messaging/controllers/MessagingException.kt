package ai.tambo.foundation.ngoma.messaging.controllers

class MessagingException(val code: String, message: String) : Exception(message) {
    companion object {
        /** Personne n'est connecté (Session.currentUser vide). */
        const val NOT_AUTHENTICATED = "MESSAGING_NOT_AUTHENTICATED"
        const val CONVERSATION_NOT_FOUND = "MESSAGING_CONVERSATION_NOT_FOUND"
        const val MESSAGE_NOT_FOUND = "MESSAGING_MESSAGE_NOT_FOUND"
        const val RECIPIENT_NOT_FOUND = "MESSAGING_RECIPIENT_NOT_FOUND"

        /** Pas participant, ou l'autre compte est supprimé. */
        const val SEND_FORBIDDEN = "MESSAGING_SEND_FORBIDDEN"

        /** Modifier / supprimer le message d'un autre, ou un message supprimé. */
        const val ACTION_NOT_ALLOWED = "MESSAGING_ACTION_NOT_ALLOWED"

        /** Fonction non demandée par la fiche (réactions, appels, pièces jointes…). */
        const val FEATURE_DISABLED = "MESSAGING_FEATURE_DISABLED"

        /** Message vide ou trop long. */
        const val INVALID_MESSAGE = "MESSAGING_INVALID_MESSAGE"

        /** Argument manquant dans l'appel du canal. */
        const val INVALID_ARGS = "MESSAGING_INVALID_ARGS"
    }
}
