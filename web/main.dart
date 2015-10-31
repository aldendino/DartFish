// Copyright (c) 2015, Alden Ozburn. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math';

Fish fish;
List<Fish> school;
int mouseX = 0;
int mouseY = 0;
num start = 0.0;
final int fps = 120;
final double interval = 1000/fps;
Random rand = new Random();

enum Dir {Left, Right}

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
    switch(e.keyCode) {
      case KeyCode.SPACE:
        spawnFish();
        print(school.length + 1);
        break;
      default:
        break;
    }
  });

  window.animationFrame.then(loop);
}

void loop(num delta) {
  if (delta - start > interval) {
    fish.doAnimation();
    school.forEach((fish) => fish.doAnimation());
    start = delta;
  }
  window.animationFrame.then(loop);
}

void spawnFish() {
  DivElement fish = new DivElement()..classes.add('abs');
  ImageElement fishImg = new ImageElement()..src = "media/fish_right.png";
  fish.children.add(fishImg);
  document.body.children.add(fish);
  Fish egg = new Fish(fish, fishImg, rand.nextDouble() + 1);
  egg.setBait(mouseX, mouseY);
  school.add(egg);
}

class Fish {
  static String resName(String dir) => "media/fish_${dir}.png";
  static String leftImg = resName('left');
  static String rightImg = resName('right');

  DivElement fish;
  ImageElement fishImg;
  bool isRight = true;
  int width;
  int height;
  double fishX;
  double fishY;
  int baitX;
  int baitY;
  double time;
  double spf;

  Fish(DivElement fish, ImageElement fishImg, [double spf = 1]) {
    this.fish = fish;
    this.fishImg = fishImg;
    width  = 0;
    height = 0;
    fishImg.style.src = rightImg;
    fishX = 0.0;
    fishY = 0.0;
    baitX = 0;
    baitY = 0;
    time = 0.0;
    this.spf = spf;
  }

  void setBait(int x, int y) {
    baitX = x;
    baitY = y;
  }

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

  void doAnimation() {
    width  = fishImg.client.width;
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
    int amp = 10;

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

    if (baitY > fishY + tolY + amp){// + (width / 2)) {
      moveY = deltaY;
    } else if (baitY < fishY - tolY - amp){// - (width / 2)) {
      moveY = -deltaY;
    }

    moveX *= spf;
    moveY *= spf;

    moveY += amp * sin(time);

    fishX += moveX;
    fishY += moveY;

    int posX = (fishX - (width  / 2)).toInt();
    int posY = (fishY - (height / 2)).toInt();

    fish.style.left = '${posX}px';
    fish.style.top  = '${posY}px';

    time += 0.1;
  }
}