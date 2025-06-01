import http.requests.*;
import java.util.Comparator;

// === Google Sheet / Form 連線設定 ===
final String SHEET_URL      = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTABJIAVcxP6LgkMlgtP9dx_MtOOLsWTzhp44Tb1wskgibka2h6u_h4Tn40h7-mTyo1j9S_NjCvu_jF/pub?output=csv";
final String FORM_URL       = "https://docs.google.com/forms/d/e/1FAIpQLSeGhOgDuc8ECcK1ocZUbKMSx1NiZGWeBW1_8PTSsTbF7sZwDg/formResponse";
final String RESPONSES_URL  = "https://docs.google.com/spreadsheets/d/e/2PACX-1vTAvPTiYx96QdfWEvSgUMmFkz8O9w29QdPoVc5dis9cXfmagI0wlNAJF3d2r6tJjewV0t6VMSgS8Rru/pub?output=csv";

// Google Form 欄位代號（依你表單調整）
final String ENTRY_NAME     = "entry.1290096940";
final String ENTRY_ACCOUNT  = "entry.1469038103";
final String ENTRY_PASSWORD = "entry.182905058";
final String ENTRY_SCORE    = "entry.1610854592";

// 註冊/登入錯誤訊息
String registerError = "";
String loginError    = "";

// 倒數計時設定（毫秒）
final int QUESTION_DURATION = 30 * 1000;
long questionStartTime;

// 遊戲狀態
enum Scene { LOGIN, REGISTER, QUIZ, RESULT, RECORDS }
Scene scene = Scene.LOGIN;

// 問題資料結構，含圖片支援
class Question {
  String text, difficulty, answer;
  String[] opts;
  String imageUrl;
  PImage img;

  Question(TableRow r) {
    text       = r.getString("題目");
    difficulty = r.getString("難易");
    answer     = r.getString("解答");
    opts = new String[]{
      r.getString("選項A"),
      r.getString("選項B"),
      r.getString("選項C"),
      r.getString("選項D")
    };
    imageUrl = r.getString("圖片URL");
    if (imageUrl != null && imageUrl.length() > 0) {
      img = loadImage(imageUrl);  // 支援網路 URL 或 data 資料夾中的檔名
    } else {
      img = null;
    }
  }
}

ArrayList<Question> questions = new ArrayList<>();
int qIndex    = 0;
int score     = 0;
int selected  = -1;

// 使用者資料
String name    = "";
String account = "";
String password= "";

PFont font;

// 簡易輸入框
class InputBox {
  float x,y,w,h; String label, value="";
  boolean active=false;
  InputBox(String l,float x,float y,float w,float h){
    label=l;this.x=x;this.y=y;this.w=w;this.h=h;
  }
  void draw(){
    stroke(active?color(0,120,255):150);
    noFill(); rect(x,y,w,h,4);
    fill(0); textAlign(LEFT, CENTER);
    text(label+": "+value, x+5, y+h/2);
  }
  boolean over(float mx,float my){
    return mx>x && mx<x+w && my>y && my<y+h;
  }
}

InputBox boxName    = new InputBox("Name",    260,200,280,32);
InputBox boxAccount = new InputBox("Account", 260,250,280,32);
InputBox boxPassword= new InputBox("Password",260,300,280,32);

void setup(){
  size(800,600);
  try {
    font = createFont("NotoSansTC-Regular.ttf",18);
  } catch(Exception e){
    font = createFont("SansSerif",18);
  }
  textFont(font);
  loadQuestions();
}

void draw(){
  background(245);
  switch(scene){
    case LOGIN:    drawLogin();    break;
    case REGISTER: drawRegister(); break;
    case QUIZ:     drawQuiz();     break;
    case RESULT:   drawResult();   break;
    case RECORDS:  drawRecords();  break;
  }
}

// ===== LOGIN 場景 =====
void drawLogin(){
  // 標題
  fill(0); textAlign(CENTER); textSize(28);
  text("Quiz Game – 雲端版", width/2, 100);

  // 遊戲特別之處
  textAlign(LEFT); textSize(14); fill(50);
  text("• 即時雲端成績儲存，隨時查看個人及全球排行 | 整合多學科知識 | 請切換英文鍵盤", 80, 140);
  text("• 支援多元題型：純文字、圖片題均可串接 | 簡約風介面提升遊玩體驗",    80, 160);
  text("• 可寫入資料(註冊)、可讀出資料(個人分數、全球分數、所有文字及媒體資料",    80, 180);

  // 技術亮點
  text("• 請先安裝http.requests | 遊戲回答問題之後，需稍等最終畫面，其按鈕按下之後也要等到按鈕變藍",   80, 200);
  text("• 動態載入圖片並自動排版，提升題目豐富度，圖片並非存在本地端而是雲端，除了文本還有多媒體資料！多練習！",    80, 220);

  // 輸入框與按鈕
  boxAccount.draw();
  boxPassword.draw();
  drawButton("Login",    width/2-140,370,120,40);
  drawButton("Register", width/2+20, 370,120,40);

  // 錯誤訊息
  if(!loginError.isEmpty()){
    fill(200,0,0); textAlign(CENTER); textSize(16);
    text(loginError, width/2, 420);
  }
}

void loginMouse(){
  if(overButton(width/2-140,370,120,40)){
    account  = boxAccount.value.trim();
    password = boxPassword.value.trim();
    Table t = loadTable(RESPONSES_URL,"header,csv");
    if(t==null){
      loginError = "無法載入帳號資料，請稍後再試。";
      return;
    }
    boolean auth = false;
    for(TableRow r:t.rows()){
      if(r.getString(2).equals(account) && r.getString(3).equals(password)){
        auth = true;
        name = r.getString(1);
        break;
      }
    }
    if(auth){
      loginError = "";
      registerError = "";
      scene = Scene.QUIZ;
      questionStartTime = millis();
    } else {
      loginError = "帳號或密碼錯誤，請再試一次。";
    }
  }
  else if(overButton(width/2+20,370,120,40)){
    loginError = "";
    registerError = "";
    scene = Scene.REGISTER;
  }
}

// ===== REGISTER 場景 =====
void drawRegister(){
  fill(0); textAlign(CENTER); textSize(28);
  text("Create Account", width/2,120);
  boxName.draw(); boxAccount.draw(); boxPassword.draw();
  drawButton("Submit",width/2-60,370,120,40);
  drawButton("Back",20,20,80,32);
  if(!registerError.isEmpty()){
    fill(200,0,0);
    text(registerError, width/2, 420);
  }
}

void registerMouse(){
  if(overButton(width/2-60,370,120,40)){
    name     = boxName.value.trim();
    account  = boxAccount.value.trim();
    password = boxPassword.value.trim();
    Table t = loadTable(RESPONSES_URL,"header,csv");
    boolean exists=false;
    if(t!=null){
      for(TableRow r:t.rows()){
        if(r.getString(2).equals(account)){
          exists=true; break;
        }
      }
    }
    if(exists){
      registerError="帳號已存在，請換一組新帳號。";
    } else {
      sendForm(name,account,password,0);
      registerError="";
      boxName.value=boxAccount.value=boxPassword.value="";
      loginError = "";
      scene=Scene.LOGIN;
    }
  }
  else if(overButton(20,20,80,32)){
    registerError="";
    loginError = "";
    scene=Scene.LOGIN;
  }
}

// ===== QUIZ 場景 =====
void drawQuiz(){
  if(qIndex>=questions.size()){
    scene=Scene.RESULT; return;
  }
  Question q = questions.get(qIndex);
  // 圖片題顯示
  float textY, baseY;
  if(q.img != null){
    float iw = 200;
    float ih = q.img.height * (200.0f / q.img.width);
    image(q.img, width/2 - iw/2, 80, iw, ih);
    textY = 80 + ih + 20;
    baseY = 80 + ih + 60;
  } else {
    textY = 80;
    baseY = 220;
  }
  fill(0); textAlign(LEFT,TOP); textSize(20);
  text("Q"+(qIndex+1)+" ("+q.difficulty+"): "+q.text, 60, textY, 680, 200);
  for(int i=0;i<4;i++){
    drawOption(q.opts[i], 80, baseY + i*60, i);
  }
  int elapsed = (int)(millis()-questionStartTime);
  int remain  = max(0, QUESTION_DURATION-elapsed)/1000;
  textAlign(RIGHT, TOP); textSize(18);
  text("Time: "+remain+"s", width-60, 20);
  if(elapsed>=QUESTION_DURATION){
    processAnswer();
  }
  drawButton("Next", width-160, height-80,120,40);
}

void processAnswer(){
  Question q = questions.get(qIndex);
  if(selected>-1 && q.answer.equals(""+(char)('A'+selected))){
    score++;
  }
  qIndex++; selected=-1;
  questionStartTime = millis();
}

void quizMouse(){
  Question q = questions.get(qIndex);
  float baseY = (q.img!=null)
    ? 80 + q.img.height * (200.0f/q.img.width) + 60
    : 220;
  for(int i=0;i<4;i++){
    if(mouseX>80 && mouseX<720 && mouseY>baseY+i*60 && mouseY<baseY+i*60+40){
      selected=i;
    }
  }
  if(overButton(width-160,height-80,120,40)){
    processAnswer();
  }
}

// ===== RESULT 場景（美化版） =====
void drawResult(){
  // 半透明遮罩
  noStroke();
  fill(0, 150);
  rect(0, 0, width, height);

  // 白色圓角面板
  float panelW = 600, panelH = 400;
  float panelX = (width - panelW) / 2;
  float panelY = (height - panelH) / 2;
  fill(255);
  stroke(200);
  strokeWeight(2);
  rect(panelX, panelY, panelW, panelH, 16);

  // 標題與分數
  noStroke();
  fill(40);
  textAlign(CENTER, TOP);
  textSize(36);
  text("Completed!", width/2, panelY + 30);
  textSize(24);
  text("Score: " + score + " / " + questions.size(), width/2, panelY + 80);

  // 排行榜
  Table t = loadTable(RESPONSES_URL,"header,csv");
  if(t!=null){
    t.sortReverse(4);
    float lbX = panelX + panelW - 240;
    float lbY = panelY + 130;
    textAlign(LEFT, TOP);
    fill(60); textSize(18);
    text("Global Top 5", lbX, lbY);
    textSize(16); fill(0);
    for(int i=0; i<5 && i<t.getRowCount(); i++){
      TableRow r = t.getRow(i);
      String nm = r.getString(1);
      String sc = r.getString(4);
      text((i+1) + ". " + nm + " — " + sc,
           lbX, lbY + 30 + i*30);
    }
  }

  // 按鈕
  float btnY = panelY + panelH - 60;
  float btnW = 120, btnH = 40, gap = 20;
  float centerX = width/2;
  // Upload & Records
  drawButton("上傳此次成績",  centerX - btnW - gap/2, btnY, btnW, btnH);
  drawButton("檢閱紀錄", centerX + gap/2,           btnY, btnW, btnH);
  // Logout & Restart
  drawButton("登出",  panelX + 30,                    btnY, btnW, btnH);
  drawButton("重新開始", panelX + panelW - btnW - 30,    btnY, btnW, btnH);
}

void resultMouse(){
  float panelW = 600, panelH = 400;
  float panelX = (width - panelW) / 2;
  float panelY = (height - panelH) / 2;
  float btnY = panelY + panelH - 60;
  float btnW = 120, btnH = 40, gap = 20;
  float centerX = width/2;

  // Upload
  if(overButton(centerX - btnW - gap/2, btnY, btnW, btnH)){
    sendForm(name,account,password,score);
  }
  // Records
  else if(overButton(centerX + gap/2, btnY, btnW, btnH)){
    scene = Scene.RECORDS;
  }
  // Logout
  else if(overButton(panelX + 30, btnY, btnW, btnH)){
    account = ""; password = ""; loginError = "";
    scene = Scene.LOGIN;
  }
  // Restart
  else if(overButton(panelX + panelW - btnW - 30, btnY, btnW, btnH)){
    qIndex = 0; score = 0; selected = -1;
    questionStartTime = millis();
    scene = Scene.QUIZ;
  }
}

// ===== RECORDS 場景 =====
void drawRecords(){
  fill(0); textAlign(CENTER); textSize(26);
  text("Latest records for account: "+account, width/2,60);
  Table t = loadTable(RESPONSES_URL,"header,csv");
  if(t==null){
    println("Failed to load responses sheet!");
    return;
  }
  t.sortReverse(0);
  int rowsShown=0;
  for(TableRow r:t.rows()){
    if(r.getString(2).equals(account)){
      String time = r.getString(0);
      String nm   = r.getString(1);
      String sc   = r.getString(4);
      textAlign(LEFT);
      text(nm+"  Score: "+sc+"  Time: "+time, 120,120+rowsShown*30);
      if(++rowsShown==5) break;
    }
  }
  drawButton("Back",20,20,80,32);
}

void mousePressed(){
  switch(scene){
    case LOGIN:    loginMouse();    break;
    case REGISTER: registerMouse(); break;
    case QUIZ:     quizMouse();     break;
    case RESULT:   resultMouse();   break;
    case RECORDS:
      if(overButton(20,20,80,32)){
        loginError = "";
        scene = Scene.LOGIN;
      }
      break;
  }
  for(InputBox b:new InputBox[]{boxName,boxAccount,boxPassword}){
    b.active = b.over(mouseX,mouseY);
  }
}

void keyTyped(){
  for(InputBox b:new InputBox[]{boxName,boxAccount,boxPassword}){
    if(b.active){
      if(key==BACKSPACE && b.value.length()>0){
        b.value=b.value.substring(0,b.value.length()-1);
      } else if(key!=CODED && key!=ENTER){
        b.value+=key;
      }
    }
  }
}

void drawOption(String txt,float x,float y,int idx){
  fill(idx==selected?color(180,220,255):230);
  stroke(150); rect(x,y,640,40,6);
  fill(0); textAlign(LEFT,CENTER);
  text((char)('A'+idx)+". "+txt, x+10,y+20);
}

void drawButton(String lbl,float x,float y,float w,float h){
  fill(overButton(x,y,w,h)?color(200,230,255):220);
  stroke(150); rect(x,y,w,h,6);
  fill(0); textAlign(CENTER,CENTER);
  text(lbl,x+w/2,y+h/2);
}

boolean overButton(float x,float y,float w,float h){
  return mouseX>x && mouseX<x+w && mouseY>y && mouseY<y+h;
}

void loadQuestions(){
  Table t = loadTable(SHEET_URL,"header,csv");
  if(t==null){ println("Load sheet failed."); return; }
  questions.clear();
  for(TableRow r:t.rows()) questions.add(new Question(r));
  questions.sort(new Comparator<Question>(){
    public int compare(Question a,Question b){
      return a.difficulty.compareTo(b.difficulty);
    }
  });
}

void sendForm(String nm,String acc,String pwd,int sc){
  PostRequest req=new PostRequest(FORM_URL);
  req.addHeader("Content-Type","application/x-www-form-urlencoded");
  req.addData(ENTRY_NAME,nm);
  req.addData(ENTRY_ACCOUNT,acc);
  req.addData(ENTRY_PASSWORD,pwd);
  req.addData(ENTRY_SCORE,str(sc));
  req.send();
  println("Form submitted for "+acc+": score="+sc);
}
