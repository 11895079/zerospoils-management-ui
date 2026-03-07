# Android ProGuard configuration for ZeroSpoils release builds
# Minimize and obfuscate code for Play Store releases
# Used with: flutter build apk --release --obfuscate --split-debug-info=./debug-info/

# Keep class names for Firebase services (required for remote config)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Preserve Supabase classes
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

# Keep Flutter generated code
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Preserve annotation classes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Preserve serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep native method names (required for plugins)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values (some enums may be serialized)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve resource references
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Verbose logging for debugging (comment out for production)
# -verbose
