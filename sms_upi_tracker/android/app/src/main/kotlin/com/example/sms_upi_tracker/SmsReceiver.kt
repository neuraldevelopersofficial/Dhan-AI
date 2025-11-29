package com.example.sms_upi_tracker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent.action) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (smsMessage in messages) {
                val body = smsMessage.messageBody ?: ""
                val sender = smsMessage.originatingAddress ?: ""
                
                // Check if it looks like a UPI transaction
                if (isUpiTransaction(body)) {
                    val amount = extractAmount(body)
                    if (amount != null && amount > 0) {
                        showNotification(context, amount, sender)
                    }
                }
            }
        }
    }
    
    private fun isUpiTransaction(body: String): Boolean {
        val lower = body.lowercase()
        return lower.contains("upi") ||
               lower.contains("credited") ||
               lower.contains("debited") ||
               lower.contains("payment") ||
               lower.contains("paid") ||
               lower.contains("transaction") ||
               lower.contains("transfer") ||
               (lower.contains("rs") || lower.contains("₹")) &&
               (lower.contains("credited") || lower.contains("debited"))
    }
    
    private fun extractAmount(body: String): Double? {
        val patterns = listOf(
            Regex("""(?:rs|inr|₹|rupees?|amount|amt)\s*:?\s*([0-9,]+(?:\.[0-9]{1,2})?)""", RegexOption.IGNORE_CASE),
            Regex("""([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:rs|inr|₹|rupees?)""", RegexOption.IGNORE_CASE),
            Regex("""\b([0-9]{1,2}(?:,[0-9]{2})*(?:\.[0-9]{1,2})?)\b""")
        )
        
        for (pattern in patterns) {
            val match = pattern.find(body)
            if (match != null) {
                val numeric = match.groupValues[1].replace(",", "")
                val amount = numeric.toDoubleOrNull()
                if (amount != null && amount > 0 && amount < 100000000) {
                    return amount
                }
            }
        }
        return null
    }
    
    private fun showNotification(context: Context, amount: Double, sender: String) {
        val notificationManager = NotificationManagerCompat.from(context)
        
        // Create notification channel for Android O+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "upi_transactions",
                "UPI Transactions",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for new UPI transactions"
                enableVibration(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
        
        val senderDisplay = if (sender.length > 20) sender.substring(0, 20) + "..." else sender
        
        val notification = NotificationCompat.Builder(context, "upi_transactions")
            .setSmallIcon(android.R.drawable.sym_def_app_icon)
            .setContentTitle("New UPI Transaction")
            .setContentText("₹${String.format("%.2f", amount)} from $senderDisplay")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            .setAutoCancel(true)
            .build()
        
        try {
            notificationManager.notify(System.currentTimeMillis().toInt(), notification)
        } catch (e: Exception) {
            // Notification permission might not be granted
        }
    }
}

