package com.example.aleartmycontroller.data.repository

import android.content.Context
import android.util.Log
import com.google.android.gms.auth.GoogleAuthUtil
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import dagger.hilt.android.qualifiers.ApplicationContext
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val supabase: SupabaseClient
) {
    private val calendarScope = "oauth2:https://www.googleapis.com/auth/calendar.events"

    fun getLastSignedInAccount(): GoogleSignInAccount? =
        GoogleSignIn.getLastSignedInAccount(context)

    suspend fun getAccessToken(): String? = withContext(Dispatchers.IO) {
        val account = getLastSignedInAccount()?.account ?: return@withContext null
        runCatching { GoogleAuthUtil.getToken(context, account, calendarScope) }.getOrNull()
    }

    /**
     * Google IdToken を使って Supabase にサインインし、profiles 行を upsert する。
     * 失敗時は例外をそのまま投げる（呼び出し元で catch してエラー表示すること）。
     */
    suspend fun signInWithSupabase(account: GoogleSignInAccount) {
        val idToken = account.idToken
            ?: error("Google idToken が null です。SUPABASE_GOOGLE_WEB_CLIENT_ID が正しく設定されているか確認してください。")

        withContext(Dispatchers.IO) {
            supabase.auth.signInWith(IDToken) {
                provider = Google
                this.idToken = idToken
            }
            Log.i(TAG, "Supabase sign-in succeeded: ${account.email}")
            upsertProfile(account)
        }
    }

    fun isSupabaseAuthenticated(): Boolean =
        supabase.auth.currentSessionOrNull() != null

    fun currentSupabaseUserId(): String? =
        supabase.auth.currentSessionOrNull()?.user?.id

    private suspend fun upsertProfile(account: GoogleSignInAccount) {
        val userId = supabase.auth.currentSessionOrNull()?.user?.id ?: return
        runCatching {
            supabase.from("profiles").upsert(
                buildJsonObject {
                    put("id", userId)
                    put("google_subject", account.id ?: "")
                    account.displayName?.let { put("display_name", it) }
                    account.photoUrl?.toString()?.let { put("avatar_url", it) }
                }
            )
            Log.i(TAG, "Profile upserted for $userId")
        }.onFailure { Log.e(TAG, "Profile upsert failed", it) }
    }

    companion object {
        private const val TAG = "AuthRepository"
    }
}
