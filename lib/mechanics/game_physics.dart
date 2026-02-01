import 'dart:math';

class Obstacle {
  final double x; // lewy górny róg przeszkody
  final double y;
  final double width; // szerokość przeszkody
  final double height; // wysokość przeszkody
  final double holeX; // pozycja X środka dziury
  final double holeWidth; // szerokość dziury

  const Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.holeX,
    required this.holeWidth,
  });
}

/// Fizyka gry - zarządza ruchem kulki i kolizjami
class GamePhysics {
  // FIZYKA KULKI
  double ballX = 0.0; // Pozycja kulki w osi X
  double ballY = 0.0; // Pozycja kulki w osi Y
  double velocityX = 0.0; // Prędkość kulki w osi X
  double velocityY = 0.0; // Prędkość kulki w osi Y

  // PUNKTY
  int score = 0; // Aktualny wynik gracza
  bool _isInsideHole = false;

  // PARAMETRY FIZYKI
  double gravity = 0.1; // Siła grawitacji
  double friction = 0.95; // Tarcie (0.95 = 5% utraty prędkości na klatkę)
  double forceMultiplier = 0.5; // Mnożnik siły z akcelerometru

  // KALIBRACJA AKCELEROMETRU
  double offsetX = 0.0;
  double offsetY = 0.0;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  double _bottomPadding = 0.0;

  final List<Obstacle> obstacles = [];
  final Random _random = Random();

  void initialize(double width, double height, {double bottomPadding = 0}) {
    screenWidth = width;
    screenHeight = height;
    ballX = width / 2;
    ballY = 30.0;
    _bottomPadding = bottomPadding;

    // Wygeneruj przeszkody
    _generateObstacles();
  }

  /// Resetuje pozycję kulki na górę ekranu i zatrzymuje ją
  void resetBall() {
    ballX = screenWidth / 2;
    ballY = 30.0;
    velocityX = 0.0;
    velocityY = 0.0;
  }

  /// Generuje nowy poziom - nowe przeszkody
  void generateNewLevel() {
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
  void updatePhysics(double accelX, double accelY) {
    velocityX += -(accelX - offsetX) * forceMultiplier; // X akcelerometru, ruch w lewo/prawo
    velocityY += (accelY - offsetY) * forceMultiplier; // Y akcelerometru, ruch w górę/dół

    // GRAWITACJA
    if ((accelX - offsetX).abs() > 0.1 || (accelY - offsetY).abs() > 0.1) {
      velocityY += gravity;
    }

    // TARCIE
    velocityX *= friction;
    velocityY *= friction;

    // AKTUALIZACJA POZYCJI
    ballX += velocityX;
    ballY += velocityY;

    // KOLIZJE ZE ŚCIANAMI
    _handleCollisions();

    // KOLIZJE Z PRZESZKODAMI
    _handleObstacleCollisions();
  }

  /// Aktualizuje wynik gry na podstawie pozycji dziury
  bool updateScore(double holeX, double holeY, double holeRadius) {
    // Odległość pomiędzy środkiem kulki a środkiem dziury
    final dx = ballX - holeX;
    final dy = ballY - holeY;
    final distanceSquared = dx * dx + dy * dy;

    final double detectionRadius = holeRadius * 0.6;
    final double detectionRadiusSquared = detectionRadius * detectionRadius;

    final isNowInside = distanceSquared <= detectionRadiusSquared;

    if (isNowInside) {
      ballX = holeX;
      ballY = holeY;
      velocityX = 0.0;
      velocityY = 0.0;
    }

    final bool justEntered = isNowInside && !_isInsideHole;
    if (justEntered) {
      score += 1;
    }

    _isInsideHole = isNowInside;
    return justEntered;
  }

  /// Obsługuje kolizje kulki ze ścianami ekranu
  void _handleCollisions() {
    // Lewa
    if (ballX < 15) {
      ballX = 15;
      velocityX = -velocityX * 0.8; // Odbicie z utratą 20% energii
    }
    // Prawa
    if (ballX > screenWidth - 15) {
      ballX = screenWidth - 15;
      velocityX = -velocityX * 0.8;
    }
    // Górna
    if (ballY < 15) {
      ballY = 15;
      velocityY = -velocityY * 0.8;
    }
    // Dolna
    final bottomBoundary = screenHeight - 100 - _bottomPadding;
    if (ballY > bottomBoundary) {
      ballY = bottomBoundary;
      velocityY = -velocityY * 0.8;
    }
  }

  /// Generuje przeszkody z dziurami
  void _generateObstacles() {
    obstacles.clear();

    if (screenWidth == 0 || screenHeight == 0) {
      return;
    }

    const int obstacleCount = 8;
    const double obstacleHeight = 16.0; // Grubość przeszkody
    const double holeWidth = 80.0; // Szerokość dziury
    final double availableHeight = screenHeight - 100 - _bottomPadding - 60;
    final double spacing = availableHeight / (obstacleCount + 1);

    for (int i = 0; i < obstacleCount; i++) {
      final double y = 60 + spacing * (i + 1) - 50.0;
      
      // Losowe położenie dziury w przeszkodzie
      final double minHoleX = holeWidth / 2 + 20;
      final double maxHoleX = screenWidth - holeWidth / 2 - 20;
      final double holeX = minHoleX + _random.nextDouble() * (maxHoleX - minHoleX);

      obstacles.add(Obstacle(
        x: 0,
        y: y,
        width: screenWidth,
        height: obstacleHeight,
        holeX: holeX,
        holeWidth: holeWidth,
      ));
    }
  }

  /// Obsługuje kolizje kulki z przeszkodami (uwzględnia dziury)
  void _handleObstacleCollisions() {
    const double ballRadius = 15.0;

    for (final obstacle in obstacles) {
      final double obstacleTop = obstacle.y;
      final double obstacleBottom = obstacle.y + obstacle.height;
      final double holeLeft = obstacle.holeX - obstacle.holeWidth / 2;
      final double holeRight = obstacle.holeX + obstacle.holeWidth / 2;

      // Sprawdź, czy kulka jest na wysokości przeszkody
      final bool isAtObstacleHeight = ballY >= obstacleTop - ballRadius && 
                                      ballY <= obstacleBottom + ballRadius;

      if (isAtObstacleHeight) {
        // Sprawdź, czy kulka jest poza dziurą
        final bool isOutsideHole = ballX < holeLeft || ballX > holeRight;

        if (isOutsideHole) {
          // Odbij kulkę od przeszkody
          if (ballY < obstacleTop + obstacle.height / 2) {
            // Odbicie od góry przeszkody
            ballY = obstacleTop - ballRadius;
            velocityY = -velocityY * 0.8;
          } else {
            // Odbicie od dołu przeszkody
            ballY = obstacleBottom + ballRadius;
            velocityY = -velocityY * 0.8;
          }
        }
      }
    }
  }
}


