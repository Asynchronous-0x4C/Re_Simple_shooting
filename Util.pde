void setVolume(float vol){
  for(Sound s:sounds.values()){
    s.setVolume(vol);
  }
}

void setMute(boolean m){
  for(Sound s:sounds.values()){
    s.setMute(m);
  }
}

class Movement{
  PVector velocity;
  PVector accel;
  float limit;
  float smooth=1;
  
  Movement(){}
  
  Movement(PVector velocity,PVector accel,float limit){
    this.velocity=new PVector(velocity.x,velocity.y);
    this.accel=new PVector(accel.x,accel.y);
    this.limit=limit;
  }
  
  void update(){
    velocity.mult(smooth);
    velocity.add(accel);
    if(limit>=0)velocity.limit(limit);
    accel.set(0,0,0);
  }
  
  void setAccel(PVector a){
    accel.set(a.x,a.y,a.z);
  }
  
  void setVelocity(PVector v){
    velocity.set(v.x,v.y,v.z);
  }
  
  void setLimitSpeed(float s){
    limit=s;
  }
}

abstract class Collider{
  PVector position;
  PVector size;
  float angle;
  
  boolean hasBody=true;
  
  Collider(PVector position,PVector size,float angle){
    this.position=position;
    this.size=size;
    this.angle=angle;
  }
  
  abstract PVector getRandomPoint();
}

class Rectangle extends Collider{
  
  Rectangle(PVector position,PVector size,float angle){
    super(position,size,angle);
  }
  
  PVector getRandomPoint(){
    PVector rand=vectorRotate(new PVector(random(-size.x,size.x)*0.5,random(-size.y,size.y)*0.5),angle);
    return new PVector(position.x+rand.x,position.y+rand.y);
  }
}

class Circle extends Collider{
  
  Circle(PVector position,float size,float angle){
    super(position,new PVector(size,size),angle);
  }
  
  PVector getRandomPoint(){
    float a=random(0,TWO_PI);
    return new PVector(position.x+cos(a)*random(0,size.x*0.5),position.y+sin(a)*random(0,size.y*0.5));
  }
}

float calcDamage(float a,float d){
  return a*a/(a+d);
}

class Material{
  Color albedo=new Color(0);
  Color emission=new Color(0);
  float z_height=3;
  
  final float Thickness=0.1;
  
  Color shadow=new Color(0);
  Color surface=new Color(0);
  
  int updateCount=0;
  
  Material(Color albedo,Color emission){
    this.albedo=albedo;
    this.emission=emission;
    calcColor();
  }
  
  Material setAlbedo(Color albedo){
    this.albedo=albedo;
    calcColor();
    return this;
  }
  
  Material setEmission(Color emission){
    this.emission=emission;
    calcColor();
    return this;
  }
  
  Material setZ_height(float h){
    boolean change=z_height!=h;
    this.z_height=h;
    if(change)calcColor();
    return this;
  }
  
  void calcColor(){
    calcSurface();
    calcShadow();
  }
  
  void calcSurface(){
    surface=lightColor.clone().mult_c(albedo).add_c(emission.clone().mult_s(albedo.a));
  }
  
  void calcShadow(){
    Color direct=lightColor.clone().mult_c(albedo).mult_s(1-albedo.a).add_c(emission.clone().mult_s(1f/sq(z_height))).mult_c(backgroundAlbedo);
    Color indirect=lightColor.clone().mult_c(backgroundAlbedo).mult_s(albedo.a).mult_c(backgroundAlbedo);
    shadow=direct.add_c(indirect);
  }
  
  Color getShadow(){
    if(lightingUpdateCount>updateCount){
      calcColor();
      updateCount=lightingUpdateCount;
    }
    return shadow;
  }
  
  Color getSurface(){
    if(lightingUpdateCount>updateCount){
      calcColor();
      updateCount=lightingUpdateCount;
    }
    return surface;
  }
  
  Material copy(){
    return new Material(albedo,emission);
  }
}

class Color implements Cloneable {
  float r;
  float g;
  float b;
  float a;

  int intValue;
  
  Color(float grayscale){
    init(grayscale/255f,grayscale/255f,grayscale/255f,1);
  }
  
  Color(float grayscale,float a){
    init(grayscale/255f,grayscale/255f,grayscale/255f,a/255f);
  }
  
  Color(float r,float g,float b){
    init(r/255f,g/255f,b/255f,1);
  }
  
  Color(float r,float g,float b,float a){
    init(r/255f,g/255f,b/255f,a/255f);
  }

  /**
   * This method initalizes color data(Red, Green, Blue, Alpha) by
   * Clamping color source and configure {@code intValue}.<br>
   * If you want to change color, you must call this method.<br>
   * @param r Color source(Red).
   * @param g Color source(Green).
   * @param b Color source(Blue).
   * @param a Color source(Alpha).
   * @return The result of configured color.
   */
  Color init(float r,float g,float b,float a){
    this.r=r;
    this.g=g;
    this.b=b;
    this.a=constrain(a,0,1);
    this.intValue=(round(this.a*255)<<24)|(round(constrain(this.r*255,0,255))<<16)|(round(constrain(this.g*255,0,255))<<8)|round(constrain(this.b*255,0,255));
    return this;
  }

  Color set_f(float grayscale){
    return init(grayscale/255f,grayscale/255f,grayscale/255f,1);
  }

  Color set_f(float grayscale,float a){
    return init(grayscale/255f,grayscale/255f,grayscale/255f,a/255f);
  }

  Color set_f(float r,float g,float b){
    return init(r/255f,g/255f,b/255f,a);
  }

  Color set_f(float r,float g,float b,float a){
    return init(r/255f,g/255f,b/255f,a/255f);
  }

  Color setRed(float r){
    return init(r/255f,g,b,a);
  }

  int getRed(){
    return round(min(r*255,255));
  }
  
  float getRawRed(){
    return r;
  }

  Color setGreen(float g){
    return init(r,g/255f,b,a);
  }

  int getGreen(){
    return round(min(g*255,255));
  }
  
  float getRawGreen(){
    return g;
  }

  Color setBlue(float b){
    return init(r,g,b/255f,a);
  }

  int getBlue(){
    return round(min(b*255,255));
  }
  
  float getRawBlue(){
    return b;
  }

  Color setAlpha(float a){
    return init(r,g,b,a/255f);
  }

  int getAlpha(){
    return round(a*255);
  }
  
  float getRawAlpha(){
    return a;
  }

  Color add_s(float scalar){
    return init(r+scalar,g+scalar,b+scalar,a);
  }

  Color add_rgb(float r,float g,float b){
    return init(this.r+r,this.g+g,this.b+b,a);
  }

  Color add_c(Color c){
    return init(r+c.r,g+c.g,b+c.b,a);
  }

  Color sub_s(float scalar){
    return init(r-scalar,g-scalar,b-scalar,a);
  }

  Color sub_rgb(float r,float g,float b){
    return init(this.r-r,this.g-g,this.b-b,a);
  }

  Color sub_c(Color c){
    return init(r-c.r,g-c.g,b-c.b,a);
  }

  Color mult_s(float scalar){
    return init(r*scalar,g*scalar,b*scalar,a);
  }

  Color mult_rgb(float r,float g,float b){
    return init(this.r*r,this.g*g,this.b*b,a);
  }

  Color mult_c(Color c){
    return init(this.r*c.r,this.g*c.g,this.b*c.b,this.a*c.a);
  }

  Color div_s(float scalar){
    return init(r/scalar,g/scalar,b/scalar,a);
  }

  Color div_rgb(float r,float g,float b){
    return init(this.r/r,this.g/g,this.b/b,a);
  }
  
  Color pow_f(float r,float g,float b){
    return init(pow(this.r,r),pow(this.g,g),pow(this.b,b),a);
  }
  
  Color pow_c(Color c){
    return init(pow(r,c.r),pow(g,c.g),pow(b,c.b),pow(a,c.a));
  }

  Color lerp(Color c1,float a){
    return clone().add_c(c1.clone().sub_c(this).mult_s(a));
  }

  Color clone(){
    return new Color(r*255,g*255,b*255,a*255);
  }
  
  float blightness(){
    return max(r,g,b);
  }

  int getInt(){
    return intValue;
  }
}

//TODO:Add Pointer class
class Pointer{
  boolean press=false;
  boolean pressed=false;
  int x=0;
  int y=0;
}
