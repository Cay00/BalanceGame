import 'dart:math';

/// Prosta reprezentacja prostokątnej przeszkody na planszy
class Obstacle {
  final double x; // lewy górny róg
  final double y;
  final double width;
  final double height;
  final double angle; // kąt obrotu (radiany) dla wizualizacji

  const Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.angle,
  });
}

/// Fizyka gry - zarządza ruchem kulki, kolizjami i przeszkodami
///
/// Zawiera:
/// - Pozycję i prędkość kulki
/// - Parametry fizyki (grawitacja, tarcie)
/// - Kalibrację akcelerometru
/// - Logikę kolizji ze ścianami i przeszkodami
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

  // === PRZESZKODY ===
  final List<Obstacle> obstacles = [];
  final Random _random = Random();

  /// Inicjalizuje fizykę z wymiarami ekranu
  void initialize(double width, double height, {double bottomPadding = 0}) {
    screenWidth = width;
    screenHeight = height;
    // Ustaw kulkę na środku ekranu
    ballX = width / 2;
    ballY = height / 2;
    // Zapisz padding dolny dla kolizji
    _bottomPadding = bottomPadding;

    // Wygeneruj losowe przeszkody
    _generateObstacles();
  }

  /// Resetuje pozycję kulki na środek ekranu i zatrzymuje ją
  void resetBall() {
    ballX = screenWidth / 2;
    ballY = screenHeight / 2;
    velocityX = 0.0;
    velocityY = 0.0;

    // Opcjonalnie odśwież przeszkody przy resecie
    _generateObstacles();
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

    // === KOLIZJE Z PRZESZKODAMI ===
    _handleObstacleCollisions();
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

  /// Generuje losowe, podłużne przeszkody
  void _generateObstacles() {
    obstacles.clear();

    if (screenWidth == 0 || screenHeight == 0) {
      return;
    }

    const int count = 8;
    const int maxAttemptsPerObstacle = 25;

    for (var i = 0; i < count; i++) {
      Obstacle? newObstacle;

      for (var attempt = 0; attempt < maxAttemptsPerObstacle; attempt++) {
        final isHorizontal = _random.nextBool();

        final double length = (isHorizontal ? screenWidth : screenHeight) *
            (0.25 + _random.nextDouble() * 0.25);
        const double thickness = 16.0;
        final double angle = (_random.nextDouble() - 0.5) * pi / 2; // ~ -45°..45°

        double x, y, width, height;

        if (isHorizontal) {
          width = length;
          height = thickness;
          x = _random.nextDouble() * (screenWidth - width - 40) + 20;
          y = _random.nextDouble() * (screenHeight * 0.6 - height - 40) + 60;
        } else {
          width = thickness;
          height = length;
          x = _random.nextDouble() * (screenWidth * 0.8 - width - 40) + 40;
          y = _random.nextDouble() * (screenHeight * 0.5 - height - 40) + 80;
        }

        final candidate = Obstacle(
          x: x,
          y: y,
          width: width,
          height: height,
          angle: angle,
        );

        // Sprawdź, czy nachodzi na istniejące przeszkody
        final overlapsExisting = obstacles.any((existing) {
          final bool noOverlap =
              candidate.x + candidate.width <= existing.x ||
                  existing.x + existing.width <= candidate.x ||
                  candidate.y + candidate.height <= existing.y ||
                  existing.y + existing.height <= candidate.y;
          return !noOverlap;
        });

        if (!overlapsExisting) {
          newObstacle = candidate;
          break;
        }
      }

      if (newObstacle != null) {
        obstacles.add(newObstacle);
      }
    }
  }

  /// Obsługuje kolizje kulki z prostokątnymi przeszkodami
  void _handleObstacleCollisions() {
    const double ballRadius = 15.0;

    for (final obstacle in obstacles) {
      final double left = obstacle.x;
      final double right = obstacle.x + obstacle.width;
      final double top = obstacle.y;
      final double bottom = obstacle.y + obstacle.height;

      // Najbliższy punkt prostokąta do środka kulki
      final double closestX = ballX.clamp(left, right);
      final double closestY = ballY.clamp(top, bottom);

      final double dx = ballX - closestX;
      final double dy = ballY - closestY;

      // Czy kulka wchodzi w prostokąt
      if (dx * dx + dy * dy <= ballRadius * ballRadius) {
        // Oblicz penetrację w każdym kierunku i odbij kulkę od najbliższej krawędzi
        final double overlapLeft = (ballX + ballRadius) - left;
        final double overlapRight = right - (ballX - ballRadius);
        final double overlapTop = (ballY + ballRadius) - top;
        final double overlapBottom = bottom - (ballY - ballRadius);

        final double minOverlap =
            [overlapLeft, overlapRight, overlapTop, overlapBottom].reduce(min);

        const double bounceFactor = 0.8;

        if (minOverlap == overlapLeft) {
          ballX = left - ballRadius;
          velocityX = -velocityX * bounceFactor;
        } else if (minOverlap == overlapRight) {
          ballX = right + ballRadius;
          velocityX = -velocityX * bounceFactor;
        } else if (minOverlap == overlapTop) {
          ballY = top - ballRadius;
          velocityY = -velocityY * bounceFactor;
        } else {
          ballY = bottom + ballRadius;
          velocityY = -velocityY * bounceFactor;
        }
      }
    }
  }
}


