# Add project specific ProGuard rules here.
-keepattributes *Annotation*
-keep class org.tensorflow.lite.** { *; }
-keep class com.manwen.app.** { *; }
-dontwarn org.tensorflow.lite.**
