package io.flutter.plugins.sharedpreferences;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;

/**
 * Minimal stub that satisfies the GeneratedPluginRegistrant import and
 * returns empty/null values for all shared_preferences calls.
 * The Dart-side SharedPreferences will work but preferences won't persist.
 */
public class SharedPreferencesPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        channel = new MethodChannel(
            binding.getBinaryMessenger(), "plugins.flutter.io/shared_preferences");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "getAll":
                result.success(new HashMap<String, Object>());
                break;
            case "setBool":
            case "setString":
            case "setInt":
            case "setDouble":
            case "setStringList":
                result.success(true);
                break;
            case "remove":
            case "clear":
                result.success(true);
                break;
            case "getString":
            case "getBool":
            case "getInt":
            case "getDouble":
            case "getStringList":
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
}
