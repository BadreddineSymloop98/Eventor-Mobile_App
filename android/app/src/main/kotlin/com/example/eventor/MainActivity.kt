package com.example.eventor

import android.Manifest
import android.annotation.TargetApi
import android.app.DownloadManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    /** A save waiting on the storage permission (Android 9 and older). */
    private var pendingSave: Pair<MethodCall, MethodChannel.Result>? = null

    /** A "download complete" notification waiting on POST_NOTIFICATIONS. */
    private var pendingNotice: (() -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // `eventor/downloads` — see lib/core/services/device_files.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePdf" -> savePdf(call, result)
                    "open" -> open(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun savePdf(call: MethodCall, result: MethodChannel.Result) {
        // Asked for only on Android 6–9: before 6 it is granted at install,
        // from 10 on writing into Downloads needs none.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            pendingSave = call to result
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                STORAGE_REQUEST,
            )
            return
        }
        val bytes = call.argument<ByteArray>("bytes")!!
        val name = call.argument<String>("name")!!
        val notice = call.argument<Map<String, String>>("notice")
        // The file is handed back first; the notification (and, the first
        // time on Android 13+, its permission prompt) follows.
        val done = { saved: Map<String, String?> ->
            runOnUiThread {
                result.success(saved)
                if (notice != null) notifySaved(saved["uri"], saved["name"] ?: name, notice)
            }
        }
        // Off the main thread: the write is small but still disk I/O.
        Thread {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    done(saveToMediaStore(bytes, name))
                } else {
                    saveToPublicDownloads(bytes, name, done)
                }
            } catch (error: Exception) {
                runOnUiThread { result.error("failed", error.message, null) }
            }
        }.start()
    }

    /**
     * Android 10+: straight into the public Downloads collection, no
     * permission needed. Android numbers a clashing name itself —
     * "INV-1 (1).pdf" — so the name it settled on is read back.
     */
    @TargetApi(Build.VERSION_CODES.Q)
    private fun saveToMediaStore(bytes: ByteArray, name: String): Map<String, String> {
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, PDF)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            // Hidden from other apps until the bytes are all written.
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("MediaStore refused the file")
        try {
            resolver.openOutputStream(uri)!!.use { it.write(bytes) }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
        val savedName = resolver.query(
            uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null } ?: name
        return mapOf("uri" to uri.toString(), "name" to savedName)
    }

    /**
     * Android 9 and older: a file in the public Downloads folder, numbered
     * like Android 10 does on a clash, then indexed so viewers can open it.
     */
    @Suppress("DEPRECATION")
    private fun saveToPublicDownloads(
        bytes: ByteArray,
        name: String,
        done: (Map<String, String?>) -> Unit,
    ) {
        val folder = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        folder.mkdirs()
        val base = name.removeSuffix(".pdf")
        var file = File(folder, name)
        var n = 1
        while (file.exists()) file = File(folder, "$base (${n++}).pdf")
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf(PDF)) { _, uri ->
            done(mapOf("uri" to uri?.toString(), "name" to file.name))
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        if (requestCode == NOTIFY_REQUEST) {
            val notice = pendingNotice
            pendingNotice = null
            if (granted) notice?.invoke()
            return
        }
        if (requestCode != STORAGE_REQUEST) return
        val (call, result) = pendingSave ?: return
        pendingSave = null
        if (granted) {
            savePdf(call, result)
        } else {
            result.error("denied", "Storage permission refused", null)
        }
    }

    /**
     * "Download complete" in the notification shade, as a browser posts it:
     * the file's name, and a tap opens it. On Android 13+ the permission is
     * asked the first time only — refused, the toast in the app still said it.
     */
    private fun notifySaved(uri: String?, name: String, notice: Map<String, String>) {
        val post = { postDownloadNotice(uri?.let(Uri::parse), name, notice) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            val prefs = getSharedPreferences(NATIVE_PREFS, MODE_PRIVATE)
            if (prefs.getBoolean(ASKED_NOTIFICATIONS, false)) return
            prefs.edit().putBoolean(ASKED_NOTIFICATIONS, true).apply()
            pendingNotice = post
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFY_REQUEST)
            return
        }
        post()
    }

    private fun postDownloadNotice(uri: Uri?, name: String, notice: Map<String, String>) {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Quiet, like a browser's finished download: in the shade, no sound.
            manager.createNotificationChannel(
                NotificationChannel(
                    DOWNLOADS_CHANNEL,
                    notice["channel"] ?: "Downloads",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }
        val view = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, PDF)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        // No PDF viewer on the phone (or no URI): the tap opens Downloads.
        val tap = if (uri != null && view.resolveActivity(packageManager) != null) {
            view
        } else {
            Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val id = name.hashCode()
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, DOWNLOADS_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(name)
            .setContentText(notice["text"])
            .setContentIntent(
                PendingIntent.getActivity(
                    this,
                    id,
                    tap,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
            .setAutoCancel(true)
            .setShowWhen(true)
            .build()
        manager.notify(id, notification)
    }

    /** Opens a saved PDF in whatever viewer the phone has; false if none. */
    private fun open(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.parse(call.argument<String>("uri")!!)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, PDF)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(intent)
            result.success(true)
        } catch (error: ActivityNotFoundException) {
            result.success(false)
        }
    }

    private companion object {
        const val CHANNEL = "eventor/downloads"
        const val PDF = "application/pdf"
        const val STORAGE_REQUEST = 4201
        const val NOTIFY_REQUEST = 4202
        const val DOWNLOADS_CHANNEL = "downloads"
        const val NATIVE_PREFS = "eventor_native"
        const val ASKED_NOTIFICATIONS = "asked_post_notifications"
    }
}
