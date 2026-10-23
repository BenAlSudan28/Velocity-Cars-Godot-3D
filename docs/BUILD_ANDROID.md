# بناء Android APK عبر GitHub Actions

## ما يحدث في البناء

ملف `.github/workflows/build.yml` يستخدم Ubuntu 24.04 المستضاف من GitHub. يهيئ Java 17 وAndroid SDK وNDK، ويشغّل ADB، ثم ينزّل Godot 4.7.2 وقوالب التصدير المطابقة لإصداره. يستخدم إعداد التصدير قيم Godot الافتراضية لـMin/Target SDK لأن Gradle Build معطّل، ويُفعّل المشروع استيراد خامات ETC2/ASTC المطلوب لـAndroid. بعد استيراد الموارد وتشغيل اختبار الحلقة الأساسية، ينفّذ:

```bash
godot --headless --path . --export-debug "Android" artifacts/VelocityRush3D.apk
```

يتأكد Workflow من سلامة أرشيف APK وتوقيعه واسم الحزمة ووجود مكتبات ARMv7 وARM64، ثم يرفعه إلى GitHub Actions Artifacts. ينزّل GitHub الـArtifact بصيغة ZIP؛ يجب فك ضغطه وتثبيت `VelocityRush3D.apk` بداخله، لا ZIP نفسه. لا يحتاج المستخدم إلى Windows Runner أو Unreal Engine أو Android Studio على جهازه.

## الاستخدام من الهاتف

1. ارفع الملفات إلى مستودع GitHub مع الحفاظ على المجلدات.
2. افتح تبويب **Actions** وانتظر تشغيل **Build Android APK** أو شغّله يدويًا عبر **Run workflow**.
3. افتح التشغيل الناجح، ثم نزّل Artifact باسم `Velocity-Rush-3D-Android-APK`.
4. فك الضغط وثبّت APK. قد يطلب Android السماح بالتثبيت من هذا المصدر.

## التوقيع

الـAPK الناتج Debug لأغراض الاختبار. Workflow ينشئ مفتاحًا مؤقتًا داخل Runner ولا يرفع المفتاح كـArtifact. لا يُعاد استخدامه لتحديث نسخة منشورة. لإصدار متجر، أنشئ مفتاح Release خاصًا بك وخزّن القيم في GitHub Secrets، ثم هيئ توقيع Release منفصلًا ولا ترفع ملف المفتاح إلى المستودع.

## حدود التحقق

الاختبار المحلي يراجع استيراد المشروع والمنطق وتشغيل المشهد. لم يُبنَ APK في هذه البيئة لأن Android SDK وقوالب تصدير Android غير مثبتة هنا؛ ستنفّذ عملية تصدير APK الفعلية في GitHub Actions. نجاح الملف النهائي لا يُدّعى قبل نجاح تشغيل الـWorkflow.
