ArrayList<Gift> gifts = new ArrayList<>();
ArrayList<Snowflake> snowflakes = new ArrayList<>();
ArrayList<Cloud> clouds = new ArrayList<>();
PFont zhFont;

void setup() {
  size(600, 400);
  surface.setTitle("HW1_Vector Drawing and Shape Practice");
  surface.setLocation(200, 100);
  background(135, 206, 235);
  zhFont = createFont("NotoSansTC-Regular.ttf", 16);

  // Initialize snowflakes
  for (int i = 0; i < 50; i++) {
    snowflakes.add(new Snowflake(random(width), random(height)));
  }

  // Initialize clouds
  for (int i = 0; i < 3; i++) {
    clouds.add(new Cloud(random(width), random(50, 150)));
  }
}

void draw() {
  background(135, 206, 235);
  drawSun();
  drawClouds();
  drawSnowfall();
  drawScene();
  drawSnowman(250, 250);
  drawGifts();
  drawElf(500, 280);
  drawText();
}

void drawSun() {
  fill(255, 204, 0);
  ellipse(width - 80, 80, 60, 60);
  
  // Draw sun rays
  stroke(255, 204, 0);
  for (int i = 0; i < 12; i++) {
    float angle = TWO_PI / 12 * i;
    float x1 = (width - 80) + cos(angle) * 35;
    float y1 = 80 + sin(angle) * 35;
    float x2 = (width - 80) + cos(angle) * 50;
    float y2 = 80 + sin(angle) * 50;
    line(x1, y1, x2, y2);
  }
  noStroke();
}

void drawClouds() {
  for (Cloud cloud : clouds) {
    cloud.update();
    cloud.display();
  }
}

void drawSnowfall() {
  for (int i = snowflakes.size() - 1; i >= 0; i--) {
    Snowflake s = snowflakes.get(i);
    s.update();
    s.display();
  }
}

void drawScene() {
  // Ground
  fill(34, 139, 34);
  rect(0, 300, width, 100);

  // Multiple Christmas trees
  drawTree(100, 300);
  drawTree(200, 300);
  drawTree(300, 300);
  drawTree(400, 300);
}

void drawTree(float x, float y) {
  fill(139, 69, 19);
  rect(x - 10, y - 50, 20, 50);
  fill(34, 139, 34);
  triangle(x - 40, y - 40, x, y - 90, x + 40, y - 40);
  triangle(x - 35, y - 60, x, y - 110, x + 35, y - 60);
  triangle(x - 30, y - 80, x, y - 130, x + 30, y - 80);
}

void drawSnowman(float x, float y) {
  fill(255);
  ellipse(x, y + 40, 60, 60);
  ellipse(x, y - 10, 40, 40);
  ellipse(x, y - 50, 30, 30);

  // Eyes
  fill(0);
  ellipse(x - 5, y - 55, 5, 5);
  ellipse(x + 5, y - 55, 5, 5);

  // Carrot nose
  fill(255, 165, 0);
  triangle(x, y - 50, x + 10, y - 48, x, y - 45);

  // Buttons
  fill(0);
  ellipse(x, y - 30, 5, 5);
  ellipse(x, y - 10, 5, 5);
  ellipse(x, y + 10, 5, 5);

  // Arms
  stroke(139, 69, 19);
  strokeWeight(3);
  line(x - 20, y - 10, x - 50, y - 30);
  line(x + 20, y - 10, x + 50, y - 30);
  noStroke();
}

void drawGifts() {
  for (int i = gifts.size() - 1; i >= 0; i--) {
    Gift g = gifts.get(i);
    g.update(gifts);
    g.display();
  }
}

void mousePressed() {
  gifts.add(new Gift(mouseX, 0, color(random(255), random(255), random(255))));
}

void drawText() {
  fill(0);
  textSize(16);
  textFont(zhFont); // Use the Traditional Chinese font
  text("HW1_向量繪圖造型練習, 41171123H, 劉彥谷", 10, 20);
  text("點選畫面會有禮物掉落", 10, 43);
}

// Cloud
class Cloud {
  float x, y;
  float speed;

  Cloud(float x, float y) {
    this.x = x;
    this.y = y;
    this.speed = random(0.5, 1.5);
  }

  void update() {
    x += speed;
    if (x > width + 50) {
      x = -50;
    }
  }

  void display() {
    fill(255);
    noStroke();
    ellipse(x, y, 50, 30);
    ellipse(x + 20, y - 10, 40, 25);
    ellipse(x - 20, y - 10, 40, 25);
  }
}

// Gift
class Gift {
  float x, y;
  color c;
  float speed;
  float height;
  boolean isStopped;

  Gift(float x, float y, color c) {
    this.x = x;
    this.y = y;
    this.c = c;
    this.speed = random(2, 5);
    this.height = 30;
    this.isStopped = false;
  }

  void update(ArrayList<Gift> gifts) {
    if (!isStopped) {
      y += speed;
      float targetY = findStackHeight(gifts);
      if (y >= targetY) {
        y = targetY;
        isStopped = true;
      }
    }
  }

  float findStackHeight(ArrayList<Gift> gifts) {
    float maxHeight = 300;
    for (Gift g : gifts) {
      if (g != this && g.isStopped && abs(g.x - this.x) < 30) {
        maxHeight = min(maxHeight, g.y - this.height);
      }
    }
    return maxHeight;
  }

  void display() {
    fill(c);
    rect(x, y, 30, 30);
    fill(255);
    rect(x + 12, y, 6, 30);
    rect(x, y + 12, 30, 6);
    fill(255, 0, 0);
    ellipse(x + 15, y - 5, 15, 10);
  }
}

// Snowflake
class Snowflake {
  float x, y;
  float speed;
  float size;

  Snowflake(float x, float y) {
    this.x = x;
    this.y = y;
    this.speed = random(1, 3);
    this.size = random(3, 6);
  }

  void update() {
    y += speed;
    if (y > height) {
      y = 0;
      x = random(width);
    }
  }

  void display() {
    fill(255);
    noStroke();
    ellipse(x, y, size, size);
  }
}

// Elf
void drawElf(float x, float y) {
  // Face
  fill(255, 224, 189);
  ellipse(x, y - 30, 30, 30); // Head

  // Eyes
  fill(0);
  ellipse(x - 7, y - 35, 5, 5);
  ellipse(x + 7, y - 35, 5, 5);

  // Smile
  noFill();
  stroke(0);
  arc(x, y - 25, 10, 5, 0, PI);

  // Hat
  fill(0, 128, 0); // Green
  triangle(x - 20, y - 40, x, y - 80, x + 20, y - 40);

  // Body
  noStroke();
  fill(144, 238, 144); // Light green
  rect(x - 15, y - 15, 30, 50);

  // Arms
  stroke(255, 224, 189);
  strokeWeight(3);
  line(x - 15, y + 10, x - 30, y + 20);
  line(x + 15, y + 10, x + 30, y + 20);

  // Legs
  stroke(0);
  strokeWeight(5);
  line(x - 7, y + 40, x - 7, y + 50);
  line(x + 7, y + 40, x + 7, y + 50);
}
