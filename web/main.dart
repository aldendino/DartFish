// Copyright (c) 2015, Alden Ozburn. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';

Fish fish; // Initial fish for legacy
List<Fish> school; // School of fish
int mouseX = 0; // The x position of the mouse
int mouseY = 0; // The y position of the mouse
num lastFrame = 0.0; // Time count for animation deltas
final int fps = 120; // Frames per second
final double interval = 1000 / fps; // Animation interval
Random rand = new Random(); // Fish property randomization

enum Dir { Left, Right } // Fish direction for image choosing

void main() {
  fish = new Fish(querySelector('#fish'), querySelector('#fishImg'));
  school = [];

  document.onMouseMove.listen((e) {
    int x = e.client.x;
    int y = e.client.y;
    if (x != null) mouseX = x;
    if (y != null) mouseY = y;
    fish.setBait(mouseX, mouseY);
    school.forEach((Fish fish) => fish.setBait(mouseX, mouseY));
  });

  window.onKeyPress.listen((KeyboardEvent e) {
    switch (e.keyCode) {
      case KeyCode.SPACE:
        spawnFish();
        //print(school.length + 1);
        break;
      default:
        break;
    }
  });

  window.animationFrame.then(loop);
}

/// Recursive loop for animation
void loop(num delta) {
  if (delta - lastFrame > interval) {
    fish.animate();
    school.forEach((fish) => fish.animate());
    lastFrame = delta;
  }
  window.animationFrame.then(loop);
}

/// Spawn a new fish and add it to the school
void spawnFish() {
  DivElement fish = new DivElement()..classes.add('abs');
  ImageElement fishImg = new ImageElement()..src = "media/fish_right.png";
  fish.children.add(fishImg);
  document.body.children.add(fish);
  Fish egg = new Fish(fish, fishImg, rand.nextDouble() + 1,
      60 * rand.nextDouble() + 20, 40 * rand.nextDouble() + 10);
  egg.setBait(mouseX, mouseY);
  school.add(egg);
}

class Fish {
  static String resName(String dir) => "media/fish_${dir}.png";
  static String leftImg = resName('left');
  static String rightImg = resName('right');

  DivElement fish;
  ImageElement fishImg;
  bool isRight; // Whether or not the fish is facing right
  int width; // Width of the fish
  int height; // Height of the fish
  double fishX; // The x position the fish is centered on
  double fishY; // The y position the fish is centered on
  int baitX; // The x position that the fish is attracted to
  int baitY; // The y position that the fish is attracted to
  double time; // The time count that regulates undulation
  double spf; // Speed factor
  double ampX; // The horizontal undulation factor
  double ampY; // The vertical undulation factor

  Fish(DivElement fish, ImageElement fishImg,
      [double spf = 1.0, double ampX = 40.0, double ampY = 30.0]) {
    this.fish = fish;
    this.fishImg = fishImg;
    width = 0;
    height = 0;
    isRight = true;
    fishImg.style.src = rightImg;
    fishX = 0.0;
    fishY = 0.0;
    baitX = 0;
    baitY = 0;
    time = 2 * PI * rand.nextDouble();
    this.spf = spf;
    this.ampX = ampX;
    this.ampY = ampY;
  }

  /// Set up where the fish is heading
  void setBait(int x, int y) {
    baitX = x;
    baitY = y;
  }

  /// Change the image to match the fish's direction
  void setImg(Dir dir) {
    if (dir == Dir.Left && isRight) {
      fishImg.src = leftImg;
      isRight = false;
    }
    if (dir == Dir.Right && !isRight) {
      fishImg.src = rightImg;
      isRight = true;
    }
  }

  /// Perform one step of animation
  void animate() {
    width = fishImg.client.width;
    height = fishImg.client.height;

    int diffX = max(fishX, baitX) - min(fishX, baitX);
    int diffY = max(fishY, baitY) - min(fishY, baitY);

    double radius = 5.0;

    double deltaX = 0.0;
    double deltaY = 1.0;

    if (diffX != 0) {
      double ratioYtoX = diffY / diffX;
      deltaX = sqrt(pow(radius, 2) / (1 + pow(ratioYtoX, 2)));
      deltaY = deltaX * ratioYtoX;
    }

    double moveX = 0.0;
    double moveY = 0.0;

    int tolX = 5;
    int tolY = 5;

    if (baitX > fishX) {
      setImg(Dir.Right);
    } else if (baitX < fishX) {
      setImg(Dir.Left);
    }

    if (baitX > fishX + tolX + (width / 2)) {
      moveX = deltaX;
    } else if (baitX < fishX - tolX - (width / 2)) {
      moveX = -deltaX;
    }

    if (baitY > fishY + tolY) {
      moveY = deltaY;
    } else if (baitY < fishY - tolY) {
      moveY = -deltaY;
    }

    moveX *= spf;
    moveY *= spf;

    fishX += moveX;
    fishY += moveY;

    int posX = (fishX - (width / 2) + ampX * sin(time / 8)).toInt();
    int posY = (fishY - (height / 2) + ampY * sin(time)).toInt();

    fish.style.left = '${posX}px';
    fish.style.top = '${posY}px';

    time += 0.1 % (2 * PI);
  }
}
