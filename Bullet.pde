class ExplosionBullet extends Bullet{
  float size=0;
  float duration=30;
  
  ExplosionBullet(PVector velocity,Agent parent){
    super(new Color(255,64,0,150),velocity,parent);
    collider=new Circle(this.position,size,0);
  }
  
  void update(){
    size+=movement.velocity.x*fgMag;
    collider.size.set(size,size);
    duration-=fgMag;
    material.setAlbedo(new Color(255,64,0,150*sin(duration/30)));
    if(duration<=0)isDead=true;
    currentFrame=frameCount;
  }
  
  void display(){
    pushMatrix();
    rectMode(CENTER);
    noFill();
    stroke_by_color(material.getSurface());
    translate(position.x,position.y);
    circle(0,0,size);
    popMatrix();
  }
  
  void displayShadow(){
    pushMatrix();
    rectMode(CENTER);
    noFill();
    stroke_by_color(material.getShadow());
    translate(position.x+material.z_height,position.y+material.z_height);
    circle(0,0,size);
    popMatrix();
  }
  
  void Collision(Entity e){
  }
}

class NormalBullet extends Bullet{
  
  NormalBullet(PVector velocity,Agent parent){
    super(new Color(255,0,0,150),velocity,parent);
  }
}

class BossBullet extends Bullet{
  
  BossBullet(PVector velocity,Agent parent,float angle){
    super(new Color(255,0,0,150),velocity,parent);
    this.angle=angle;
  }
  
  void Collision(Entity e){
    if(isDead)return;
    if(e instanceof Player){
      Player p=(Player)e;
      isDead=true;
      deadEvent();
    }else if(e instanceof ExplosionBullet){
      isDead=true;
      hitBullet=true;
      deadEvent();
      sounds.get("bullet_cancel").play();
    }
  }
}
