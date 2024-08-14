/*Debug
 *1.Duplicate name function
 *2.Space behind Generics
 *3.Foreach loop
 */

import java.util.Comparator;

import java.lang.reflect.*;

Re_Simple_shooting ref_applet=null;

HashMap<String,Sound> sounds=new HashMap<String,Sound>();

HashMap<String,Strategy> strategies=new HashMap<String,Strategy>();
Strategy currentStrategy;
GameSystem gameSystem;
boolean strategy_changed=false;

PVector mouse=new PVector(0,0);
boolean mousePress=false;
boolean mouseHover=false;

HashMap<String,JSONObject> jsonCache;
JSONObject saveData;
JSONObject currentData;
JSONObject defaultMissionData=JSONObject.parse("{}");
int saveNumber;

long pTime;
float fps=60;
float gameMag=1;
float fpsMag=1;

float fgMag=1;
boolean show_fps=false;

int stageNumber=0;

JSONObject stageData;
JSONObject[] stageList=new JSONObject[5];
String loadedPath="";
String endState="";
int endScore=0;

JSONObject langData;

String font_name=isWeb()?"NotoSansJP-Light.ttf":"data/font/NotoSansJP-Light.ttf";

Color lightColor=new Color(255,255,255);
Color backgroundAlbedo=new Color(190,190,185);

int lightingUpdateCount=0;

final int MAX_CHAPTER=6;

int cores=4;
float scaling=1;

void settings(){
  size(innerWidth,innerHeight,P2D);
}

void setup(){
  settings();
  scaling=min(1,height/720.0);
  width*=1/scaling;
  height*=1/scaling;
  setReference(this);
  loaded();
  initData();
  initStrategy();
  setNextStrategy(strategies.get("start"));
  pTime=getNanoSeconds();
  setTextureSampling();
}

void draw(){
  scale(getDPR());
  mouse.set(mouseX,mouseY);
  mouse.div(scaling);
  mouseHover=false;
  strategies.get("common").update();
  currentStrategy.update();
  if(!strategy_changed){
    bg_by_color(lightColor.clone().mult_c(backgroundAlbedo));
    scale(scaling);
    currentStrategy.displayShadow();
    strategies.get("common").displayShadow();
    currentStrategy.display();
    strategies.get("common").display();
  }else{
    strategy_changed=false;
  }
  updateEvent();
}

void resetBackground(){
  backgroundAlbedo.set_f(190,190,185);
  lightingUpdateCount++;
}

void setBackground(float r,float g,float b){
  backgroundAlbedo.set_f(r,g,b);
  lightingUpdateCount++;
}

void resetLight(){
  lightColor.set_f(255,255,255);
  lightingUpdateCount++;
}

void setLight(float r,float g,float b){
  lightColor.set_f(r,g,b);
  lightingUpdateCount++;
}

void setLight(String type){
  float r=0,g=0,b=0;
  switch(type){
    case "sunrise":r=255;g=210;b=170;break;
    case "day":r=240;g=250;b=255;break;
    case "noon":r=250;g=255;b=255;break;
    case "afternoon":r=220;g=240;b=255;break;
    case "sunset":r=210;g=160;b=110;break;
    case "night":r=40;g=40;b=45;break;
    case "midnight":r=20;g=20;b=20;break;
    case "dawn":r=120;g=80;b=45;break;
  }
  lightColor.set_f(r,g,b);
  lightingUpdateCount++;
}

void setNextStrategy(Strategy s){
  currentStrategy=s;
  currentStrategy.init();
  strategy_changed=true;
}

void updateEvent(){
  mousePress=false;
  fps=1000000000f/(getNanoSeconds()-pTime);
  fpsMag=60f/fps;
  pTime=getNanoSeconds();
}

void mousePressed(){
  if(!isWeb()){
    setMousePress(true);
  }
}

void mouseMoved(){
  //setMousePosition();
}

void mouseDragged(){
}

void JSMousePressed(){
}

void windowResized(){
  if(frameCount>1){
    currentStrategy.init();
  }
}

void setMousePress(boolean b){
  mousePress=b;
}

void setMousePosition(){
  if(!isWeb())return;
  mouseX/=scaling;
  mouseY/=scaling;
}

class mutFloat{//mutable float
  private float default_float;
  float mut_float;
  
  mutFloat(float value){
    default_float=mut_float=value;
  }
  
  float getDefault(){
    return default_float;
  }
}

PVector vectorRotate(PVector p,float angle){
  return new PVector(p.x*cos(angle)-p.y*sin(angle),p.y*cos(angle)+p.x*sin(angle));
}

float length(float x,float y){
  return sqrt(x*x+y*y);
}

PVector vector_rotate(float l,float angle){
  return new PVector(l*cos(angle),l*sin(angle));
}

float sqDist(PVector a,PVector b){
  float x=b.x-a.x;
  float y=b.y-a.y;
  return x*x+y*y;
}

boolean ellipseDistFunc(PVector position,float x,float y,PVector point){
  PVector relative=new PVector((point.x-position.x)/x,(point.y-position.y)/y);
  return relative.mag()-1<=0;
}

boolean roundRectDistFunc(PVector p,float x,float y, float radius) {
  PVector d = new PVector(abs(p.x)-x,abs(p.y)-y);
  return min(max(d.x, d.y), 0.0) + length(max(d.x,0.0),max(d.y,0.0))- radius<=0;
}

GameSystem getGameSystem(){
  if(!(currentStrategy instanceof StageStrategy))return null;
  return ((StageStrategy)currentStrategy).system;
}

Player getPlayer(){
  if(!(currentStrategy instanceof StageStrategy))return null;
  return ((StageStrategy)currentStrategy).system.player;
}

void bg_by_color(Color c){
  fill(c.getRed(),c.getGreen(),c.getBlue(),c.getAlpha());
  rectMode(CORNER);
  rect(0,0,width*scaling,height*scaling);
}

void fill_by_color(Color c){
  fill(c.getRed(),c.getGreen(),c.getBlue(),c.getAlpha());
}

void stroke_by_color(Color c){
  stroke(c.getRed(),c.getGreen(),c.getBlue(),c.getAlpha());
}

float ease(float x){
  return 2.0/(1+pow(2.718281828,-x))-1.0;
}

float easeOutExpo(float x){
  return x==1?1:1-pow(2,-10*x);
}

float ease25(float x){
  return 1.0/(1+pow(2.718281828,-25*(x-0.25)));
}

float cross(PVector x,PVector y){
  return x.x*y.y-x.y*y.x;
}

float sign(float x){
  return x>0?1:x<0?-1:0;
}

void initData(){
  jsonCache=new HashMap<String,JSONObject>();
  saveData=loadJSONObject("./data/save/save.json");
  loadLang(saveData.getString("lang"));
  initAudio();
  initEvent();
  if(!isWeb())loadSound();
}

void loadLang(String code){
  langData=loadJSONObject("./data/lang/"+code+".json");
}

void loadSound(){
  readSound("exit","./data/sound/Exit.wav");
  readSound("hit","./data/sound/Impact.wav");
  readSound("defeat","./data/sound/Defeat.wav");
  readSound("enter","./data/sound/Enter.mp3");
  readSound("shot","./data/sound/Shot.wav");
  readSound("bullet_cancel","./data/sound/BulletCancel.wav");
  readSound("damaged","./data/sound/Damaged.wav");
  readSound("hit_damaged","./data/sound/HitDamaged.wav");
}

void readSound(String name,String path){
  if(!sounds.containsKey(name))sounds.put(name,new Sound(path));
}

String translation(String s){
  return langData.getString(s);
}

String syntax_translation(String s,String... token){
  String res=translation(s);
  int i=0;
  while(res.indexOf("{}")!=-1){
    res=res.replaceFirst("\\{\\}",token[i].startsWith("*")?translation(token[i].replace("*","")):token[i]);
    ++i;
  }
  return res;
}
