import 'dart:io';
import 'package:image/image.dart' as img;

// Background fill color sampled from assets/icon/app_icon.png.
const int _bgR = 27, _bgG = 77, _bgB = 74;
const int _tolerance = 60;

bool _isBackgroundLike(img.Pixel px) {
  if (px.a < 250) return true;
  final dr = (px.r - _bgR).abs();
  final dg = (px.g - _bgG).abs();
  final db = (px.b - _bgB).abs();
  return dr < _tolerance && dg < _tolerance && db < _tolerance;
}

void main() {
  final bytes = File('assets/icon/app_icon.png').readAsBytesSync();
  final src = img.decodePng(bytes)!;
  final w = src.width, h = src.height;
  final fg = img.Image.from(src);

  final visited = List.generate(h, (_) => List.filled(w, false));
  final queueX = <int>[];
  final queueY = <int>[];

  void seed(int x, int y) {
    if (visited[y][x]) return;
    visited[y][x] = true;
    queueX.add(x);
    queueY.add(y);
  }

  for (int x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (int y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }

  int removed = 0;
  int head = 0;
  while (head < queueX.length) {
    final x = queueX[head];
    final y = queueY[head];
    head++;
    final px = src.getPixel(x, y);
    if (!_isBackgroundLike(px)) continue;
    fg.setPixelRgba(x, y, 0, 0, 0, 0);
    removed++;
    const dx = [1, -1, 0, 0];
    const dy = [0, 0, 1, -1];
    for (int i = 0; i < 4; i++) {
      final nx = x + dx[i];
      final ny = y + dy[i];
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      if (visited[ny][nx]) continue;
      visited[ny][nx] = true;
      queueX.add(nx);
      queueY.add(ny);
    }
  }

  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(fg));
  print('removed $removed background pixels out of ${w * h}');
}
