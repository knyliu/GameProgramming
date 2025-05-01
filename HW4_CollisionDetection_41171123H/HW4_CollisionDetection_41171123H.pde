interface NPC {
  void update();
  void display();
  boolean checkCollision(Player p);
}
interface Collidable {
  boolean checkCollision(Player p);
}

class Record {
  int s1, s2;
  Record(int s1_, int s2_) { s1 = s1_; s2 = s2_; }
}

class Wall {
  float x, y, w, h;
  Wall(float x, float y, float w, float h) {
    this.x = x; this.y = y; this.w = w; this.h = h;
  }
  void display() {
    fill(150); noStroke();
    rect(x, y, w, h);
  }
  boolean contains(PVector p) {
    return p.x > x && p.x < x + w && p.y > y && p.y < y + h;
  }
}

Player         p1, p2;
ArrayList<NPC> npcs;
Treasure       chest1, chest2;
ArrayList<Wall> walls = new ArrayList<Wall>();
ArrayList<Record> history = new ArrayList<Record>();

int score1 = 0, score2 = 0, lives = 3;
int startTime, totalTime = 30_000;
final int MAX_HISTORY = 50;
boolean gameStarted = false;
int btnW = 160, btnH = 40;

// sprite scale & assets
float spriteScale = 0.5;
PImage[] monsterImgs = new PImage[3];
PImage boyNorm, boyHappy, boySurp;
PImage girlNorm, girlHappy, girlSurp;
PImage boyBox, girlBox;
PFont fontTC;

void setup() {
  size(800, 600);
  // load Traditional Chinese font
  fontTC = createFont("NotoSansTC-Regular.ttf", 18);
  textFont(fontTC);
  // load sprites
  monsterImgs[0] = loadImage("monster_1.png");
  monsterImgs[1] = loadImage("monster_2.png");
  monsterImgs[2] = loadImage("monster_3.png");
  boyNorm     = loadImage("boy_normal.png");
  boyHappy    = loadImage("boy_happy.png");
  boySurp     = loadImage("boy_surprised.png");
  girlNorm    = loadImage("girl_normla.png");
  girlHappy   = loadImage("girl_happy.png");
  girlSurp    = loadImage("girl_surprised.png");
  boyBox      = loadImage("boy_box.png");
  girlBox     = loadImage("girl_box.png");
  // create two walls
  walls.add(new Wall(200, 150, 400, 20));
  walls.add(new Wall(300, 350, 20, 200));
}

void draw() {
  if (!gameStarted) {
    background(30);
    drawIntro();
    return;
  }

  int elapsed   = millis() - startTime;
  int remaining = max(totalTime - elapsed, 0);

  // dynamic background: desaturated blue → desaturated red
  if (remaining > 0) {
    float t = constrain(elapsed / (float)totalTime, 0, 1);
    color c1 = color(80, 80, 200);
    color c2 = color(200, 80, 80);
    background(lerpColor(c1, c2, t));
  } else {
    background(200, 80, 80);
  }

  int seconds = (int)ceil(remaining / 1000.0f);

  // countdown
  fill(255);
  textSize(24);
  textAlign(RIGHT, TOP);
  text("Time: " + seconds, width - 20, 20);

  if (remaining > 0) {
    drawHUD();
    // draw walls
    for (Wall w : walls) w.display();

    // chest1 for player1
    if (chest1.checkCollision(p1)) {
      score1 += 10;
      p1.triggerHappy(30);
    }
    chest1.updateEffect();
    chest1.display();

    // chest2 for player2
    if (chest2.checkCollision(p2)) {
      score2 += 10;
      p2.triggerHappy(30);
    }
    chest2.updateEffect();
    chest2.display();

    // NPCs
    for (NPC npc : npcs) {
      npc.update();
      npc.display();
      if (npc.checkCollision(p1)) {
        lives--;
        p1.triggerCry(30);
        p1.triggerFreeze(3000);
      }
      if (npc.checkCollision(p2)) {
        lives--;
        p2.triggerCry(30);
        p2.triggerFreeze(3000);
      }
    }

    // player-player collision
    if (PVector.dist(p1.pos, p2.pos) < 40) {
      score1 = score2 = 0;
      p1.triggerCry(30);
      p2.triggerCry(30);
    }

    // update & draw players
    p1.update(); p1.display(); p1.updateCry(); p1.updateHappy();
    p2.update(); p2.display(); p2.updateCry(); p2.updateHappy();

  } else {
    drawEndScreen();
  }
}

void drawIntro() {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("歡迎來到雙人競賽碰撞遊戲", width/2, height/2 - 100);
  textSize(24);
  text("遊戲特色：", width/2, height/2 - 60);
  textSize(18);
  textAlign(LEFT, TOP);
  String[] features = {
    "41171123H 劉彥谷",
    "1. 30秒倒數計時",
    "2. 玩家1：方向鍵 控制(請將電腦鍵盤語言設定為英文再開始)",
    "3. 玩家2：WASD 控制(請將電腦鍵盤語言設定為英文再開始)",
    "4. 12隻怪物，3種圖案各3隻",
    "5. 2道固定障礙牆",
    "6. 撞到NPC凍結3秒，保持驚訝表情；碰到寶箱喜悅表情+10分",
    "7. 玩家互撞分數歸零",
    "8. 遊戲分數紀錄",
    "9. 撿箱後寶箱隨機移動",
    "10. 基於時間變化的動態背景 & 怪物加速",
    "11. 開始介面及結束界面和相關按鈕及說明",
    "12. 設計為雙人競賽同步操作增添樂趣"
  };
  for (int i = 0; i < features.length; i++) {
    text(features[i], width/2 - 200, height/2 - 30 + i*24);
  }
  textAlign(CENTER, CENTER);
  int bx = width/2, by = height/2 - 180;
  rectMode(CENTER);
  fill(50); stroke(200);
  rect(bx, by, btnW, btnH, 5);
  fill(255);
  textSize(20);
  text("開始遊戲", bx, by);
  rectMode(CORNER);
}

void drawHUD() {
  fill(255);
  textSize(18);
  textAlign(LEFT, TOP);
  text("P1: " + score1, 20, 20);
  text("P2: " + score2, 20, 40);
  //text("Lives: " + lives, 20, 60);
}

void drawEndScreen() {
  fill(255);
  textFont(fontTC);
  textAlign(CENTER, CENTER);
  int bx = width/2, by = height/2 - 80;
  rectMode(CENTER);
  fill(50); stroke(200);
  rect(bx, by, btnW, btnH, 5);
  fill(255);
  textSize(20);
  text("重玩一次", bx, by);
  rectMode(CORNER);

  textSize(32);
  text("P1: " + score1 + "   P2: " + score2, width/2, by + btnH + 40);

  int rows = min(history.size(), 5);
  int cellW = 120, cellH = 30;
  int tx = width/2 - cellW, ty = by + btnH + 80;
  stroke(255); noFill();
  rect(tx, ty, cellW*2, cellH*(rows+1));
  line(tx + cellW, ty, tx + cellW, ty + cellH*(rows+1));
  for (int i = 1; i <= rows+1; i++) {
    line(tx, ty + cellH*i, tx + cellW*2, ty + cellH*i);
  }
  textSize(16);
  for (int i = 0; i < rows; i++) {
    Record r = history.get(history.size() - rows + i);
    float y = ty + cellH*(i+1) + cellH/2;
    textAlign(CENTER, CENTER);
    text(r.s1, tx + cellW/2,         y);
    text(r.s2, tx + cellW + cellW/2, y);
  }
}

void mousePressed() {
  if (!gameStarted) {
    int bx = width/2, by = height/2 - 180;
    if (mouseX >= bx-btnW/2 && mouseX <= bx+btnW/2 &&
        mouseY >= by-btnH/2 && mouseY <= by+btnH/2) {
      gameStarted = true;
      resetGame();
    }
  } else if (millis() - startTime >= totalTime) {
    int bx = width/2, by = height/2 - 80;
    if (mouseX >= bx-btnW/2 && mouseX <= bx+btnW/2 &&
        mouseY >= by-btnH/2 && mouseY <= by+btnH/2) {
      history.add(new Record(score1, score2));
      if (history.size() > MAX_HISTORY) history.remove(0);
      resetGame();
    }
  }
}

void resetGame() {
  score1 = score2 = 0;
  lives = 3;
  startTime = millis();
  // Player1: arrow keys
  p1 = new Player(new PVector(width*0.25, height*0.5),
                  boyNorm, boyHappy, boySurp);
  // Player2: WASD
  p2 = new WASDPlayer(new PVector(width*0.75, height*0.5),
                       girlNorm, girlHappy, girlSurp);
  chest1 = new Treasure(new PVector(random(50,width-50), random(50,height-50)), boyBox);
  chest2 = new Treasure(new PVector(random(50,width-50), random(50,height-50)), girlBox);
  // spawn 3 of each monster
  npcs = new ArrayList<NPC>();
  for (int i = 0; i < monsterImgs.length; i++) {
    for (int j = 0; j < 3; j++) {
      PVector pos = new PVector(random(50,width-50), random(50,height-50));
      npcs.add(new Walker(pos, monsterImgs[i]));
    }
  }
}

// ===== Player classes =====
class Player {
  PVector pos;
  PImage imgNorm, imgHappy, imgSurp;
  int cryTimer=0, happyTimer=0;
  boolean frozen=false;
  int freezeEnd=0;

  Player(PVector p, PImage n, PImage h, PImage s) {
    pos = p.copy();
    imgNorm = n; imgHappy = h; imgSurp = s;
  }
  void update() {
    if (frozen) {
      if (millis() > freezeEnd) frozen = false;
      else return;
    }
    PVector prev = pos.copy();
    if (keyPressed) {
      if (keyCode==LEFT)  pos.x -= 3;
      if (keyCode==RIGHT) pos.x += 3;
      if (keyCode==UP)    pos.y -= 3;
      if (keyCode==DOWN)  pos.y += 3;
    }
    for (Wall w : walls) {
      if (w.contains(pos)) { pos.set(prev); break; }
    }
    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);
  }
  void display() {
    imageMode(CENTER);
    PImage toDraw = frozen   ? imgSurp
                   : happyTimer>0 ? imgHappy
                   : cryTimer>0   ? imgSurp
                                  : imgNorm;
    float w = toDraw.width * spriteScale;
    float h = toDraw.height * spriteScale;
    image(toDraw, pos.x, pos.y, w, h);
    imageMode(CORNER);
  }
  void triggerCry(int d)   { cryTimer = d; }
  void updateCry()         { if (cryTimer>0) cryTimer--; }
  void triggerHappy(int d) { happyTimer = d; }
  void updateHappy()       { if (happyTimer>0) happyTimer--; }
  void triggerFreeze(int d){ frozen = true; freezeEnd = millis() + d; }
}

class WASDPlayer extends Player {
  WASDPlayer(PVector p, PImage n, PImage h, PImage s) {
    super(p,n,h,s);
  }
  @Override
  void update() {
    if (frozen) {
      if (millis()>freezeEnd) frozen=false;
      else return;
    }
    PVector prev = pos.copy();
    if (keyPressed) {
      if (key=='A'||key=='a') pos.x -= 3;
      if (key=='D'||key=='d') pos.x += 3;
      if (key=='W'||key=='w') pos.y -= 3;
      if (key=='S'||key=='s') pos.y += 3;
    }
    for (Wall w : walls) {
      if (w.contains(pos)) { pos.set(prev); break; }
    }
    pos.x = constrain(pos.x, 0, width);
    pos.y = constrain(pos.y, 0, height);
  }
}

class Walker implements NPC {
  PVector pos, vel;
  PImage img;
  float  baseSpeed;
  Walker(PVector p, PImage sprite) {
    pos = p.copy();
    vel = PVector.random2D().mult(2);
    img = sprite;
    baseSpeed = vel.mag();
  }
  public void update() {
    // increase speed over time
    float t = constrain((millis() - startTime) / (float)totalTime, 0, 1);
    vel.setMag(baseSpeed * (1 + t));
    pos.add(vel);
    // bounce off walls
    for (Wall w : walls) {
      if (w.contains(pos)) {
        vel.mult(-1);
        pos.add(vel);
        break;
      }
    }
    if (pos.x < 0 || pos.x > width)   vel.x *= -1;
    if (pos.y < 0 || pos.y > height)  vel.y *= -1;
  }
  public void display() {
    imageMode(CENTER);
    float w = img.width * spriteScale;
    float h = img.height * spriteScale;
    image(img, pos.x, pos.y, w, h);
    imageMode(CORNER);
  }
  public boolean checkCollision(Player p) {
    float r = max(img.width, img.height) * spriteScale / 2;
    return PVector.dist(pos, p.pos) < r;
  }
}

class Treasure implements Collidable {
  PVector pos;
  PImage img;
  int effectTimer = 0;
  Treasure(PVector p, PImage sprite) {
    pos = p.copy();
    img = sprite;
  }
  public void display() {
    imageMode(CENTER);
    float w = img.width * spriteScale;
    float h = img.height * spriteScale;
    image(img, pos.x, pos.y, w, h);
    imageMode(CORNER);
    if (effectTimer > 0) {
      fill(255, 200, 0, 200);
      textSize(24);
      textAlign(CENTER, CENTER);
      text("+10", pos.x, pos.y - h/2 - 10);
    }
  }
  public boolean checkCollision(Player p) {
    float r = max(img.width, img.height) * spriteScale / 2;
    if (PVector.dist(pos, p.pos) < r) {
      effectTimer = 30;
      pos.x = random(50, width - 50);
      pos.y = random(50, height - 50);
      return true;
    }
    return false;
  }
  void updateEffect() {
    if (effectTimer > 0) effectTimer--;
  }
}
