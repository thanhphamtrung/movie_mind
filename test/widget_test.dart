import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movie_mind/main.dart';
import 'package:movie_mind/core/di/injection.dart' as di;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Mock environment variables for testing
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=mock_key_here');
    
    // Reset GetIt to prevent duplicate registration in multiple test environments
    await di.sl.reset();
    await di.init();
  });

  testWidgets('MovieMind app launches successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MovieMindApp());
    await tester.pump(); // Pump first frame to kick off DI and Bloc building

    // Verify that the initial discover text is present.
    expect(find.text('Khám phá Điện ảnh cùng AI'), findsOneWidget);
  });
}
