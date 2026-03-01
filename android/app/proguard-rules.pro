# ========== FLUTTER ==========
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ========== PLAY CORE ==========
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ========== FIREBASE ==========
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ========== YOUR APP ==========
-keep class com.example.bangla_hub.** { *; }
-keep class com.example.bangla_hub.models.** { *; }

# ========== ESSENTIALS ==========
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Keep Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepnames class * implements java.io.Serializable

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Remove logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Disable warnings for everything else
-dontwarn **