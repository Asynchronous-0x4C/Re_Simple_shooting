import java.util.function.*;

abstract class Particle extends Entity{
  float maxLife;
  float life;
  float radius=0;
  
  void update(){
    movement.update();
    position.add(movement.velocity.x*fgMag,movement.velocity.y*fgMag);
    angle+=radians(movement.velocity.magSq())*fgMag;
    life-=fgMag;
    material.setAlbedo(material.albedo.setAlpha(200*(life/maxLife)));
    currentFrame=frameCount;
  }
  
  void display(){
    noStroke();
    rectMode(CENTER);
    pushMatrix();
    translate(position.x,position.y);
    rotate(angle);
    fill_by_color(material.getSurface());
    rect(0,0,size,size,radius);
    popMatrix();
  }
  
  void displayShadow(){
    noStroke();
    rectMode(CENTER);
    pushMatrix();
    translate(position.x+material.z_height,position.y+material.z_height);
    rotate(angle);
    fill_by_color(material.getShadow());
    rect(0,0,size,size,radius);
    popMatrix();
  }
}

class MenuParticle extends Particle{
  
  MenuParticle(ParticleGenerator g){
    position=g.range.getRandomPoint();
    movement=new Movement(g.velocity.get(),new PVector(0,0),-1);
    maxLife=g.life.get();
    life=maxLife;
    size=6;
    angle=random(0,TWO_PI);
    material=new Material(new Color(128,168,168),new Color(0));
    radius=size*0.3;
  }
}

class EntityParticle extends Particle{
  
  EntityParticle(EntityParticleGenerator g){
    position=g.range.getRandomPoint();
    movement=new Movement(g.velocity.get(),new PVector(0,0),-1);
    maxLife=g.life.get();
    life=maxLife;
    size=6;
    angle=random(0,TWO_PI);
    material=g.parent.material.copy();
  }
}

class BossParticle extends Particle{
  
  BossParticle(BossParticleGenerator g){
    position=g.range.getRandomPoint();
    movement=new Movement(g.velocity.get(),new PVector(0,0),-1);
    maxLife=g.life.get();
    life=maxLife;
    size=6;
    angle=random(0,TWO_PI);
    material=new Material(g.albedo,new Color(0,0,0));
  }
}

class ColoredParticle extends Particle{
  
  ColoredParticle(PVector pos,PVector vel,float maxlife,float size,float angle,Color albedo,Color emission){
    position=new PVector(pos.x,pos.y);
    movement=new Movement(vel,new PVector(0,0),-1);
    this.life=this.maxLife=maxlife;
    this.size=size;
    this.angle=angle;
    material=new Material(albedo,emission);
  }
  
  void update(){
    super.update();
    if(life<0)isDead=true;
  }
}

abstract class ParticleGenerator extends Entity{
  ArrayList<Particle> particle=new ArrayList<Particle>();
  Collider range;
  Supplier<PVector> velocity;
  Supplier<Float> life;
  
  void display(){
    for(Particle p:particle)p.display();
  }
  
  void displayShadow(){
    for(Particle p:particle)p.displayShadow();
  }
  
  void update(){
    ArrayList<Particle> next=new ArrayList<Particle>();
    for(Particle p:particle){
      p.update();
      if(p.life>0)next.add(p);
    }
    particle=next;
    if(particle.isEmpty())isDead=true;
    currentFrame=frameCount;
  }
}

class MenuParticleGenerator extends ParticleGenerator{
  
  MenuParticleGenerator(Rectangle range,Supplier<PVector> velocity,Supplier<Float> life){
    this.range=range;
    this.velocity=velocity;
    this.life=life;
  }
  
  void generate(float freq){
    if(freq>=random(0,1)){
      particle.add(new MenuParticle(this));
    }
  }
  
  void update(){
    super.update();
    isDead=false;
  }
}

class EntityParticleGenerator extends ParticleGenerator{
  Entity parent;
  
  EntityParticleGenerator(Entity e,Supplier<PVector> velocity,Supplier<Float> life){
    parent=e;
    this.range=e.collider;
    this.velocity=velocity;
    this.life=life;
  }
  
  EntityParticleGenerator generate(int count){
    for(int i=0;i<count;i++)particle.add(new EntityParticle(this));
    return this;
  }
}

class BossParticleGenerator extends ParticleGenerator{
  Color albedo;
  
  BossParticleGenerator(Color c,Rectangle range,Supplier<PVector> velocity,Supplier<Float> life){
    albedo=c;
    this.range=range;
    this.velocity=velocity;
    this.life=life;
  }
  
  void generate(float freq){
    if(freq>=random(0,1)){
      particle.add(new BossParticle(this));
    }
  }
}
