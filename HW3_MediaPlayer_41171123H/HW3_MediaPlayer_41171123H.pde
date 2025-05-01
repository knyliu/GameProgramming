import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.effects.*;
import ddf.minim.analysis.*;
import java.io.File;
import javax.swing.JOptionPane;

Minim minim;
AudioPlayer player;
PFont myFont;
FFT fft;

float currentGain = 0;         // dB, Minim default 0 dB is original volume
float currentBalance = 0;      // -1.0 (left) ~ 1.0 (right), 0 means centered balance
boolean isMuted = false;
boolean isRepeating = false;

color SPOTIFY_GREEN = color(29, 185, 84);
color BG_DARK       = color(25, 20, 20);
color BTN_DARK      = color(40, 40, 40);
color TEXT_WHITE    = color(255);

boolean showMore = false;      // Whether to show additional function panel

// Flag for dragging the progress bar and desired position
boolean draggingProgress = false;
int desiredPosition = 0;

// Sleep timer related variables
boolean sleepTimerActive = false;
int sleepTimerDuration = 300000;  // Default 5 minutes (300,000 ms)
int sleepTimerStart = 0;          // Time when timer was started (millis)

// Playlist stored as an ArrayList for dynamic additions
ArrayList<String> playlist = new ArrayList<String>();
int currentTrack = 0;

// ArrayLists for main function buttons and additional function buttons
ArrayList<Button> mainButtons = new ArrayList<Button>();  
ArrayList<Button> moreButtons = new ArrayList<Button>();    

// Flag to record previous playing state (to detect natural song end)
boolean wasPlaying = false;

// === Custom Button class ===
class Button {
  float x, y, w, h;
  String label;
  boolean pressed = false;
  int id; // Button ID
  
  Button(float x, float y, float w, float h, String label, int id) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.id = id;
  }
  
  void display() {
    color baseColor = BTN_DARK;
    // If it's the Play/Pause button (id==22) and the player is playing,
    // or if it's the More button (id==25) and the panel is shown,
    // or if it's the Repeat button (id==10) and repeat is active, then use SPOTIFY_GREEN.
    if ((id == 22 && player != null && player.isPlaying()) ||
        (id == 25 && showMore) ||
        (id == 10 && isRepeating)) {
      baseColor = SPOTIFY_GREEN;
    }
    if (pressed) {
      baseColor = color(red(baseColor)+20, green(baseColor)+20, blue(baseColor)+20);
    }
    fill(baseColor);
    rect(x, y, w, h, 10);
    
    fill(TEXT_WHITE);
    textAlign(CENTER, CENTER);
    textSize(14);
    if (id == 22) {
      if (player != null && player.isPlaying()) {
        text("Pause", x + w/2, y + h/2);
      } else {
        text("Play", x + w/2, y + h/2);
      }
    } else {
      text(label, x + w/2, y + h/2);
    }
  }
  
  boolean isMouseOver() {
    return (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h);
  }
}

void setup() {
  size(800, 600);
  minim = new Minim(this);
  // Add initial default playlist (place music files in the data folder)
  playlist.add("pop-dance-positive-music.mp3");
  playlist.add("positive-pop-house.mp3");
  playlist.add("hard-sport-electronic.mp3");
  player = minim.loadFile(playlist.get(currentTrack));
  fft = new FFT(player.bufferSize(), player.sampleRate());
  
  myFont = createFont("NotoSansTC-Regular.ttf", 32);
  textFont(myFont);
  
  // --- Create main function buttons ---
  float btnW = 40;
  float btnH = 40;
  float gap = 10;
  int mainCount = 6;
  float totalWidth = mainCount * btnW + (mainCount - 1) * gap;
  // Right side effective area: x from 200 to 800 (600px wide)
  float startX = 200 + (600 - totalWidth) / 2;
  float btnY = height - 80;
  
  mainButtons.add(new Button(startX + (btnW + gap) * 0, btnY, btnW, btnH, "Prev", 20));
  mainButtons.add(new Button(startX + (btnW + gap) * 1, btnY, btnW, btnH, "Rew10", 21));
  mainButtons.add(new Button(startX + (btnW + gap) * 2, btnY, btnW, btnH, "Play", 22));
  mainButtons.add(new Button(startX + (btnW + gap) * 3, btnY, btnW, btnH, "Fwd10", 23));
  mainButtons.add(new Button(startX + (btnW + gap) * 4, btnY, btnW, btnH, "Next", 24));
  mainButtons.add(new Button(startX + (btnW + gap) * 5, btnY, btnW, btnH, "More", 25));
  
  // --- Create additional function buttons (vertically arranged on the right side) ---
  moreButtons.clear();
  int moreBtnW = 40;
  int moreBtnH = 40;
  int moreGap = 10;
  int startXMore = width - moreBtnW - 20;
  int startYMore = 100;
  moreButtons.add(new Button(startXMore, startYMore + 0*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Stop", 2));
  moreButtons.add(new Button(startXMore, startYMore + 1*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Restart", 4));
  moreButtons.add(new Button(startXMore, startYMore + 2*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Mute", 3));
  moreButtons.add(new Button(startXMore, startYMore + 3*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Vol-", 9));
  moreButtons.add(new Button(startXMore, startYMore + 4*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Vol+", 8));
  moreButtons.add(new Button(startXMore, startYMore + 5*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Left", 5));
  moreButtons.add(new Button(startXMore, startYMore + 6*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Right", 6));
  moreButtons.add(new Button(startXMore, startYMore + 7*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Stereo", 7));
  moreButtons.add(new Button(startXMore, startYMore + 8*(moreBtnH+moreGap), moreBtnW, moreBtnH, "Repeat", 10));
}

void drawSongList() {
  int listWidth = 200;
  int startY = 20;
  int itemHeight = 40;
  
  fill(30);
  noStroke();
  rect(0, 0, listWidth, height);
  
  for (int i = 0; i < playlist.size(); i++) {
    if (i == currentTrack) {
      fill(SPOTIFY_GREEN);
    } else {
      fill(70);
    }
    rect(0, startY + i * itemHeight, listWidth, itemHeight - 5);
    
    fill(TEXT_WHITE);
    textAlign(LEFT, CENTER);
    textSize(12);
    String name = playlist.get(i);
    int idx = name.lastIndexOf(File.separator);
    if (idx != -1) {
      name = name.substring(idx+1);
    }
    text(name, 10, startY + i * itemHeight + (itemHeight - 5) / 2);
  }
  
  // Display "Upload Music" option
  fill(100);
  rect(0, startY + playlist.size() * itemHeight, listWidth, itemHeight - 5);
  fill(TEXT_WHITE);
  textAlign(CENTER, CENTER);
  textSize(14);
  text("Upload Music", listWidth/2, startY + playlist.size() * itemHeight + (itemHeight - 5) / 2);
}

void drawSleepTimerButton() {
  // Define sleep timer button area at the upper right corner
  int btnW = 120;
  int btnH = 40;
  int btnX = width - btnW - 10;
  int btnY = 10;
  
  fill(50);
  rect(btnX, btnY, btnW, btnH, 10);
  
  fill(TEXT_WHITE);
  textAlign(CENTER, CENTER);
  textSize(14);
  
  if (sleepTimerActive) {
    int remaining = max(0, sleepTimerDuration - (millis() - sleepTimerStart));
    int seconds = (remaining / 1000) % 60;
    int minutes = remaining / 60000;
    String timeStr = nf(minutes, 2) + ":" + nf(seconds, 2);
    text("Sleep: " + timeStr, btnX + btnW/2, btnY + btnH/2);
  } else {
    text("Sleep Timer", btnX + btnW/2, btnY + btnH/2);
  }
}

void promptSleepTimer() {
  // Show input dialog for sleep timer duration in minutes
  String input = JOptionPane.showInputDialog("Enter sleep timer duration (minutes):");
  if (input != null && input.length() > 0) {
    try {
      int minutes = Integer.parseInt(input);
      sleepTimerDuration = minutes * 60000; // Convert to milliseconds
      sleepTimerActive = true;
      sleepTimerStart = millis();
    } catch (NumberFormatException e) {
      println("Please enter a valid number!");
    }
  }
}

void draw() {
  background(BG_DARK);
  
  // Check if sleep timer is active and time is up; if so, pause the player and disable the timer
  if (sleepTimerActive && millis() - sleepTimerStart >= sleepTimerDuration) {
    player.pause();
    sleepTimerActive = false;
  }
  
  // Draw left-side song list
  drawSongList();
  
  if (player != null) {
    fft.forward(player.mix);
  }
  
  // Display the current song name in the center of the right area (bounding box: x=200, width=600; y: height/2 - 50, height=100)
  fill(TEXT_WHITE);
  textAlign(CENTER, CENTER);
  textSize(16);
  text(playlist.get(currentTrack), 200, height/2 - 50, 600, 100);
  
  // Dynamic line effect
  int numLines = 12;
  for (int i = 0; i < numLines; i++) {
    float sx = noise(i * 0.1, frameCount * 0.02) * width;
    float sy = noise(i * 0.1 + 300, frameCount * 0.02) * height;
    int bandIndex = (int)map(i, 0, numLines - 1, 0, fft.specSize()-1);
    float amplitude = fft.getBand(bandIndex);
    float ex = sx + map(amplitude, 0, 50, 20, 150);
    float ey = sy + map(amplitude, 0, 50, 20, 150);
    stroke(noise(i, frameCount * 0.015)*255,
           noise(i+50, frameCount * 0.015)*255,
           noise(i+100, frameCount * 0.015)*255, 180);
    strokeWeight(2);
    line(sx, sy, ex, ey);
  }
  
  // Abstract circle effect
  int numCircles = 10;
  noStroke();
  for (int i = 0; i < numCircles; i++) {
    float cx = noise(i * 0.1, frameCount * 0.01) * width;
    float cy = noise(i * 0.1 + 100, frameCount * 0.01) * height;
    int bandIndex = (int)map(i, 0, numCircles - 1, 0, fft.specSize()-1);
    float amplitude = fft.getBand(bandIndex);
    float rad = map(amplitude, 0, 50, 10, 150);
    float cr = noise(i, frameCount * 0.02) * 255;
    float cg = noise(i + 100, frameCount * 0.02) * 255;
    float cb = noise(i + 200, frameCount * 0.02) * 255;
    fill(cr, cg, cb, 150);
    ellipse(cx, cy, rad, rad);
  }
  
  // Display student ID and function instructions on the right side
  fill(TEXT_WHITE);
  textSize(20);
  textAlign(LEFT, TOP);
  text("41171123H 劉彥谷", 220, 20);
  textSize(12);
  text("支援上傳電腦音樂功能", 220, 60);
  text("背景動態效果隨音樂改變", 220, 80);
  text("按下More可以看到更多功能", 220, 100);
  text("More中包含聲道輸出、重複播放、聲音控制等等", 220, 120);
  text("支援睡眠計時器，自動暫停音樂，單位為分鐘正整數", 220, 140);
  text("左側音樂list可選擇不同音樂", 220, 160);
  text("拖動以調整音樂進度", 220, 180);
  
  for (Button b : mainButtons) {
    b.display();
  }
  
  // If showMore is true, draw a background block for the vertically arranged additional buttons on the right
  if (showMore) {
    int moreBtnW = 40;
    int moreCount = moreButtons.size();
    int moreGap = 10;
    int startXMore = width - moreBtnW - 20;
    int startYMore = 100;
    int bgX = startXMore - 10;
    int bgY = startYMore - 10;
    int bgW = moreBtnW + 20;
    int bgH = moreCount * (moreBtnW + moreGap) - moreGap + 20;
    fill(0, 150);
    noStroke();
    rect(bgX, bgY, bgW, bgH, 10);
    
    for (Button b : moreButtons) {
      b.display();
    }
  }
  
  // Draw the progress bar and draggable dot (centered in the right area)
  float barWidth = 400;
  float barHeight = 5;
  float barX = 200 + (600 - barWidth) / 2;
  float barY = height - 140;
  
  fill(100);
  rect(barX, barY, barWidth, barHeight);
  // Use desiredPosition if dragging, otherwise use player's current position
  float currentPos = draggingProgress ? desiredPosition : player.position();
  float playedWidth = map(currentPos, 0, player.length(), 0, barWidth);
  fill(SPOTIFY_GREEN);
  rect(barX, barY, playedWidth, barHeight);
  
  fill(TEXT_WHITE);
  noStroke();
  float dotSize = 15;
  ellipse(barX + playedWidth, barY + barHeight/2, dotSize, dotSize);
  
  textSize(14);
  textAlign(LEFT, CENTER);
  text(nf(player.position()/1000.0, 0, 1) + "s", barX, barY - 20);
  textAlign(RIGHT, CENTER);
  text(nf(player.length()/1000.0, 0, 1) + "s", barX + barWidth, barY - 20);
  
  // Draw the sleep timer button in the upper right corner
  drawSleepTimerButton();
  
  // Check if need to auto-repeat: if player is not playing, was playing, and current position is within the last 1000 ms, and repeat is active
  if (!player.isPlaying() && wasPlaying && player.position() > player.length() - 1000 && isRepeating) {
    player.rewind();
    player.play();
    wasPlaying = false;
  }
  
  // Update wasPlaying state
  if (player.isPlaying()) {
    wasPlaying = true;
  }
}

void mousePressed() {
  // If clicking in the left-side song list, handle track selection or upload
  if (mouseX < 200) {
    int listWidth = 200;
    int startY = 20;
    int itemHeight = 40;
    int index = (mouseY - startY) / itemHeight;
    if (index < playlist.size()) {
      currentTrack = index;
      loadTrack();
    } else if (index == playlist.size()) {
      selectInput("Select a music file:", "fileSelected");
    }
    return;
  }
  
  // Check sleep timer button in the upper right corner
  int timerBtnX = width - 130;
  int timerBtnY = 10;
  int timerBtnW = 120;
  int timerBtnH = 40;
  if (mouseX >= timerBtnX && mouseX <= timerBtnX + timerBtnW &&
      mouseY >= timerBtnY && mouseY <= timerBtnY + timerBtnH) {
    promptSleepTimer();
    return;
  }
  
  // Check main function buttons
  for (Button b : mainButtons) {
    if (b.isMouseOver()) {
      b.pressed = true;
      performAction(b.id);
      return;
    }
  }
  // Check additional function buttons if panel is shown
  if (showMore) {
    for (Button b : moreButtons) {
      if (b.isMouseOver()) {
        b.pressed = true;
        performAction(b.id);
        return;
      }
    }
  }
  
  // Check if the progress bar is clicked
  float barWidth = 400;
  float barHeight = 5;
  float barX = 200 + (600 - barWidth) / 2;
  float barY = height - 140;
  if (mouseX >= barX && mouseX <= barX + barWidth &&
      mouseY >= barY && mouseY <= barY + barHeight) {
    draggingProgress = true;
    updateProgress();
  }
}

void mouseDragged() {
  if (draggingProgress) {
    updateProgress();
  }
}

void mouseReleased() {
  for (Button b : mainButtons) {
    b.pressed = false;
  }
  for (Button b : moreButtons) {
    b.pressed = false;
  }
  if (draggingProgress) {
    player.cue(desiredPosition);
  }
  draggingProgress = false;
}

void updateProgress() {
  float barWidth = 400;
  float barX = 200 + (600 - barWidth) / 2;
  float newPosX = constrain(mouseX, barX, barX+barWidth);
  desiredPosition = int(map(newPosX, barX, barX+barWidth, 0, player.length()));
}

void fileSelected(File selection) {
  if (selection == null) {
    println("No file selected.");
  } else {
    println("User selected: " + selection.getAbsolutePath());
    playlist.add(selection.getAbsolutePath());
    currentTrack = playlist.size() - 1;
    loadTrack();
  }
}

void performAction(int id) {
  switch(id) {
    case 20:
      currentTrack--;
      if (currentTrack < 0) {
        currentTrack = playlist.size() - 1;
      }
      loadTrack();
      break;
    case 21:
      int newPos = player.position() - 10000;
      if (newPos < 0) newPos = 0;
      player.cue(newPos);
      break;
    case 22:
      if (player.isPlaying()) {
        player.pause();
      } else {
        if (player.position() >= player.length()) {
          player.rewind();
        }
        player.play();
        player.setGain(currentGain);
        player.setBalance(currentBalance);
      }
      break;
    case 23:
      newPos = player.position() + 10000;
      if (newPos > player.length()) newPos = player.length();
      player.cue(newPos);
      break;
    case 24:
      currentTrack++;
      if (currentTrack >= playlist.size()) {
        currentTrack = 0;
      }
      loadTrack();
      break;
    case 25:
      showMore = !showMore;
      break;
    case 2:
      if (player.isPlaying() || player.position() > 0) {
        player.pause();
        player.rewind();
      }
      break;
    case 3:
      isMuted = !isMuted;
      if (isMuted) {
        currentGain = player.getGain();
        player.setGain(-80);
      } else {
        player.setGain(currentGain);
      }
      break;
    case 4:
      player.pause();
      player.rewind();
      player.play();
      player.setGain(currentGain);
      player.setBalance(currentBalance);
      break;
    case 5:
      currentBalance = -1.0;
      player.setBalance(currentBalance);
      break;
    case 6:
      currentBalance = 1.0;
      player.setBalance(currentBalance);
      break;
    case 7:
      currentBalance = 0.0;
      player.setBalance(currentBalance);
      break;
    case 8:
      currentGain += 5;
      if (!isMuted) {
        player.setGain(currentGain);
      }
      break;
    case 9:
      currentGain -= 5;
      if (!isMuted) {
        player.setGain(currentGain);
      }
      break;
    case 10:
      isRepeating = !isRepeating;
      break;
  }
}

void loadTrack() {
  if (player != null) {
    player.close();
  }
  player = minim.loadFile(playlist.get(currentTrack));
  player.setGain(currentGain);
  player.setBalance(currentBalance);
  player.play();
}
