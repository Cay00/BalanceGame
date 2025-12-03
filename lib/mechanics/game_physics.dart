/// Fizyka gry - zarządza ruchem kulki i kolizjami
///
/// Zawiera:
/// - Pozycję i prędkość kulki
/// - Parametry fizyki (grawitacja, tarcie)
/// - Kalibrację akcelerometru
/// - Logikę kolizji ze ścianami
class GamePhysics {
  // === FIZYKA KULKI ===
  double ballX = 0.0; // Pozycja kulki w osi X (piksele)
  double ballY = 0.0; // Pozycja kulki w osi Y (piksele)
  double velocityX = 0.0; // Prędkość kulki w osi X (piksele/klatka)
  double velocityY = 0.0; // Prędkość kulki w osi Y (piksele/klatka)

  // === PUNKTY ===
  int score = 0; // Aktualny wynik gracza
  bool _isInsideHole = false; // Czy kulka jest aktualnie w dziurze

  // === PARAMETRY FIZYKI ===
  double gravity = 0.1; // Siła grawitacji
  double friction = 0.95; // Tarcie (0.95 = 5% utraty prędkości na klatkę)
  double forceMultiplier = 0.5; // Mnożnik siły z akcelerometru

  // === KALIBRACJA AKCELEROMETRU ===
  double offsetX = 0.0; // Offset X - wartość gdy telefon leży płasko
  double offsetY = 0.0; // Offset Y - wartość gdy telefon leży płasko

  // === WYMIARY EKRANU ===
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  double _bottomPadding = 0.0;

  /// Inicjalizuje fizykę z wymiarami ekranu
  void initialize(double width, double height, {double bottomPadding = 0}) {
    screenWidth = width;
    screenHeight = height;
    // Ustaw kulkę na środku ekranu
    ballX = width / 2;
    ballY = height / 2;
    // Zapisz padding dolny dla kolizji
    _bottomPadding = bottomPadding;
  }

  /// Resetuje pozycję kulki na środek ekranu i zatrzymuje ją
  void resetBall() {
    ballX = screenWidth / 2;
    ballY = screenHeight / 2;
    velocityX = 0.0;
    velocityY = 0.0;
  }

  /// Kalibruje akcelerometr - zapisuje aktualne wartości jako "poziom 0"
  void calibrate(double x, double y) {
    offsetX = x;
    offsetY = y;
    velocityX = 0.0;
    velocityY = 0.0;
  }

  /// Aktualizuje fizykę kulki na podstawie danych z akcelerometru
  ///
  /// Wykonuje:
  /// 1. Dodanie siły z akcelerometru do prędkości
  /// 2. Dodanie grawitacji
  /// 3. Zastosowanie tarcia
  /// 4. Aktualizację pozycji kulki
  /// 5. Detekcję kolizji ze ścianami i odbicia
  void updatePhysics(double accelX, double accelY) {
    // === DODAJ SIŁĘ Z AKCELEROMETRU ===
    // Używa offsetów z kalibracji - różnica od "poziomu 0"
    velocityX += -(accelX - offsetX) * forceMultiplier; // X akcelerometru → ruch w lewo/prawo
    velocityY += (accelY - offsetY) * forceMultiplier; // Y akcelerometru → ruch w górę/dół

    // === GRAWITACJA ===
    // Działa tylko gdy telefon jest znacząco pochylony w obu osiach względem skalibrowanej pozycji
    if ((accelX - offsetX).abs() > 0.1 || (accelY - offsetY).abs() > 0.1) {
      // Próg 0.1 dla znaczącego pochylenia
      velocityY += gravity;
    }

    // === TARCIE ===
    // Spowalnia kulkę (0.95 = 5% utraty prędkości na klatkę)
    velocityX *= friction;
    velocityY *= friction;

    // === AKTUALIZACJA POZYCJI ===
    ballX += velocityX;
    ballY += velocityY;

    // === KOLIZJE ZE ŚCIANAMI ===
    _handleCollisions();
  }

  /// Aktualizuje wynik gry na podstawie pozycji dziury
  ///
  /// Wywołuj po `updatePhysics`, przekazując współrzędne środka dziury i jej promień.
  void updateScore(double holeX, double holeY, double holeRadius) {
    // Odległość pomiędzy środkiem kulki a środkiem dziury
    final dx = ballX - holeX;
    final dy = ballY - holeY;
    final distanceSquared = dx * dx + dy * dy;
    final radiusSquared = holeRadius * holeRadius;

    final isNowInside = distanceSquared <= radiusSquared;

    // Zlicz punkt tylko w momencie wejścia do dziury (zbocze narastające)
    if (isNowInside && !_isInsideHole) {
      score += 1;
    }

    _isInsideHole = isNowInside;
  }

  /// Obsługuje kolizje kulki ze ścianami ekranu
  void _handleCollisions() {
    // Lewa ściana
    if (ballX < 15) {
      ballX = 15;
      velocityX = -velocityX * 0.8; // Odbicie z utratą 20% energii
    }
    // Prawa ściana
    if (ballX > screenWidth - 15) {
      ballX = screenWidth - 15;
      velocityX = -velocityX * 0.8;
    }
    // Górna ściana
    if (ballY < 15) {
      ballY = 15;
      velocityY = -velocityY * 0.8;
    }
    // Dolna ściana (zostaw miejsce na AppBar i dolną belkę nawigacyjną)
    final bottomBoundary = screenHeight - 100 - _bottomPadding;
    if (ballY > bottomBoundary) {
      ballY = bottomBoundary;
      velocityY = -velocityY * 0.8;
    }
  }
}


