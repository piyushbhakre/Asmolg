# Suppress warnings related to proguard.annotation.Keep
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Keep Awesome Notifications classes
-keep class com.dexterous.** { *; }
-keep class de.android.** { *; }
-keep class awesome_notifications.** { *; }

# Keep Flutter plugins classes
-keep class io.flutter.** { *; }

# General ProGuard rules for Flutter (ensures that no Flutter or Dart classes are stripped)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Avoid stripping of generated code used in Flutter
-keep class io.flutter.** { *; }
-keep class androidx.lifecycle.** { *; }
