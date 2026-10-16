# مصادر البناء وحقوق الأصول

## مراجع البناء الرسمية

- [Godot — التصدير إلى Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html): متطلبات Java وAndroid SDK وقوالب التصدير.
- [Godot — استخدام سطر الأوامر](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html): خيارات تشغيل المحرر والتصدير دون واجهة.
- [Godot — خيارات تصدير Android](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html): مفاتيح إعدادات المنصة.
- [Godot 4.7.2 Stable](https://godotengine.org/download/archive/4.7.2-stable/): إصدار المحرك المثبّت والمثبّت في سير العمل.
- [android-actions/setup-android](https://github.com/android-actions/setup-android): تهيئة أدوات Android SDK على GitHub Actions.
- [Android Developers — Godot](https://developer.android.com/games/engines/godot/godot-export): توثيق Android الرسمي للتصدير من Godot.

يستخدم ملف CI إصدار Godot 4.7.2 وقوالب تصدير مطابقة له. فحص المصدر محليًا لا يثبت نجاح APK؛ يتعين نجاح تشغيل GitHub Actions للتحقق من البناء الفعلي.

## الأصول

- **نماذج السيارات:** ثلاثة نماذج GLB خيالية موجودة في الأرشيف الذي رفعه المستخدم، وفق `Resources/README.md` فيه: لا شعارات Ferrari أو Lamborghini أو Toyota، ولا تدّعي أنها سيارات إنتاجية مرخصة. تبقى أسماء سيارات اللعبة خيالية.
- **الصوت:** ملفات WAV ثم OGG مبنية من الأصوات الموجودة في أرشيف المستخدم. لم يتضمن الأرشيف بيان ترخيص مستقلًا للصوت؛ تحقّق من حق إعادة التوزيع قبل جعل المستودع عامًا أو استخدام الأصول تجاريًا، واستبدلها إذا لم تكن تملك حقوقها.
- **الخط:** Noto Sans Arabic من حزمة `fonts-noto-core`؛ يتضمن `assets/fonts/NotoSansArabic-OFL.txt` نص SIL Open Font License 1.1.
- **الأيقونات:** رسوم أصلية مولدة محليًا بواسطة `tools/generate_icons.py`، بلا شعارات أو علامات سيارات.
