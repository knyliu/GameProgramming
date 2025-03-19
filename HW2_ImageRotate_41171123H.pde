PImage pSun, pEarth, pMoon;  // Load sun, earth, and moon images
boolean swapped = false;     // In interactive mode, image swap status: false -> default (sun+earth), true -> swapped (earth+moon)
boolean simulationMode = false;  // Simulation mode: sun follows the mouse, earth orbits, moon orbits
boolean dragMode = false;        // Drag mode (Y mode): only allow dragging of the moon

// Interactive mode parameters
float orbitAngle = 0;        // Orbit angle for interactive mode
float customRotation = 0;    // Custom vector shape's rotation angle

// Simulation mode parameters
float simulationEarthAngle = 0;
float simulationMoonAngle = 0;

// **Earth and Moon spin angles**
float earthSpinAngle = 0;
float moonSpinAngle = 0;

PFont myFont;                // Custom font

// Star effects
int starCount = 150;
Star[] stars = new Star[starCount];

// Planet positions for drag mode (using center points)
// In drag mode, the sun and earth are fixed, only the moon can be moved
PVector sunPos, earthPos, moonPos;
float moonOrbitRadiusDrag;  // Fixed orbit radius of the moon relative to the earth

// Currently dragged planet: 0 = none, 1 = sun, 2 = earth, 3 = moon
int draggingPlanet = 0;

// Used to calculate mouse movement speed, and change background color
float prevMouseX, prevMouseY;

void setup() {
  size(800, 600);
  
  // Load images (make sure the image files are placed in the data folder)
  pSun = loadImage("sun.png");
  pEarth = loadImage("earth.png");
  pMoon = loadImage("moon.png");
  
  // Enlarge the images while preserving transparency
  pSun.resize(200, 200);    // Increase sun size
  pEarth.resize(120, 120);  // Increase earth size
  pMoon.resize(80, 80);     // Increase moon size
  
  // Load the /data/NotoSansTC-Regular.ttf font, with font size 16
  myFont = createFont("NotoSansTC-Regular.ttf", 16);
  textFont(myFont);
  textSize(16);
  fill(255);
  
  // Initialize stars
  for (int i = 0; i < starCount; i++) {
    stars[i] = new Star();
  }
  
  // Initialize planet positions for drag mode (using center points)
  sunPos = new PVector(150, height/2);
  earthPos = new PVector(width/2, height/2);
  // Set initial moon position closer to the earth (e.g., 100 pixels)
  moonPos = new PVector(width/2 + 100, height/2);
  // Fixed moon orbit radius (approximately 100 pixels)
  moonOrbitRadiusDrag = PVector.dist(earthPos, moonPos);
  
  // Initialize previous mouse position
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}

void draw() {
  // Calculate mouse movement speed
  float mouseSpeed = dist(mouseX, mouseY, prevMouseX, prevMouseY);
  // Map blue component from 0 (black background when mouse is stationary) to 30 (deep blue when moving fast)
  float blueIntensity = map(mouseSpeed, 0, 20, 0, 30);
  blueIntensity = constrain(blueIntensity, 0, 30);
  background(0, 0, blueIntensity);
  prevMouseX = mouseX;
  prevMouseY = mouseY;
  
  // Draw stars (fixed size 3 pixels, unaffected by mouse movement)
  for (int i = 0; i < starCount; i++) {
    stars[i].update();
    stars[i].display();
  }
  
  // Display assignment name, student ID, and student name in the top-left corner
  fill(255);
  text("HW2_2D點陣彩圖置入及換圖", 10, 20);
  text("學號: 41171123H   姓名: 劉彥谷", 10, 40);
  text("按下右鍵可以切換顯示星球", 10, 60);
  text("移動滑鼠時背景顏色改變且星球跟隨", 10, 80);
  text("按下X進入三顆星球模式(請注意鍵盤需切換為英文)", 10, 100);
  text("按下Y進入教育模式(請注意鍵盤需切換為英文)", 10, 120);
  
  // Update Earth and Moon spin angles
  earthSpinAngle += 0.02;
  moonSpinAngle += 0.03;
  
  if (dragMode) {
    // Y mode (drag mode): Sun and Earth are fixed, only the moon can move along an orbit centered on the Earth
    
    // Sun (no spin)
    image(pSun, sunPos.x - pSun.width/2, sunPos.y - pSun.height/2);
    
    // Earth (spinning)
    pushMatrix();
      translate(earthPos.x, earthPos.y);
      rotate(earthSpinAngle);
      image(pEarth, -pEarth.width/2, -pEarth.height/2);
    popMatrix();
    
    // Moon (spinning)
    pushMatrix();
      translate(moonPos.x, moonPos.y);
      rotate(moonSpinAngle);
      image(pMoon, -pMoon.width/2, -pMoon.height/2);
    popMatrix();
    
    // Draw helper line: connect Earth's center and Moon's center
    stroke(255, 150);
    strokeWeight(2);
    line(earthPos.x, earthPos.y, moonPos.x, moonPos.y);
    
    // Draw helper circle: display the orbit on which the moon can move
    noFill();
    stroke(255, 100);
    ellipse(earthPos.x, earthPos.y, moonOrbitRadiusDrag*2, moonOrbitRadiusDrag*2);
    
    // Check if the alignment qualifies as an annular eclipse
    if (checkEclipse()) {
      fill(255);
      text("日環蝕簡介：當月亮無法完全遮蔽太陽，形成美麗的光環現象。", 50, height - 50);
    }
    
    // Hint text
    fill(255);
    text("拖曳月亮於軌道上排列（太陽與地球固定）", 10, height - 10);
    
  } else if (simulationMode) {
    // Simulation mode: Sun follows the mouse, Earth orbits around the Sun, Moon orbits around the Earth
    float centerX = mouseX;
    float centerY = mouseY;
    
    // Sun (no spin)
    image(pSun, centerX - pSun.width/2, centerY - pSun.height/2);
    
    simulationEarthAngle += 0.01;
    simulationMoonAngle += 0.03;
    
    float simMargin = 60;  // Larger margin
    float earthOrbitRadius = pSun.width/2 + pEarth.width/2 + simMargin;
    float earthX = centerX + earthOrbitRadius * cos(simulationEarthAngle);
    float earthY = centerY + earthOrbitRadius * sin(simulationEarthAngle);
    
    // Earth (orbiting + spinning)
    pushMatrix();
      translate(earthX, earthY);
      rotate(earthSpinAngle);
      image(pEarth, -pEarth.width/2, -pEarth.height/2);
    popMatrix();
    
    float moonOrbitRadius = pEarth.width/2 + pMoon.width/2 + 10;
    float moonX = earthX + moonOrbitRadius * cos(simulationMoonAngle);
    float moonY = earthY + moonOrbitRadius * sin(simulationMoonAngle);
    
    // Moon (orbiting + spinning)
    pushMatrix();
      translate(moonX, moonY);
      rotate(moonSpinAngle);
      image(pMoon, -pMoon.width/2, -pMoon.height/2);
    popMatrix();
    
    drawCustomShape(width/2, height - 100);
    
  } else {
    // Interactive mode: main image follows the mouse, right-click to switch image effect
    orbitAngle += 0.02;
    PImage mainImg, orbitImg;
    if (!swapped) {
      mainImg = pSun;
      orbitImg = pEarth;
    } else {
      mainImg = pEarth;
      orbitImg = pMoon;
    }
    
    // Draw mainImg first
    float mainX = mouseX;
    float mainY = mouseY;
    
    if (mainImg == pEarth) {
      // Earth (spinning)
      pushMatrix();
        translate(mainX, mainY);
        rotate(earthSpinAngle);
        image(pEarth, -pEarth.width/2, -pEarth.height/2);
      popMatrix();
    } else if (mainImg == pMoon) {
      // Moon (spinning)
      pushMatrix();
        translate(mainX, mainY);
        rotate(moonSpinAngle);
        image(pMoon, -pMoon.width/2, -pMoon.height/2);
      popMatrix();
    } else {
      // Sun (no spin)
      image(mainImg, mainX - mainImg.width/2, mainY - mainImg.height/2);
    }
    
    // Then draw orbitImg
    float margin = 20;
    float orbitRadius = (mainImg.width/2 + orbitImg.width/2 + margin);
    float centerX = mouseX;
    float centerY = mouseY;
    float orbitX = centerX + orbitRadius * cos(orbitAngle);
    float orbitY = centerY + orbitRadius * sin(orbitAngle);
    
    if (orbitImg == pEarth) {
      pushMatrix();
        translate(orbitX, orbitY);
        rotate(earthSpinAngle);
        image(pEarth, -pEarth.width/2, -pEarth.height/2);
      popMatrix();
    } else if (orbitImg == pMoon) {
      pushMatrix();
        translate(orbitX, orbitY);
        rotate(moonSpinAngle);
        image(pMoon, -pMoon.width/2, -pMoon.height/2);
      popMatrix();
    } else {
      image(orbitImg, orbitX - orbitImg.width/2, orbitY - orbitImg.height/2);
    }
    
    drawCustomShape(width/2, height/2);
    customRotation += 0.05;
  }
}

// Custom shape demonstration (omitted)
void drawCustomShape(float x, float y) {
  pushMatrix();
  translate(x, y);
  
  noStroke();
  fill(100, 200, 250, 0);
  rectMode(CENTER);
  rect(0, 0, 150, 100, 20);
  
  stroke(0, 0);
  strokeWeight(3);
  pushMatrix();
  rotate(customRotation);
  line(0, 0, 30, 0);
  popMatrix();
  
  popMatrix();
}

void mousePressed() {
  if (dragMode) {
    // In drag mode, only check if the moon is clicked
    if (isMouseOver(moonPos, pMoon)) {
      draggingPlanet = 3;
    }
  } else if (!simulationMode && mouseButton == RIGHT) {
    swapped = !swapped;
  }
}

void mouseDragged() {
  if (dragMode && draggingPlanet == 3) {
    // Restrict the moon's movement along a fixed orbit centered on the Earth
    PVector v = new PVector(mouseX - earthPos.x, mouseY - earthPos.y);
    v.normalize();
    v.mult(moonOrbitRadiusDrag);
    moonPos = PVector.add(earthPos, v);
  }
}

void mouseReleased() {
  if (dragMode) {
    draggingPlanet = 0;
  }
}

void keyPressed() {
  if (key == 'x' || key == 'X') {
    simulationMode = !simulationMode;
    if (simulationMode) dragMode = false;
  }
  if (key == 'y' || key == 'Y') {
    dragMode = !dragMode;
    if (dragMode) simulationMode = false;
  }
}

// Check if the mouse is over a planet image (determined by the image's center and dimensions)
boolean isMouseOver(PVector pos, PImage img) {
  return mouseX >= pos.x - img.width/2 && mouseX <= pos.x + img.width/2 &&
         mouseY >= pos.y - img.height/2 && mouseY <= pos.y + img.height/2;
}

// Check if the alignment qualifies as an annular eclipse (simple check): arranged as Sun, Moon, Earth, with the Moon between them
boolean checkEclipse() {
  float dSM = PVector.dist(sunPos, moonPos);   // Distance from Sun to Moon
  float dME = PVector.dist(moonPos, earthPos);   // Distance from Moon to Earth
  float dSE = PVector.dist(sunPos, earthPos);    // Distance from Sun to Earth
  float tolerance = 15;  // Adjustable tolerance value
  return (abs((dSM + dME) - dSE) < tolerance && dSM < dSE && dME < dSE);
}

// Star class: fixed size of 3 pixels, implements a twinkling effect
class Star {
  float x, y;
  float phase;
  float speed;
  
  Star() {
    x = random(width);
    y = random(height);
    phase = random(TWO_PI);
    speed = random(0.01, 0.05);
  }
  
  void update() {
    phase += speed;
  }
  
  void display() {
    float brightness = map(sin(phase), -1, 1, 50, 255);
    noStroke();
    fill(brightness);
    ellipse(x, y, 3, 3);
  }
}
