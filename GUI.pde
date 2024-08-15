abstract class GameComponent{
  PFont font;
  
  PVector position;
  PVector size;
  
  boolean hover;
  
  boolean active=true;
  
  Material material;
  
  final void handleUpdate(){
    if(!active)return;
    update();
  }
  
  abstract void update();
  
  final void handleDisplay(){
    if(!active)return;
    display();
  }
  
  abstract void display();
  
  final void handleDisplayShadow(){
    if(!active)return;
    displayShadow();
  }
  
  abstract void displayShadow();
  
  GameComponent setActive(boolean a){
    active=a;
    return this;
  }
  
  GameComponent setColor(Color c){
    material.setAlbedo(c);
    return this;
  }
  
  boolean isHover(){
    return (position.x<mouse.x&&mouse.x<position.x+size.x&&position.y<mouse.y&&mouse.y<position.y+size.y);
  }
  
  GameComponent setEmission(Color c){
    material.setEmission(c);
    return this;
  }
}

class E2GAdapter extends GameComponent{
  Entity adaptee;
  Consumer<Entity> updator=null;
  
  E2GAdapter(Entity adaptee){
    this.adaptee=adaptee;
  }
  
  E2GAdapter setConsumer(Consumer<Entity> e){
    updator=e;
    return this;
  }
  
  void update(){
    if(updator!=null)updator.accept(adaptee);
    adaptee.update();
  }
  
  void display(){
    adaptee.display();
  }
  
  void displayShadow(){
    adaptee.displayShadow();
  }
}

class ComponentManager extends GameComponent{
  ArrayList<GameComponent> components=new ArrayList<GameComponent>();
  ArrayList<GameComponent> next=new ArrayList<GameComponent>();
  ArrayList<GameComponent> rem=new ArrayList<GameComponent>();
  
  boolean clearNext=false;
  
  int scrollDist=0;
  
  ComponentManager(){
    
  }
  
  ComponentManager setScrollDistance(int d){
    scrollDist=d;
    return this;
  }
  
  void update(){
    for(GameComponent c:components)c.handleUpdate();
    if(clearNext){
      components.clear();
      clearNext=false;
    }
    components.addAll(next);
    components.removeAll(rem);
    next.clear();
    rem.clear();
  }
  
  void display(){
    for(GameComponent c:components)c.handleDisplay();
  }
  
  void displayShadow(){
    for(GameComponent c:components)c.handleDisplayShadow();
  }
  
  ComponentManager add(GameComponent c){
    next.add(c);
    return this;
  }
  
  ComponentManager clear(){
    clearNext=true;
    return this;
  }
  
  ComponentManager clearAll(){
    next.clear();
    clearNext=true;
    return this;
  }
  
  ComponentManager remove(GameComponent c){
    rem.add(c);
    return this;
  }
}

interface ButtonEvent{
  void select(Button b);
}

class Button extends GameComponent{
  PVector offset=new PVector();
  String label = "";
  ButtonEvent event;
  
  float hoverTime=0;
  float offsetDist=3;
  float hoverMaxTime=20;
  
  boolean enable=true;
  
  Material hoverMaterial;
  Material disableMaterial;

  Button(float x,float y,float w,float h){
    position=new PVector(x,y);
    size=new PVector(w,h);
    this.font=createFont(font_name,h*0.75,true);
    material=new Material(new Color(120,120,120,180),new Color(0)).setZ_height(5);
    hoverMaterial=new Material(new Color(60,60,60,200),new Color(0));
    disableMaterial=new Material(new Color(60,60,60,50),new Color(0));
  }
  
  Button setEvent(ButtonEvent e){
    event=e;
    return this;
  }
  
  Button setLabel(String s){
    label=s;
    return this;
  }
  
  Button setEnable(boolean b){
    enable=b;
    return this;
  }
  
  void update(){
    if(!enable)return;
    hover=isHover();
    if(hover){
      hoverTime+=fpsMag;
      hoverTime=min(hoverTime,hoverMaxTime);
      float hoverDist=offsetDist*ease(hoverTime/hoverMaxTime*5);
      offset.set(-hoverDist,-hoverDist);
      material.setZ_height(5.0+hoverDist);
      mouseHover=true;
      if(mousePress){
        event.select(this);
        sounds.get("enter").play();
      }
    }else{
      hoverTime=0;
      offset.set(0,0);
      material.setZ_height(5);
    }
  }
  
  void display(){
    rectMode(CORNER);
    noStroke();
    fill_by_color(enable?hover?hoverMaterial.getSurface():material.getSurface():disableMaterial.getSurface());
    rect(position.x+offset.x,position.y+offset.y,size.x,size.y);
    if(enable){
      if(hover){
        rect(position.x-7+offset.x,position.y+offset.y,3.5,size.y);
        fill(200,200,200);
      }else{
        fill(220,220,220);
      }
    }else{
      fill(100,100,100,200);
    }
    textFont(font);
    textSize(size.y*0.75);
    textAlign(CENTER);
    text(label,position.x+size.x*0.5+offset.x,position.y+size.y*0.77+offset.y);
  }
  
  void displayShadow(){
    rectMode(CORNER);
    noStroke();
    fill_by_color(enable?hover?hoverMaterial.getShadow():material.getShadow():disableMaterial.getShadow());
    rect(position.x+material.z_height+offset.x,position.y+material.z_height+offset.y,size.x,size.y);
    if(hover)rect(position.x-7+material.z_height+offset.x,position.y+material.z_height+offset.y,3.5,size.y);
  }
  
  Button setHoverColor(Color c){
    hoverMaterial.setAlbedo(c);
    return this;
  }
  
  Button setDisableColor(Color c){
    disableMaterial.setAlbedo(c);
    return this;
  }
}

class DialogButton extends Button{
  Color c;
  Color foreground_c;
  
  Color text_c;
  
  DialogButton(float x,float y,float w,float h){
    super(x,y,w,h);
  }
  
  void update(){
    if(!enable)return;
    hover=isHover();
    if(hover){
      hoverTime+=fpsMag;
      hoverTime=min(hoverTime,hoverMaxTime);
      mouseHover=true;
      if(mousePress){
        event.select(this);
        sounds.get("enter").play();
      }
    }else{
      hoverTime=max(0,hoverTime-fpsMag*2);
    }
    float hover_alpha=ease(hoverTime/hoverMaxTime*5);
    c.setAlpha(hover_alpha*255);
    foreground_c=text_c.lerp(new Color(220),1-hover_alpha);
  }
  
  void display(){
    fill_by_color(c);
    stroke(230);
    rectMode(CORNER);
    rect(position.x,position.y,size.x,size.y);
    fill_by_color(foreground_c);
    textFont(font);
    textSize(size.y*0.75);
    textAlign(CENTER);
    text(label,position.x+size.x*0.5,position.y+size.y*0.77);
  }
  
  void displayShadow(){}
  
  DialogButton setColor(Color c){
    this.c=c;
    return this;
  }
  
  DialogButton setTextColor(Color c){
    this.text_c=c;
    return this;
  }
}

class ScrollBar extends GameComponent{
  float maxLength;
  float displayLength;
  
  ScrollBar(float max,float disp,PVector pos,PVector size){
    
  }
  
  void update(){
    
  }
  
  void display(){
    
  }
  
  void displayShadow(){
    
  }
}

class FlowTextBox extends GameComponent{
  Supplier<String> text_content=new Supplier<String>(){String get(){return "";}};
  int text_size=15;
  int align=LEFT;
  
  Material textMaterial;
  
  FlowTextBox(PVector position,PVector size,int text_size,Color body,Color text){
    material=new Material(body,new Color(0)).setZ_height(5);
    textMaterial=new Material(text,new Color(0)).setZ_height(5);
    this.text_size=text_size;
    this.position=position;
    this.size=size;
    this.font=createFont(font_name,text_size);
  }
  
  FlowTextBox setText(Supplier<String> t){
    text_content=t;
    return this;
  }
  
  FlowTextBox setStaticText(String t){
    text_content=new Supplier<String>(){String get(){return t;}};
    return this;
  }
  
  FlowTextBox setAlign(int a){
    align=a;
    return this;
  }
  
  void update(){
  }
  
  void display(){
    fill_by_color(material.getSurface());
    rectMode(CORNER);
    rect(position.x,position.y,size.x,size.y);
    fill_by_color(textMaterial.getSurface());
    textAlign(align);
    textSize(text_size);
    textFont(font);
    text(text_content.get(),position.x,position.y+(isWeb()?text_size*0.27:0),size.x,size.y);
  }
  
  void displayShadow(){
    fill_by_color(material.getShadow());
    rectMode(CORNER);
    rect(position.x+material.z_height,position.y+material.z_height,size.x,size.y);
    fill_by_color(textMaterial.getShadow());
    textAlign(align);
    textSize(text_size);
    textFont(font);
    text(text_content.get(),position.x+material.z_height,position.y+(isWeb()?text_size*0.27:0)+material.z_height,size.x,size.y);
  }
}

class MissionTextBox extends FlowTextBox{
  HashMap<String,Mission> missions=new HashMap<String,Mission>();
  Material unachieved;
  Material achieved;
  
  final String[] attribs={"must","bonus","challenge","hard_challenge"};
  
  MissionTextBox(PVector position,PVector size,int text_size,Color body,Color text){
    super(position,size,text_size,body,text);
    unachieved=new Material(new Color(255,0,0,150),new Color(0));
    achieved=new Material(new Color(0,255,128,150),new Color(0));
  }
  
  MissionTextBox setData(String name,String attr,boolean clear){
    missions.put(attr,new Mission(name,attr,clear));
    return this;
  }
  
  MissionTextBox clearData(){
    missions.clear();
    return this;
  }
  
  void display(){
    super.display();
    int offset=text_size*3;
    textFont(font);
    textSize(text_size);
    textLeading(text_size+2);
    for(String s:attribs){
      if(!missions.containsKey(s))continue;
      Mission m=missions.get(s);
      fill_by_color((m.clear?achieved:unachieved).getSurface());
      text("  "+m.t_attribute+"\n  "+m.t_name,position.x,position.y+text_size*0.27+offset,size.x,size.y);
      offset+=text_size*3;
    }
  }
  
  void displayShadow(){
    super.displayShadow();
    int offset=text_size*3;
    textFont(font);
    textSize(text_size);
    textLeading(text_size+2);
    for(String s:attribs){
      if(!missions.containsKey(s))continue;
      Mission m=missions.get(s);
      fill_by_color((m.clear?achieved:unachieved).getShadow());
      text("  "+m.t_attribute+"\n  "+m.t_name,position.x+material.z_height,position.y+text_size*0.27+offset+material.z_height,size.x,size.y);
      offset+=text_size*3;
    }
  }
  
  class Mission{
    String name;
    String attribute;
    boolean clear;
    
    String t_name;
    String t_attribute;
    
    Mission(String name,String attr,boolean clear){
      this.name=name;
      attribute=attr;
      this.clear=clear;
      String[] _name=name.split("_");
      t_name=syntax_translation(_name[0],_name[1]);
      t_attribute=translation(attr);
    }
  }
}

class FlowText extends GameComponent{
  String label;
  
  int style=CENTER;
  
  FlowText(String text,PVector position,float size,float z,Color textColor){
    this.label=text;
    this.size=new PVector(size,0);
    material=new Material(textColor,new Color(0)).setZ_height(z);
    this.position=position;
    this.font=createFont(font_name,size,true);
  }
  
  FlowText setStyle(int style){
    this.style=style;
    return this;
  }
  
  FlowText setFont(String name){
    this.font=createFont(name,size.x,true);
    return this;
  }
  
  void update(){
    
  }
  
  void display(){
    if(font!=null){
      textFont(font);
    }
    textSize(size.x);
    textAlign(style);
    fill_by_color(material.getSurface());
    text(label,position.x,position.y);
  }
  
  void displayShadow(){
    if(font!=null)textFont(font);
    textSize(size.x);
    textAlign(style);
    fill_by_color(material.getShadow());
    text(label,position.x+material.z_height,position.y+material.z_height);
  }
}

class DynamicFlowText extends FlowText{
  Supplier<String> supplier;
  
  DynamicFlowText(Supplier<String> supplier,PVector position,float size,float z,Color textColor){
    super("",position,size,z,textColor);
    this.supplier=supplier;
  }
  
  void update(){
    label=supplier.get();
  }
}

class FlowRect extends GameComponent{
  Rectangle body;
  
  FlowRect(Rectangle r,float z,Color body_c){
    body=r;
    material=new Material(body_c,new Color(0)).setZ_height(z);
  }
  
  void update(){}
  
  void display(){
    rectMode(CENTER);
    noStroke();
    fill_by_color(material.getSurface());
    rect(body.position.x,body.position.y,body.size.x,body.size.y);
  }
  
  void displayShadow(){
    rectMode(CENTER);
    noStroke();
    fill_by_color(material.getShadow());
    rect(body.position.x+material.z_height,body.position.y+material.z_height,body.size.x,body.size.y);
  }
}

class DynamicFlowRect extends FlowRect{
  Function<DynamicFlowRect,Rectangle> supplier;
  
  DynamicFlowRect(Function<DynamicFlowRect,Rectangle> supplier,float z,Color body_c){
    super(supplier.apply(null),z,body_c);
    this.supplier=supplier;
  }
  
  void update(){
    body=supplier.apply(this);
  }
}

class FlowIcon extends FlowRect{
  PImage icon;
  Material bg_material;

  FlowIcon(Rectangle r,float z,Color body_c,Color bg_c,PImage icon){
    super(r,z,body_c);
    this.icon=icon;
    this.bg_material=new Material(bg_c,new Color(0,0,0)).setZ_height(z);
  }

  void display(){
    rectMode(CENTER);
    noStroke();
    fill_by_color(bg_material.getSurface());
    rect(body.position.x,body.position.y,body.size.x,body.size.y);
    imageMode(CENTER);
    Color tint_color=material.getSurface();
    tint(tint_color.getRed(),tint_color.getGreen(),tint_color.getBlue(),tint_color.getAlpha());
    image(icon,body.position.x,body.position.y,body.size.x,body.size.y);
    noTint();
  }
  
  void displayShadow(){
    rectMode(CENTER);
    noStroke();
    fill_by_color(bg_material.getShadow());
    rect(body.position.x+material.z_height,body.position.y+material.z_height,body.size.x,body.size.y);
    imageMode(CENTER);
    Color tint_color=material.getShadow();
    tint(tint_color.getRed(),tint_color.getGreen(),tint_color.getBlue(),tint_color.getAlpha());
    image(icon,body.position.x+material.z_height,body.position.y+material.z_height,body.size.x,body.size.y);
    noTint();
  }
}

class StageUI{
  ArrayList<GameComponent> components=new ArrayList<GameComponent>();
  GameSystem system;
  
  int UIscore=0;
  
  StageUI(GameSystem s){
    this.system=s;
    components.add(new DynamicFlowText(new Supplier<String>(){
      String get(){
        return nf(max(0.0,s.stage.time),1,2);
      }
    },new PVector(width*0.5,20),20,3,new Color(50,50,50,200)).setEmission(new Color(50,50,50)));
    components.add(new DynamicFlowText(new Supplier<String>(){
      String get(){
        return "HP: "+ceil(max(0.0,s.getPlayer().status.get("HP").mut_float));
      }
    },new PVector(width-270,37.5),20,3,new Color(0,255,0,150)).setEmission(new Color(0,255,0)));
    components.add(new DynamicFlowRect(new Function<DynamicFlowRect,Rectangle>(){
      Rectangle apply(DynamicFlowRect r){
        float hp=s.getPlayer().status.get("HP").mut_float/s.getPlayer().status.get("HP").default_float;
        return new Rectangle(new PVector(width-230+100*hp,30),new PVector(200*hp,15),0);
      }
    },3,new Color(0,255,0,150)).setEmission(new Color(0,255,0)));
    components.add(new DynamicFlowText(new Supplier<String>(){
      String get(){
        UIscore+=round(max((system.score-UIscore)*0.1,(system.score-UIscore)>0?1:0));
        return "Score :"+UIscore;
      }
    },new PVector(width-width*0.3,20),20,3,new Color(0,255,255,150)).setEmission(new Color(0,255,255)));
  }
  
  void update(){
    for(GameComponent c:components)c.handleUpdate();
  }
  
  void display(){
    for(GameComponent c:components)c.handleDisplay();
  }
  
  void displayShadow(){
    for(GameComponent c:components)c.handleDisplayShadow();
  }
}

class Filter extends GameComponent{
  Color c;
  
  Filter(Color c){
    this.c=c;
  }
  
  void update(){}
  
  void display(){
    noStroke();
    fill_by_color(c);
    rectMode(CORNER);
    rect(0,0,width,height);
  }
  
  void displayShadow(){}
}

class GroupBorder extends GameComponent{
  ArrayList<GameComponent> components=new ArrayList<GameComponent>();
  
  PVector margin;
  float border_width;
  
  GroupBorder(float margin_x,float margin_y,float border_width){
    margin=new PVector(margin_x,margin_y);
    this.border_width=border_width;
    position=new PVector();
    size=new PVector();
  }
  
  GroupBorder add(GameComponent c){
    components.add(c);
    position.set(min(position.x,c.position.x-margin.x),min(position.y,c.position.x-margin.y));
    size.set(max(position.x+size.x,c.position.x+c.size.x+margin.x),max(position.y+size.y,c.position.y+c.size.y+margin.y));
    size.sub(position);
    return this;
  }
  
  void update(){
    
  }
  
  void display(){
    rectMode(CORNER);
    noFill();
    stroke_by_color(material.getSurface());
    rect(position.x,position.y,size.x,size.y);
  }
  
  void displayShadow(){
    rectMode(CORNER);
    noFill();
    stroke_by_color(material.getShadow());
    rect(position.x+3,position.y+3,size.x,size.y);
  }
}

class InputHandler extends GameComponent{
  ArrayList<Integer> binds;
  Runnable complete;
  int count=0;
  
  InputHandler(Runnable complete,Integer... binds){
    this.binds=new ArrayList<Integer>();
    for(Integer b:binds){
      this.binds.add(b);
    }
    this.complete=complete;
    //TODO:add listener
  }
  
  void update(){}
  
  void display(){}
  
  void displayShadow(){}
}

class DialogManager extends GameComponent{
  ArrayList<Dialog> dialogs=new ArrayList<Dialog>();
  
  void add(Dialog d){
    dialogs.add(d);
  }
  
  void clear(){
    dialogs.clear();
  }
  
  boolean isEmpty(){
    return dialogs.isEmpty();
  }
  
  void update(){
    HashMap<String,Integer> indexes=new HashMap<String,Integer>();
    ArrayList<Dialog> next=new ArrayList<Dialog>();//TODO:set index data for each dialog
    for(Dialog d:dialogs){
      d.update();
      if(d.duration>0){
        if(indexes.containsKey(getClassName(d))){
          indexes.replace(getClassName(d),indexes.get(getClassName(d))+1);
          d.index=indexes.get(getClassName(d));
        }else{
          d.index=0;
          indexes.put(getClassName(d),0);
        }
        next.add(d);
      }
    }
    dialogs=next;
  }
  
  void display(){
    for(Dialog d:dialogs){
      d.display();
    }
  }
  
  void displayShadow(){}
}

abstract class Dialog extends GameComponent{
  float duration=60;
  String title;
  
  int index=0;
  
  void setTitle(String title){
    this.title=title;
  }
  
  void setDuration(float duration){
    this.duration=duration;
  }
  
  void update(){
    duration-=fpsMag;
  }
  
  void displayShadow(){}
}

class SelectDialog extends Dialog{
  Button accept;
  Button reject;
  
  int text_size=30;
  
  String content="";
  
  boolean closeable=true;
  
  SelectDialog(float x,float y,String a,String r){
    position=new PVector(width*0.5,height*0.5);
    size=new PVector(x,y);
    this.font=createFont(font_name,text_size,true);
    float min_margin=10;
    float min_height=35;
    float min_width=300;
    accept=new DialogButton(position.x-min_width-min_margin*2,position.y+size.y*0.5-min_height-min_margin,min_width,min_height)
           .setColor(new Color(200)).setTextColor(new Color(20)).setLabel(a);
    reject=new DialogButton(position.x+min_margin*2,position.y+size.y*0.5-min_height-min_margin,min_width,min_height)
           .setColor(new Color(200)).setTextColor(new Color(20)).setLabel(r);
  }
  
  SelectDialog setEvent(ButtonEvent a,ButtonEvent r){
    accept.setEvent(a);
    reject.setEvent(r);
    return this;
  }
  
  SelectDialog setText(String s){
    content=s;
    return this;
  }
  
  SelectDialog setCloseable(boolean b){
    closeable=b;
    return this;
  }
  
  void display(){
    noStroke();
    fill(0,200);
    rectMode(CENTER);
    rect(position.x,position.y,size.x,size.y);
    fill(255);
    textAlign(CENTER,CENTER);
    rectMode(CORNER);
    textSize(text_size);
    textFont(this.font);
    textLeading(text_size*1.14);
    text(content,position.x-size.x*0.5,position.y-size.y*0.5,size.x,size.y);
    accept.display();
    reject.display();
  }
  
  void update(){
    if(closeable&&!isHover()&&mousePress)duration=0;
    accept.update();
    reject.update();
  }
  
  boolean isHover(){
    return (position.x-size.x*0.5<mouse.x&&mouse.x<position.x+size.x*0.5&&position.y-size.y*0.5<mouse.y&&mouse.y<position.y+size.y*0.5);
  }
}
