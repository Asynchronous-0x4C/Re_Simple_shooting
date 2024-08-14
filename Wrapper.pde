import ddf.minim.*;
import ddf.minim.effects.*;
import javax.sound.sampled.*;

import processing.sound.*;

import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.util.*;

ExecutorService exec;
ArrayList<EntityProcess>processes=new ArrayList<>();
ArrayList<Future<?>>futures=new ArrayList<>();

Minim minim;

final int innerWidth=1280;
final int innerHeight=720;

void setReference(Re_Simple_shooting s){
  ref_applet=s;
  cores=Runtime.getRuntime().availableProcessors();
  exec=Executors.newFixedThreadPool(cores);
  for(int i=0;i<cores;i++){
    processes.add(new EntityProcess());
  }
}

class InstanceFactory{
  HashMap<String,Constructor> constructors=new HashMap<String,Constructor>();
  Re_Simple_shooting applet;
  
  InstanceFactory(Re_Simple_shooting s){
    this.applet=s;
  }
  
  boolean contains(String name){
    return constructors.containsKey(name);
  }
  
  void putConstructor(String name){
    try{
      Constructor c=Class.forName("Re_Simple_shooting$"+name).getDeclaredConstructor(Re_Simple_shooting.class,ArrayList.class);
      constructors.put(name,c);
    }catch(Exception e){
      e.printStackTrace();
    }
  }
  
  Entity getInstance(String name,ArrayList<Entity> entityList){
    try{
      return (Entity)constructors.get(name).newInstance(applet,entityList);
    }catch(Exception e){
      e.printStackTrace();
    }
    return null;
  }
}

static boolean isWeb(){
  return false;
}

void initAudio(){
  minim = new Minim(this);
}

class Sound{
  AudioPlayer player;
  
  Sound(String path){
    player=minim.loadFile(path);
  }
  
  void play(){
    player.rewind();
    player.play();
  }
  
  void setVolume(float v){
    player.setGain(v);
  }
  
  void setMute(boolean m){
    if(m)player.mute();else player.unmute();
  }
}

void stop(){
  minim.stop();
  super.stop();
}

long getNanoSeconds(){
  return System.nanoTime();
}

String getClassName(Object o){
  return o.getClass().toString();
}

void damage_vibrate(){}

void boss_damage_vibrate(){}

void boss_vibrate(){}

void setVibration(boolean b){}

boolean getVibration(){return false;}

void startEntityProcess(GameSystem s){
  boolean collision=s.gameState.equals("shooting");
  float size=s.entities.size()/(float)cores;
  for(int i=0;i<cores;i++){
    futures.add(exec.submit(processes.get(i).setData(round(size*i),round(size*(i+1)),collision,s.entities)));
  }
}

void waitEntityProcess(GameSystem s){
  if(s.pause)return;
  try{
    for(Future<?>f:futures){
      f.get();
    }
  }catch(Exception e){
    e.printStackTrace();
  }
  futures.clear();
  for(Entity e:s.entities){
    if(!e.isDead)s.nextEntity.add(e);
  }
  s.entities.clear();
  s.entities.addAll(s.nextEntity);
  s.nextEntity.clear();
}

class EntityProcess implements Runnable{
  int start;
  int end;
  
  boolean collision;
  ArrayList<Entity> entities=new ArrayList<>();
  
  EntityProcess(){}
  
  void run(){
    for(int n=start;n<end;n++){
      Entity e=entities.get(n);
      e.update();
      if(!e.isDead){
        if(collision){
          for(int i=0;i<entities.size();i++){
            Entity _e=entities.get(i);
            if(e==_e||_e.currentFrame!=frameCount||_e.isDead||((_e instanceof Enemy)&&(e instanceof Enemy))){
              continue;
            }else if(colliderCollision(e.collider,_e.collider)){
              e.Collision(_e);
              _e.Collision(e);
            }
          }
        }
      }
    }
  }
  
  Runnable setData(int s,int e,boolean c,ArrayList<Entity> src){
    start=s;
    end=e;
    collision=c;
    entities=src;
    return this;
  }
}

boolean isApple(){
  return false;
}

void loaded(){};

float getDPR(){
  return 1;
}

void setTextureSampling(){
  ((PGraphicsOpenGL)g).textureSampling(2);
}
