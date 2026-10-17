package com.expensetracker.expense_tracker

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.expensetracker.expense_tracker/upi"
    private val UPI_PAYMENT_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGooglePayInstalled" -> {
                    val gpayInstalled = isPackageInstalled("com.google.android.apps.nbu.paisa.user")
                    result.success(gpayInstalled)
                }
                "isAnyUpiAppInstalled" -> {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
                    val activities = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    result.success(activities.isNotEmpty())
                }
                "initiateUpiPayment" -> {
                    val upiUriStr = call.argument<String>("upiUri")
                    val forceGooglePay = call.argument<Boolean>("forceGooglePay") ?: false
                    if (upiUriStr == null) {
                        result.error("INVALID_URI", "UPI URI cannot be null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = Uri.parse(upiUriStr)
                        val intent = Intent(Intent.ACTION_VIEW, uri)

                        if (forceGooglePay || isPackageInstalled("com.google.android.apps.nbu.paisa.user")) {
                            intent.setPackage("com.google.android.apps.nbu.paisa.user")
                        }

                        if (intent.resolveActivity(packageManager) != null) {
                            pendingResult = result
                            startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)
                        } else {
                            // Try fallback to generic UPI handler without package restriction
                            intent.setPackage(null)
                            if (intent.resolveActivity(packageManager) != null) {
                                pendingResult = result
                                startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)
                            } else {
                                result.success(mapOf(
                                    "status" to "NO_UPI_APP",
                                    "message" to "No UPI app installed on this device"
                                ))
                            }
                        }
                    } catch (e: ActivityNotFoundException) {
                        result.success(mapOf(
                            "status" to "NO_UPI_APP",
                            "message" to (e.localizedMessage ?: "Activity not found")
                        ))
                    } catch (e: Exception) {
                        result.error("UPI_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            val response = data?.getStringExtra("response") ?: data?.dataString ?: ""
            val status = parseUpiStatus(response, resultCode)

            pendingResult?.success(mapOf(
                "status" to status,
                "rawResponse" to response,
                "resultCode" to resultCode
            ))
            pendingResult = null
        }
    }

    private fun parseUpiStatus(response: String, resultCode: Int): String {
        val lower = response.lowercase()
        return when {
            lower.contains("status=success") || lower.contains("success") -> "SUCCESS"
            lower.contains("status=failure") || lower.contains("failed") || lower.contains("failure") -> "FAILURE"
            lower.contains("status=submitted") -> "SUBMITTED"
            resultCode == Activity.RESULT_CANCELED -> "CANCELLED"
            response.isEmpty() -> if (resultCode == Activity.RESULT_OK) "SUCCESS" else "CANCELLED"
            else -> "UNKNOWN"
        }
    }
}
