package ai.tambo.foundation.ngoma

import android.app.Application

class NGomaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NGomaTm.start(this)
    }
}
