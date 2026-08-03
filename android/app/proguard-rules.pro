# Flutter's own embedding is kept by the Flutter Gradle plugin's consumer
# rules; these cover the plugins this app links against.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# shared_preferences
-keep class androidx.preference.** { *; }

-dontwarn io.flutter.embedding.**
