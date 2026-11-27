package ai.tambo.foundation.ngoma.flutterBridge

import io.flutter.plugin.common.MethodCall

fun MethodCall.argLong(key: String): Long? = (argument<Any>(key) as? Number)?.toLong()

fun MethodCall.argString(key: String): String? = argument<Any>(key) as? String

fun MethodCall.argBool(key: String): Boolean? = argument<Any>(key) as? Boolean

fun MethodCall.argLongList(key: String): List<Long> =
    (argument<Any>(key) as? List<*>)?.mapNotNull { (it as? Number)?.toLong() } ?: emptyList()
