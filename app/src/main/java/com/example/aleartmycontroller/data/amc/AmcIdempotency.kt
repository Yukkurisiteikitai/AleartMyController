package com.example.aleartmycontroller.data.amc

import java.util.UUID

object AmcIdempotency {
    fun newKey(): String = UUID.randomUUID().toString()
}

