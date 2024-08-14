abstract class Controller{
  
  abstract void update(Entity e);
}

class EnemyController extends Controller{
  
  void update(Entity e){
    
  }
}

class PlayerController extends Controller{
  
  void update(Entity e){
    
  }
}

abstract class Entity{
  PVector position=new PVector();
  Movement movement=new Movement();
  Collider collider;
  Material material;
  float angle;
  float size;
  
  mutFloat HP=new mutFloat(1);
  mutFloat Attack=new mutFloat(1);
  mutFloat Defence=new mutFloat(0);
  
  float moveRange=0.3;
  
  int currentFrame=0;
  boolean isDead=false;
  
  Entity setPosition(PVector position){
    this.position.set(position);
    return this;
  }
  
  Entity setMovement(Movement movement){
    this.movement=movement;
    return this;
  }
  
  Entity setVelocity(PVector v){
    movement.setVelocity(v);
    return this;
  }
  
  Entity setLimitSpeed(float s){
    movement.setLimitSpeed(s+random(-moveRange,moveRange)*0.5*min(1,s));
    return this;
  }
  
  Entity setAccel(PVector a){
    float r=random(-moveRange,moveRange)*0.5*min(1,a.mag());
    a.add(r,r);
    movement.setAccel(a);
    return this;
  }
  
  void setHP(float f){
    HP=new mutFloat(f);
  }
  
  void setAttack(float f){
    Attack=new mutFloat(f);
  }
  
  void setDefence(float f){
    Defence=new mutFloat(f);
  }
  
  abstract void update();
  
  abstract void display();
  
  abstract void displayShadow();
  
  void Collision(Entity e){}
  
  void deadEvent(){}
}

abstract class Agent extends Entity{
  ArrayList<Entity> entityList;
  Controller controller;
  
  void setController(Controller c){
    controller=c;
  }
}

abstract class Enemy extends Agent{
  float mass=20;
  PVector base_accel=new PVector(0,0.2);
  
  Enemy(Color bodyColor,float size,ArrayList<Entity> entityList){
    this.entityList=entityList;
    material=new Material(bodyColor,new Color(0));
    this.size=size;
    collider=new Rectangle(position,new PVector(size,size),0);
    movement=new Movement(new PVector(0,0),base_accel,3+random(-moveRange,moveRange)*0.5);
  }
  
  void setMass(float m){
    mass=m;
  }
  
  void update(){
    movement.update();
    movement.setAccel(base_accel);
    PVector vel=new PVector(movement.velocity.x,movement.velocity.y);
    vel.mult(fgMag);
    position.add(vel);
    if(height<position.y-size*0.5)isDead=true;
    currentFrame=frameCount;
  }
  
  void display(){
    pushMatrix();
    translate(position.x,position.y);
    rotate(angle);
    rectMode(CENTER);
    noStroke();
    fill_by_color(material.getSurface());
    rect(0,0,size,size);
    popMatrix();
  }
  
  void displayShadow(){
    pushMatrix();
    translate(position.x+material.z_height,position.y+material.z_height);
    rotate(angle);
    rectMode(CENTER);
    noStroke();
    fill_by_color(material.getShadow());
    rect(0,0,size,size);
    popMatrix();
  }
  
  void Collision(Entity e){
    if(e instanceof Bullet){
      Bullet b=(Bullet)e;
      if(!b.isMine)return;
      HP.mut_float-=calcDamage(b.Attack.mut_float,Defence.mut_float);
      if(HP.mut_float<=0){
        isDead=true;
        deadEvent();
        sounds.get("defeat").play();
      }else{
        PVector d=PVector.sub(e.position,position);
        float a=PVector.angleBetween(movement.velocity,d)*sign(cross(movement.velocity,d))*0.03;
        float v=e.movement.velocity.mag()*cos(a);
        movement.velocity.add(new PVector(v*sin(a),-v*cos(a)/sqrt(mass)));
        if((this instanceof ShotEnemy)&&!(this instanceof Boss)){
          ((ShotEnemy)this).cooltime=60;
        }
        sounds.get("hit").play();
      }
    }else if(e instanceof Player){
      isDead=true;
      deadEvent();
    }
  }
  
  void deadEvent(){
    GameSystem s=getGameSystem();
    if(s==null)return;
    s.score+=round(HP.default_float*max(Attack.default_float,1)*50);
    s.nextEntity.add(new EntityParticleGenerator(this,
      new Supplier<PVector>(){
        PVector get(){
          PVector vel=new PVector(movement.velocity.x,movement.velocity.y);
          vel.mult(fgMag);
          float speed=random(-1.5,1.5);
          float angle=random(0,TWO_PI);
          return new PVector(cos(angle)*speed+vel.x,sin(angle)*speed+vel.y);
        }
      },
      new Supplier<Float>(){
        Float get(){
          return random(30,60);
        }
      }
      ).generate(floor(size*0.25))
    );
  }
}

class Bullet extends Entity{
  Agent parent;
  boolean isMine=false;
  float speed;
  float angle;
  
  boolean hitBullet=false;
  
  Bullet(Color bodyColor,PVector velocity,Agent parent){
    material=new Material(bodyColor,bodyColor);
    movement=new Movement(velocity,new PVector(0,0),-1);
    this.parent=parent;
    position.set(parent.position.x,parent.position.y);
    PVector vel=new PVector();
    vel.set(velocity);
    vel.normalize();
    vel.mult(parent.collider.size.y*0.5);
    position.x+=vel.x;
    position.y+=vel.y;
    speed=velocity.mag();
    angle=atan2(velocity.y,velocity.x);
    collider=new Rectangle(position,new PVector(3,speed*1.5),angle);
    isMine=parent instanceof Player;
  }
  
  void update(){
    movement.update();
    PVector vel=new PVector(movement.velocity.x,movement.velocity.y);
    vel.mult(fgMag);
    position.add(vel);
    if(position.x-movement.velocity.x<0||width<position.x+movement.velocity.x||position.y-movement.velocity.y<0||height<position.y+movement.velocity.y)isDead=true;
    currentFrame=frameCount;
  }
  
  void display(){
    pushMatrix();
    rectMode(CENTER);
    noStroke();
    fill_by_color(material.getSurface());
    translate(position.x,position.y);
    rotate(angle);
    rect(0,0,speed*1.5,3);
    popMatrix();
  }
  
  void displayShadow(){
    pushMatrix();
    rectMode(CENTER);
    noStroke();
    fill_by_color(material.getShadow());
    translate(position.x+material.z_height,position.y+material.z_height);
    rotate(angle);
    rect(0,0,speed*1.5,3);
    popMatrix();
  }
  
  void Collision(Entity e){
    if(isDead)return;
    if(e instanceof Player){
      Player p=(Player)e;
      if(!isMine){
        isDead=true;
        deadEvent();
      }
    }else if(e instanceof Enemy){
      Enemy _e=(Enemy)e;
      if(isMine){
        ++((Player)parent).streak;
        isDead=true;
        deadEvent();
      }
    }else if(e instanceof Bullet){
      Bullet b=(Bullet)e;
      if(isMine!=b.isMine){
        HP.mut_float-=b.Attack.mut_float*(isMine?0.5:1);
        if(HP.mut_float<=0){
          isDead=true;
          hitBullet=true;
          deadEvent();
          sounds.get("bullet_cancel").play();
        }
      }
    }
  }
  
  void deadEvent(){
    if(!hitBullet)return;
    GameSystem s=getGameSystem();
    if(s==null)return;
    if(!isMine)s.score+=round(Attack.default_float*movement.velocity.mag()*0.5);
    s.nextEntity.add(new EntityParticleGenerator(this,
      new Supplier<PVector>(){
        PVector get(){
          PVector vel=new PVector(movement.velocity.x,movement.velocity.y);
          vel.mult(fgMag);
          float speed=random(-1.5,1.5);
          float angle=random(0,TWO_PI);
          return new PVector(cos(angle)*speed+vel.x*0.25,sin(angle)*speed+vel.y*0.25);
        }
      },
      new Supplier<Float>(){
        Float get(){
          return random(30,60);
        }
      }
      ).generate(floor(2))
    );
  }
}

class Player extends Agent{
  PVector targetPoint;
  HashMap<String,mutFloat> status=new HashMap<String,mutFloat>();
  
  int streak=0;
  
  boolean player_input=true;
  
  Player(PVector position,ArrayList<Entity> entityList){
    this.entityList=entityList;
    targetPoint=new PVector(position.x,position.y);
    this.position=position;
    size=25;
    streak=0;
    collider=new Circle(position,size,0);
    status.put("HP",new mutFloat(5f));
    status.put("Attack",new mutFloat(1f));
    status.put("Defence",new mutFloat(0f));
    status.put("cooltime",new mutFloat(10f));
    material=new Material(new Color(0,200,0,150),new Color(0,200,0));
  }
  
  void setTarget(PVector position){
    targetPoint=position;
  }
  
  void update(){
    if(player_input){
      if(mousePressed&&!mouseHover)shot();
      position.x+=(targetPoint.x-position.x)*min(1f,0.3*fgMag);
    }
    status.get("cooltime").mut_float-=fgMag;
    if(status.get("HP").mut_float<=0){
      isDead=true;
      deadEvent();
    }
    currentFrame=frameCount;
  }
  
  void shot(){
    if(status.get("cooltime").mut_float<=0){
      status.get("cooltime").mut_float=status.get("cooltime").getDefault();
      float r=HALF_PI+random(-HALF_PI*0.05,HALF_PI*0.05);
      entityList.add(new Bullet(new Color(0,0,255,150),new PVector(-15*cos(r),-15*sin(r)),this));
      sounds.get("shot").play();
    }
  }
  
  void display(){
    noStroke();
    fill_by_color(material.getSurface());
    ellipse(position.x,position.y,size,size);
  }
  
  void displayShadow(){
    noStroke();
    fill_by_color(material.getShadow());
    ellipse(position.x+3,position.y+3,size,size);
  }
  
  void setPlayerInput(boolean b){
    player_input=b;
  }
  
  void Collision(Entity e){
    if(e instanceof Bullet){
      Bullet b=(Bullet)e;
      if(!b.isMine){
        status.get("HP").mut_float-=calcDamage(b.Attack.mut_float,status.get("Defence").mut_float);
        status.get("HP").mut_float=max(0,status.get("HP").mut_float);
        streak=0;
        entityList.add(new ExplosionBullet(new PVector(20,0),this));
        sounds.get("damaged").play();
        damage_vibrate();
      }
    }else if(e instanceof Enemy){
      Enemy _e=(Enemy)e;
      status.get("HP").mut_float-=calcDamage(_e.Attack.mut_float*2,status.get("Defence").mut_float);
      status.get("HP").mut_float=max(0,status.get("HP").mut_float);
      streak=0;
        entityList.add(new ExplosionBullet(new PVector(30,0),this));
      sounds.get("hit_damaged").play();
      damage_vibrate();
    }
  }
  
  void deadEvent(){
    GameSystem s=getGameSystem();
    if(s==null)return;
    s.nextEntity.add(new EntityParticleGenerator(this,
      new Supplier<PVector>(){
        PVector get(){
          float speed=random(-1.5,1.5);
          float angle=random(0,TWO_PI);
          return new PVector(cos(angle)*speed,sin(angle)*speed);
        }
      },
      new Supplier<Float>(){
        Float get(){
          return random(30,60);
        }
      }
      ).generate(6)
    );
  }
}

boolean colliderCollision(Collider a,Collider b){
  if(a instanceof Circle&&b instanceof Circle){
    float size=a.size.x+b.size.x;
    return sqDist(a.position,b.position)<=size*size;
  }else if(a instanceof Circle&&b instanceof Rectangle){
    return roundRectDistFunc(vectorRotate(new PVector(a.position.x-b.position.x,a.position.y-b.position.y),-b.angle),b.size.x*0.5,b.size.y*0.5,a.size.x*0.5);
  }else if(a instanceof Rectangle&&b instanceof Circle){
    return roundRectDistFunc(vectorRotate(new PVector(b.position.x-a.position.x,b.position.y-a.position.y),-a.angle),a.size.x*0.5,a.size.y*0.5,b.size.x*0.5);
  }else if(a instanceof Rectangle&&b instanceof Rectangle){
    return roundRectDistFunc(new PVector(b.position.x-a.position.x,b.position.y-a.position.y),(a.size.x+b.size.x)*0.5,(a.size.y+b.size.y)*0.5,0f);
  }
  return false;
}

Comparator<TimeSchedule> schedule_comparator=new Comparator<TimeSchedule>(){
  public int compare(TimeSchedule T1,TimeSchedule T2){
    Float t1=T1.getTime();
    Float t2=T2.getTime();
    Integer ret=Float.valueOf(t1).compareTo(t2);
    return ret;
  }
};

class Stage{
  GameSystem system;
  InstanceFactory factory;
  ArrayList<Float> times=new ArrayList<Float>();
  ArrayList<HashMap<String,Float>> enemyMap=new ArrayList<HashMap<String,Float>>();
  ArrayList<RelativeSchedule> schedules=new ArrayList<RelativeSchedule>();
  ArrayList<RelativeSchedule> next_schedules=new ArrayList<RelativeSchedule>();
  boolean end=false;
  float maxTime;
  float time;
  int enemyIndex=0;
  
  String type;
  
  String stage_time;
  
  HashMap<String,Mission> missions=new HashMap<String,Mission>();
  
  Stage(GameSystem s){
    this.system=s;
  }
  
  void loadStage(String path){
    factory=new InstanceFactory(ref_applet);
    if(!loadedPath.equals(path)){
      if(!jsonCache.containsKey(path)){
        jsonCache.put(path,loadJSONObject(path));
      }
      stageData=jsonCache.get(path);
    }
    loadStageData();
    loadedPath=path;
  }
  
  void loadStage(int index){
    factory=new InstanceFactory(ref_applet);
    stageData=stageList[index];
    loadStageData();
  }
  
  void loadStageData(){
    stage_time=stageData.getString("stage_time");
    JSONArray arr=stageData.getJSONArray("main");
    type=stageData.getString("type");
    switch(type){
      case "normal":loadNormal(arr);break;
      case "boss":loadBoss(arr);break;
    }
    JSONArray missions=stageData.getJSONArray("mission");
    for(int i=0;i<missions.size();i++){
      JSONObject obj=missions.getJSONObject(i);
      this.missions.put(obj.getString("attribute"),new Mission(obj.getString("name")));
    }
  }
  
  void loadNormal(JSONArray arr){
    maxTime=stageData.getFloat("time");
    for(int i=0;i<arr.size();i++){
      JSONObject arr_obj=arr.getJSONObject(i);
      times.add(arr_obj.getFloat("time"));
      enemyMap.add(new HashMap<String,Float>());
      JSONArray arr_obj_arr=arr_obj.getJSONArray("list");
      for(int j=0;j<arr_obj_arr.size();j++){
        JSONObject spownData=arr_obj_arr.getJSONObject(j);
        if(!factory.contains(spownData.getString("name"))){
          factory.putConstructor(spownData.getString("name"));
        }
        enemyMap.get(i).put(spownData.getString("name"),spownData.getFloat("freq"));
      }
    }
  }
  
  void loadBoss(JSONArray arr){
    maxTime=1;
    for(int i=0;i<arr.size();i++){
      JSONObject arr_obj=arr.getJSONObject(i);
      enemyMap.add(new HashMap<String,Float>());
      JSONArray arr_obj_arr=arr_obj.getJSONArray("list");
      if(arr_obj_arr!=null){
        for(int j=0;j<arr_obj_arr.size();j++){
          JSONObject spownData=arr_obj_arr.getJSONObject(j);
          factory.putConstructor(spownData.getString("name"));
          Entity e=factory.getInstance(spownData.getString("name"),system.nextEntity);
          system.entities.add(e.setPosition(new PVector(width*0.5,-e.size*2.0)));
        }
      }
      arr_obj_arr=arr_obj.getJSONArray("event");
      if(arr_obj_arr!=null){
        for(int j=0;j<arr_obj_arr.size();j++){
          String name=arr_obj_arr.getJSONObject(j).getString("name");
          schedules.add(new RelativeSchedule(0,boss_events.get(name)));
        }
      }
    }
    system.ui.components.remove(0);
  }
  
  void init(){
    time=maxTime;
    end=false;
    enemyIndex=0;
  }
  
  void update(){
    if(!system.gameState.equals("shooting"))return;
    if(!type.equals("boss"))time-=1.0/fps;
    for(RelativeSchedule s:schedules){
      s.update(1.0/fps);
    }
    schedules.addAll(next_schedules);
    next_schedules.clear();
    if(time<=0){
      end=true;
      return;
    }
    while(enemyIndex<times.size()-1&&time<=times.get(enemyIndex+1)){
      ++enemyIndex;
    }
    float rand=random(0,1);
    float sum=0;
    try{
      for(String s:enemyMap.get(enemyIndex).keySet()){
        float freq=enemyMap.get(enemyIndex).get(s);
        if(sum<rand&&rand<=sum+freq){
          Entity e=factory.getInstance(s,system.nextEntity);
          system.nextEntity.add(e.setPosition(new PVector(random(e.size*0.5,width-e.size*0.5),-e.size*2.0)));
          break;
        }
        sum+=freq;
      }
    }catch(Exception e){
      e.printStackTrace();
    }
  }
  
  boolean testMission(String name){
    return missions.get(name).test();
  }
  
  class Mission{
    HashMap<String,Predicate<Boolean>> predicators=new HashMap<String,Predicate<Boolean>>();
    
    Mission(String name){
      putMission(name);
    }
    
    void putMission(String name){
      String[] str=name.split("_");
      Predicate<Boolean> pred=null;
      switch(str[0]){
        case "survive":pred=new Predicate<Boolean>(){boolean test(Boolean b){return true;}};break;
        case "score":pred=new Predicate<Boolean>(){boolean test(Boolean b){return system.score>=int(str[1]);}};break;
        case "defeat":pred=new Predicate<Boolean>(){boolean test(Boolean b){return system.boss_dead;}};break;
      }
      predicators.put(name,pred);
    }
    
    boolean test(){
      boolean res=true;
      ArrayList<Predicate<Boolean>> pred=new ArrayList<Predicate<Boolean>>(predicators.values());
      for(int i=0;i<pred.size();i++){
        res=res&pred.get(i).test(true);
      }
      return res;
    }
  }
}
  
class TimeSchedule{
  float time;
  Consumer<Stage> process;
  
  TimeSchedule(float time,Consumer<Stage> p){
    this.time=time;
    this.process=p;
  }
  
  float getTime(){
    return time;
  }
  
  Consumer<Stage> getProcess(){
    return process;
  }
}

class RelativeSchedule{
  float time;
  float duration;
  boolean isEnd=false;
  
  Consumer<Float> process;
  
  RelativeSchedule(float duration,Consumer<Float> process){
    this.duration=duration;
    this.process=process;
  }
  
  void update(float second){
    if(isEnd)return;
    if(time>=duration){
      time=duration;
      isEnd=true;
    }
    process.accept(time);
    time+=second;
  }
}

class GameSystem{
  ArrayList<Entity> nextEntity=new ArrayList<Entity>();
  ArrayList<Entity> entities;
  Player player;
  Stage stage;
  StageUI ui;
  
  int score=0;
  
  String gameState="";
  float resultTime=0;
  
  boolean boss_dead=false;
  boolean pause=false;
  
  GameSystem(){
    init();
    entities.add(player);
  }
  
  void init(){
    gameState="shooting";
    score=0;
    gameMag=1;
    boss_dead=false;
    resultTime=0;
    player=new Player(new PVector(width*0.5,height-40),nextEntity);
    entities=new ArrayList<Entity>();
    stage=new Stage(this);
    ui=new StageUI(this);
    
  }
  
  void loadStage(String path){
    stage.loadStage(path);
    stage.init();
    gameMag=1;
  }
  
  void loadStage(int index){
    stage.loadStage(index);
    stage.init();
    gameMag=1;
  }
  
  void update(){
    if(pause)return;
    if(gameState.equals("clear")||gameState.equals("fail")){
      resultTime+=fpsMag;
      gameMag*=0.9;
    }
    fgMag=gameMag*fpsMag;
    startEntityProcess(this);
    stage.update();
    ui.update();
    if(!mouseHover)player.setTarget(new PVector(mouse.x,mouse.y));
    if(player.isDead){
      gameState="fail";
    }else if(stage.type.equals("boss")){
      if(boss_dead)gameState="clear";
    }else if(stage.time<=0){
      gameState="clear";
    }
    if(resultTime>85){
      endState=gameState;
      endScore=score;
      setNextStrategy(strategies.get("result"));
      saveGame();
    }
  }
  
  void exit(){
    gameState="fail";
  }
  
  void saveGame(){
    if(endState.equals("clear")){
      if(!currentData.getJSONObject("mission").hasKey(str(stageNumber)))currentData.getJSONObject("mission").setJSONObject(str(stageNumber),defaultMissionData);
      JSONObject save_mission=currentData.getJSONObject("mission").getJSONObject(str(stageNumber));
      if(stage.testMission("must")){
        currentData.setInt("progress",max(currentData.getInt("progress"),min(stageNumber+1,MAX_CHAPTER)));
      }
      boolean clear=stage.testMission("must");
      if(clear&&!save_mission.getBoolean("must",false)){
        save_mission.setBoolean("must",true);
        if(stage.type.equals("boss")){
          currentData.setInt("Meta Material",currentData.getInt("Meta Material")+1);
        }
        currentData.setInt("Fusion Core",currentData.getInt("Fusion Core")+1);
      }
      clear=stage.testMission("bonus");
      if(clear&&!save_mission.getBoolean("bonus",false)){
        save_mission.setBoolean("bonus",true);
        currentData.setInt("Fusion Core",currentData.getInt("Fusion Core")+1);
      }
      clear=stage.testMission("challenge");
      if(clear&&!save_mission.getBoolean("challenge",false)){
        save_mission.setBoolean("challenge",true);
        currentData.setInt("Fusion Core",currentData.getInt("Fusion Core")+1);
      }
      clear=stage.testMission("hard_challenge");
      if(clear&&!save_mission.getBoolean("hard_challenge",false)){
        save_mission.setBoolean("hard_challenge",true);
        currentData.setInt("Fusion Core",currentData.getInt("Fusion Core")+1);
      }
    }
    JSONObject save_date=currentData.getJSONObject("date");
    save_date.setInt("year",year());
    save_date.setInt("month",month());
    save_date.setInt("day",day());
    save_date.setInt("hour",hour());
    save_date.setInt("minute",minute());
    saveJSONObject(saveData,"./data/save/save.json");
  }
  
  void display(){
    for(Entity e:entities)e.display();
    ui.display();
    if(resultTime>60){
      noStroke();
      fill(205,205,210);
      rectMode(CORNER);
      float w=round(width/120f);
      float h=round(height/120f);
      for(int i=0;i<w;i++){
        for(int j=0;j<h;j++){
          if((resultTime-60f)*0.04*(w+h)>=i+j)rect(floor(width/w)*i,floor(height/h)*j,ceil(width/w),ceil(height/h));
        }
      }
    }
  }
  
  Player getPlayer(){
    return player;
  }
  
  void displayShadow(){
    waitEntityProcess(this);
    for(Entity e:entities)e.displayShadow();
    ui.displayShadow();
  }
  
  void set_boss_dead(Boss b){
    boss_dead=true;
  }
}
