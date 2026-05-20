package com.example.aleartmycontroller.data.repository

import android.content.Context
import com.google.android.gms.auth.GoogleAuthUtil
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val scope = "oauth2:https://www.googleapis.com/auth/calendar.events"

    /**
     * 最後にサインインしたアカウントを取得する
     */
    fun getLastSignedInAccount(): GoogleSignInAccount? {
        return GoogleSignIn.getLastSignedInAccount(context)
    }

    /**
     * 指定されたアカウントのアクセストークンを取得する
     * 注意: このメソッドはブロッキングなので Dispatchers.IO で実行する
     */
    suspend fun getAccessToken(): String? = withContext(Dispatchers.IO) {
        val account = getLastSignedInAccount()?.account ?: return@withContext null
        runCatching {
            GoogleAuthUtil.getToken(context, account, scope)
        }.getOrNull()
    }
}
