package im.balmi.balmi

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "im.balmi.app/oem"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "manufacturer" -> result.success(Build.MANUFACTURER)
                    "openOemBatterySettings" -> result.success(openOemBatterySettings())
                    else -> result.notImplemented()
                }
            }
    }

    private fun openOemBatterySettings(): Boolean {
        val brand = Build.MANUFACTURER.lowercase()
        val intents = mutableListOf<Intent>()
        when {
            brand.contains("samsung") -> {
                intents += component(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                )
                intents += component(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                )
            }
            brand.contains("xiaomi") ||
                brand.contains("redmi") ||
                brand.contains("poco") ||
                brand.contains("blackshark") -> {
                intents += Intent("miui.intent.action.POWER_HIDE_MODE_APP_LIST")
                intents += component(
                    "com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.HiddenAppsConfigActivity",
                )
                intents += component(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                )
            }
            brand.contains("huawei") || brand.contains("honor") -> {
                intents += component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                )
                intents += component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                )
            }
            brand.contains("oppo") || brand.contains("realme") || brand.contains("oneplus") -> {
                intents += component(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity",
                )
                intents += component(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity",
                )
            }
            brand.contains("vivo") || brand.contains("iqoo") -> {
                intents += component(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                )
                intents += component(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
                )
            }
        }
        intents += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        intents += Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:$packageName"),
        )
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }
        return false
    }

    private fun component(pkg: String, cls: String): Intent {
        return Intent().setComponent(ComponentName(pkg, cls))
    }
}
