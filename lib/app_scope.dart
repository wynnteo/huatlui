import 'services/fx_service.dart';
import 'services/portfolio_repository.dart';
import 'services/price_service.dart';
import 'theme/app_settings_controller.dart';

/// App-wide singletons. Kept in one tiny file (not main.dart) so screens
/// can import them without a circular import back to main.
final settings = AppSettingsController();
final repo = PortfolioRepository();
final fx = FxService();
final prices = PriceController(repo: repo);
