package com.example.aleartmycontroller.di

import com.example.aleartmycontroller.BuildConfig
import com.example.aleartmycontroller.data.remote.google.GoogleCalendarApi
import com.example.aleartmycontroller.data.remote.toggl.TogglApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.Credentials
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import javax.inject.Named
import javax.inject.Qualifier
import javax.inject.Singleton

@Qualifier @Retention(AnnotationRetention.BINARY) annotation class CalendarRetrofit
@Qualifier @Retention(AnnotationRetention.BINARY) annotation class TogglRetrofit

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    /** 共通ロギングインターセプター（デバッグビルドのみ BODY レベルで出力） */
    @Provides
    @Singleton
    fun provideLoggingInterceptor(): HttpLoggingInterceptor =
        HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BODY
                    else HttpLoggingInterceptor.Level.NONE
        }

    // ---- Google Calendar ----

    @Provides
    @Singleton
    @CalendarRetrofit
    fun provideCalendarOkHttpClient(
        logging: HttpLoggingInterceptor,
        authRepository: com.example.aleartmycontroller.data.repository.AuthRepository
    ): OkHttpClient =
        OkHttpClient.Builder()
            .addInterceptor(logging)
            .addInterceptor { chain ->
                val token = kotlinx.coroutines.runBlocking {
                    authRepository.getAccessToken()
                }
                val newRequest = if (token != null) {
                    chain.request().newBuilder()
                        .addHeader("Authorization", "Bearer $token")
                        .build()
                } else {
                    chain.request()
                }
                chain.proceed(newRequest)
            }
            .build()

    @Provides
    @Singleton
    fun provideGoogleCalendarApi(
        @CalendarRetrofit client: OkHttpClient
    ): GoogleCalendarApi =
        Retrofit.Builder()
            .baseUrl(GoogleCalendarApi.BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(GoogleCalendarApi::class.java)

    // ---- Toggl Track ----

    /**
     * TogglはBasic Auth: username=APIトークン, password="api_token"
     * https://developers.track.toggl.com/docs/authentication
     */
    @Provides
    @Singleton
    @TogglRetrofit
    fun provideTogglOkHttpClient(
        logging: HttpLoggingInterceptor
    ): OkHttpClient =
        OkHttpClient.Builder()
            .addInterceptor(logging)
            .addInterceptor { chain ->
                val credential = Credentials.basic(
                    BuildConfig.TOGGL_API_TOKEN,
                    "api_token"
                )
                val request = chain.request().newBuilder()
                    .header("Authorization", credential)
                    .build()
                chain.proceed(request)
            }
            .build()

    @Provides
    @Singleton
    fun provideTogglApi(
        @TogglRetrofit client: OkHttpClient
    ): TogglApi =
        Retrofit.Builder()
            .baseUrl(TogglApi.BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TogglApi::class.java)
}
