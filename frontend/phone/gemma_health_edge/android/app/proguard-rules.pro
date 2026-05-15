# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Riverpod
-keep class * extends androidx.lifecycle.ViewModel
-keep class * extends androidx.lifecycle.AndroidViewModel
-dontwarn androidx.lifecycle.**

# Hive
-keep class com.hivedatabase.** { *; }
-keep @com.hivemq.annotation.HiveEntity class * { *; }

# TFLite
-keep class org.tensorflow.lite.** { *; }
-keep class tflite_flutter.** { *; }

# FFI
-keep class dart.** { *; }

# Bluetooth
-keep class com.lib.flutter_blue_plus.** { *; }

# Health
-keep class health.** { *; }

# JSON parsing
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Google Play Core (Fixes build failure for missing deferred component classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
