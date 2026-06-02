package com.example.aleartmycontroller.data.preferences

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TogglTokenStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val sharedPreferences by lazy { openOrRecreate() }

    private fun openOrRecreate(): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return try {
            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (_: Exception) {
            // APK の再インストールや署名変更で Keystore キーと暗号化データが合わなくなった場合に
            // AEADBadTagException 等が発生する。ファイルを削除して空の状態で作り直す。
            context.deleteSharedPreferences(PREFS_NAME)
            EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        }
    }

    fun hasToken(): Boolean = !getToken().isNullOrBlank()

    fun getToken(): String? = sharedPreferences.getString(KEY_TOKEN, null)?.takeIf { it.isNotBlank() }

    fun setToken(token: String) {
        sharedPreferences.edit().putString(KEY_TOKEN, token.trim()).apply()
    }

    fun clearToken() {
        sharedPreferences.edit().remove(KEY_TOKEN).apply()
    }

    companion object {
        private const val PREFS_NAME = "toggl_secure_store"
        private const val KEY_TOKEN = "toggl_api_token"
    }
}
