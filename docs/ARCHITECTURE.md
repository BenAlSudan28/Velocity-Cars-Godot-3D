# بنية اللعبة

- `scenes/race/`: مشاهد Godot صغيرة للمشهد الرئيسي والسيارة والخصم والعقبة والتقاط النيترو والحلبة.
- `scripts/race/race_main.gd`: مالك تدفق اللعب؛ القائمة والبدء والإيقاف وإعادة اللعب والنتائج.
- `scripts/race/race_track.gd` و`route_math.gd`: مسار Catmull–Rom المغلق، إحداثيات الطريق، سطحه وخطوطه والحواجز.
- `racer.gd` و`player_driver.gd` و`rival_driver.gd`: الحركة والسرعة والتوجيه والانجراف والنيترو وذكاء الخصوم.
- `car_catalog.gd` و`car_visual.gd`: ربط أسماء السيارات الخيالية بملفات GLB وعرض بديل إجرائي عند فشل الاستيراد.
- `collision_manager.gd` و`score_system.gd` و`difficulty_manager.gd`: حساب التصادمات والنتيجة وتدرّج صعوبة المنافسين.
- `track_decorator.gd`: عناصر مدينة وحلبة منخفضة الكلفة باستخدام MultiMesh.
- `race_hud.gd` و`touch_controls.gd` و`race_theme.gd`: واجهة عربية متجاوبة، شاشات اللعب والتحكم باللمس.
- `audio_manager.gd` و`settings_store.gd`: صوت محلي، محرك متغير النبرة، وكتم الصوت وتفضيلات اللاعب.
- `assets/race/`: ملفات GLB وOGG محلية. لا يعتمد التشغيل على الإنترنت.
- `assets/icons/`: أيقونة أصلية، SVG وPNG وطبقات adaptive.
- `.github/workflows/build.yml`: استيراد الموارد، اختبار دخان، بناء APK Debug ورفع الـArtifact.

محرك السباق غير متصل بالإنترنت. التصادمات والنتيجة تحت سلطة Godot محليًا؛ لا توجد خدمة خادم أو تسجيل دخول أو لوحة ترتيب شبكية.
