// Copyright (c) 2015, Alden Ozburn. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';

Fish fish; // Initial fish for legacy
List<Fish> school; // School of fish
int mouseX = 0; // The x position of the mouse
int mouseY = 0; // The y position of the mouse
num lastFrame = 0.0; // Time count for animation deltas
final int fps = 60; // Frames per second
final double interval = 1000 / fps; // Animation interval
Random rand = new Random(); // Fish property randomization
ParagraphElement count; //

enum Dir { Left, Right } // Fish direction for image choosing

void main() {
  fish = new Fish(querySelector('#fish'));
  school = [];
  school.add(fish);
  count = querySelector('#count');
  count.text = 1.toString();

  // Set the bait the current mouse location
  document.onMouseMove.listen((e) {
    int x = e.client.x;
    int y = e.client.y;
    if (x != null) mouseX = x;
    if (y != null) mouseY = y;
    school.forEach((Fish fish) => fish.setBait(mouseX, mouseY));
  });

  // spawn a new fish when space is pressed
  window.onKeyPress.listen((KeyboardEvent e) {
    switch (e.keyCode) {
      case KeyCode.SPACE:
        spawn();
        break;
      default:
        break;
    }
  });

  // Randomize fish bait when the mouse leaver
  document.onMouseLeave.listen((e) {
    school.forEach((Fish fish) => fish.setBait(
        rand.nextInt(window.innerWidth) + 1,
        rand.nextInt(window.innerHeight) + 1));
  });

  window.animationFrame.then(loop);
}

/// Recursive loop for animation
void loop(num delta) {
  if (delta - lastFrame > interval) {
    school.forEach((fish) => fish.animate());
    lastFrame = delta;
  }
  window.animationFrame.then(loop);
}

/// Spawn a new fish and add it to the school
void spawn() {
  ImageElement fish = new ImageElement()
    ..classes.add('abs')
    ..src = "media/fish_right.png"
    ..onClick.listen((e) {
      window.location.href =
          'https://upload.wikimedia.org/wikipedia/commons/c/c3/Bludger_(fish).png';
    });
  document.body.children.add(fish);
  Fish egg = new Fish(
      fish,
      rand.nextDouble() + 1,
      60 * rand.nextDouble() + 20 + school.length * 2,
      40 * rand.nextDouble() + 10 + school.length / 2);
  egg.setBait(mouseX, mouseY);
  school.add(egg);
  count.text = school.length.toString();
}

class Fish {
  static String resName(String dir) => "media/fish_${dir}.png";
  static String leftImg = resName('left');
  static String rightImg = resName('right');

  ImageElement fish; // Fish image
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

  Fish(ImageElement fish,
      [double spf = 1.0, double ampX = 40.0, double ampY = 30.0]) {
    this.fish = fish;
    width = 0;
    height = 0;
    isRight = true;
    fish.style.src = rightImg;
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
      fish.src = leftImg;
      isRight = false;
    }
    if (dir == Dir.Right && !isRight) {
      fish.src = rightImg;
      isRight = true;
    }
  }

  /// Perform one step of animation
  void animate() {
    // TODO better distribution
    // TODO acceleration and deceleration, especially for fast turns

    width = fish.client.width;
    height = fish.client.height;

    int diffX = max(fishX, baitX) - min(fishX, baitX);
    int diffY = max(fishY, baitY) - min(fishY, baitY);

    double radius = 5.0;

    double deltaX = 0.0;
    double deltaY = 1.0;

    // Preventing divide by zero
    if (diffX != 0) {
      double ratioYtoX = diffY / diffX;
      deltaX = sqrt(pow(radius, 2) / (1 + pow(ratioYtoX, 2)));
      deltaY = deltaX * ratioYtoX;
    }

    // Set tolerances to reduce jitter
    int tolX = 3;
    int tolY = 3;

    // Set the appropriate image
    if (baitX > fishX) {
      setImg(Dir.Right);
    } else if (baitX < fishX) {
      setImg(Dir.Left);
    }

    double moveX = 0.0;
    double moveY = 0.0;

    // Determine the basic x delta
    if (baitX > fishX + tolX + (width / 2)) {
      moveX = deltaX;
    } else if (baitX < fishX - tolX - (width / 2)) {
      moveX = -deltaX;
    }

    // Determine the basic y delta
    if (baitY > fishY + tolY) {
      moveY = deltaY;
    } else if (baitY < fishY - tolY) {
      moveY = -deltaY;
    }

    // Account for the speed factor
    moveX *= spf * 2;
    moveY *= spf * 2;

    // Apply the move to the basic fish coordinates
    fishX += moveX;
    fishY += moveY;

    // Determine the new positions accounting for undulation
    int posX = (fishX - (width / 2) + ampX * sin(time / 8)).round();
    int posY = (fishY - (height / 2) + ampY * sin(time)).round();

    fish.style.left = '${posX}px';
    fish.style.top = '${posY}px';

    time += 0.1 % (2 * PI);
  }
}
