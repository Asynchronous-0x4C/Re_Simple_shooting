abstract class ShotEnemy extends Enemy{
  Predicate<ShotEnemy> predicate=new Predicate<ShotEnemy>(){
    boolean test(ShotEnemy o){
      return true;
    }
  };
  float cooltimeRange=3.0;
  float maxCooltime=30f+random(-cooltimeRange,cooltimeRange)*0.5;
  float cooltime=0f;
  float shotRange=200;
  
  ShotEnemy(Color bodyColor,float size,ArrayList<Entity> entityList){
    super(bodyColor,size,entityList);
  }
  
  ShotEnemy setCooltime(float f){
    this.maxCooltime=f+random(-cooltimeRange,cooltimeRange)*0.5;
    return this;
  }
  
  ShotEnemy setPredicate(Predicate<ShotEnemy> p){
    this.predicate=p;
    return this;
  }
  
  Enemy setShotRange(float range){
    this.shotRange=range;
    return this;
  }
  
  void update(){
    super.update();
    cooltime-=fpsMag;
    if(cooltime<=0&&ellipseDistFunc(position,shotRange,shotRange*3,gameSystem.getPlayer().position)&&predicate.test(this)){
      shot();
      cooltime=maxCooltime;
    }
  }
  
  abstract void shot();
}

abstract class Boss extends ShotEnemy{
  
  Boss(Color bodyColor,float size,ArrayList<Entity> entityList){
    super(bodyColor,size,entityList);
  }
  
  void deadEvent(){
    super.deadEvent();
    bossDead();
    boss_vibrate();
  }
  
  abstract void bossDead();
  
  void setClear(){
    getGameSystem().set_boss_dead(this);
  }
}

class NormalEnemy extends ShotEnemy{
  
  NormalEnemy(ArrayList<Entity> entityList){
    super(new Color(0,0,255,200),20,entityList);
    setHP(2);
  }
  
  void shot(){
    float a=radians(random(-5,5))+PI*0.5;
    entityList.add(new NormalBullet(new PVector(cos(a)*6,sin(a)*6),this));
  }
}

class SpecialAttackEnemy extends Enemy{
  
  SpecialAttackEnemy(ArrayList<Entity> entityList){
    super(new Color(255,255,0,200),20,entityList);
    setLimitSpeed(6);
    setHP(3);
    setMass(15);
  }
}

class Large_R extends ShotEnemy{
  
  Large_R(ArrayList<Entity> entityList){
    super(new Color(255,0,0,150),27,entityList);
    setHP(4);
    setShotRange(225);
    setCooltime(45);
    setLimitSpeed(2.7);
    setMass(50);
  }
  
  void shot(){
    entityList.add(new NormalBullet(new PVector(0,6),this));
  }
}

class Large_C extends Enemy{
  
  Large_C(ArrayList<Entity> entityList){
    super(new Color(0,255,255,150),27,entityList);
    setHP(5);
    setLimitSpeed(2.6);
    setMass(40);
  }
  
  void shot(){
    entityList.add(new NormalBullet(new PVector(0,6),this));
  }
}

class Lost_Signal extends Boss{
  int shot_count=0;
  int form=0;
  int sub_form=0;
  
  float offset=0;
  
  Lost_Signal(ArrayList<Entity> entityList){
    super(new Color(0,0,0,150),75,entityList);
    setHP(300);
    setLimitSpeed(0);
    setShotRange(3000);
    setCooltime(5);
    setMass(10e10);
  }
  
  void shot(){
    switch(form){
      case 0:
        switch(sub_form){
          case 0:shot_0_0();break;
          case 1:shot_0_1();break;
        }
        if(HP.mut_float<180)form=1;break;
      case 1:
        HP.mut_float-=120;
        setCooltime(5);
        form=2;
        addParticle();
        sounds.get("defeat").play();
        return;
      case 2:shot_2();break;
    }
  }
  
  void shot_0_0(){
    float angle=radians(60+12*abs(6-shot_count)+random(-2,2)+offset);
    shot_count=(shot_count+1)%12;
    entityList.add(new BossBullet(vector_rotate(6,angle),this,angle));
    if(shot_count==0){
      offset=random(-6,6);
      if(random(0,1)<0.2){
        sub_form=1;
        setCooltime(13);
      }
    }
  }
  
  void shot_0_1(){
    float angle=atan2(getPlayer().position.y-position.y,getPlayer().position.x-position.x);
    shot_count=(shot_count+1)%12;
    float offset=random(-3,3);
    entityList.add(new BossBullet(vector_rotate(6,angle+radians(offset-20)),this,angle));
    entityList.add(new BossBullet(vector_rotate(6,angle+radians(offset)),this,angle));
    entityList.add(new BossBullet(vector_rotate(6,angle+radians(offset+20)),this,angle));
    if(shot_count==0){
      if(random(0,1)<0.7){
        sub_form=0;
        setCooltime(5);
      }
    }
  }
  
  void shot_2(){
    float angle=radians(54+12*abs(6-shot_count)+random(-2,2)+offset);
    shot_count=(shot_count+1)%12;
    entityList.add(new BossBullet(vector_rotate(6,angle),this,angle));
    angle=radians(126-12*abs(6-shot_count)+random(-2,2)+offset);
    entityList.add(new BossBullet(vector_rotate(6,angle),this,angle));
    if(shot_count==0)offset=random(-6,6);
  }
  
  void addParticle(){
    getGameSystem().nextEntity.add(new EntityParticleGenerator(this,
      new Supplier<PVector>(){
        PVector get(){
          PVector vel=new PVector(movement.velocity.x,movement.velocity.y);
          vel.mult(fpsMag);
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
  
  void bossDead(){
    getGameSystem().stage.schedules.add(new RelativeSchedule(1.0,new Consumer<Float>(){
      void accept(Float f){
        if(f>=1){setClear();}
      }
    }));
  }
}

//5->10

class Slide extends ShotEnemy{
  float s_cooltime=random(50,100);
  
  Slide(ArrayList<Entity> entityList){
    super(new Color(0,128,255,200),20,entityList);
    setHP(5);
  }
  
  void update(){
    super.update();
    if(s_cooltime<0){
      float a=random(0,TWO_PI);
      float m=random(2,3);
      movement.accel.add(cos(a)*m,sin(a)*m);
      for(int i=0;i<round(m);i++){
        float rnd=random(-0.5,0.5);
        entityList.add(new ColoredParticle(position,new PVector(cos(a+PI+rnd)*m*0.5,sin(a+PI+rnd)*m*0.5),30,6,random(0,TWO_PI),new Color(255,64,0),new Color(255,64,0)));
      }
      s_cooltime=random(50,150);
    }
    s_cooltime-=gameMag;
  }
  
  void shot(){
    float a=radians(random(-5,5))+PI*0.5;
    entityList.add(new NormalBullet(new PVector(cos(a)*6,sin(a)*6),this));
  }
}
