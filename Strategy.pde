abstract class Strategy{
  ComponentManager UImanager=new ComponentManager();
  DialogManager dialogManager=new DialogManager();
  String child;
  String parent;
  String name;
  
  void init(){}
  
  Strategy(String parent,String name){
    this.parent=parent;
    this.name=name;
  }
  
  Strategy setChild(String name){
    this.child=name;
    return this;
  }
  
  abstract void update();
  
  abstract void display();
  
  abstract void displayShadow();
}

void initStrategy(){
  strategies.clear();
  strategies.put("common",new CommonStrategy());
  strategies.put("start",new StartStrategy());
  strategies.put("menu",new MenuStrategy());
  strategies.put("config",new ConfigStrategy());
  strategies.put("shop",new ShopStrategy());
  strategies.put("stage",new StageStrategy());
  strategies.put("result",new ResultStrategy());
}

class CommonStrategy extends Strategy{
  
  CommonStrategy(){
    super("","common");
    UImanager.add(new DynamicFlowText(new Supplier<String>(){
      String get(){
        return show_fps?nf(fps,0,1)+" FPS":"";
      }
    },new PVector(35,20),15,3,new Color(0,0,100,200))
    .setEmission(new Color(200,0,0)));
  }
  
  void update(){
    UImanager.handleUpdate();
  }
  
  void display(){
    UImanager.handleDisplay();
  }
  
  void displayShadow(){
    UImanager.handleDisplayShadow();
  }
}

class StartStrategy extends Strategy{
  MenuParticleGenerator particleGen;
  
  StartStrategy(){
    super("","start");
  }
  
  void init(){
    UImanager.clearAll();
    dialogManager.clear();
    particleGen=new MenuParticleGenerator(new Rectangle(new PVector(width*0.5,height+10),new PVector(width,20),0),
      new Supplier<PVector>(){
        PVector get(){
          return new PVector(0,-random(1.0,1.2));
        }
      },
      new Supplier<Float>(){
        Float get(){
          return random(240,300);
        }
      }
    );
    for(int i=0;i<3;i++){
      UImanager.add(
        new Button(width*0.5-100,height*0.5-55+i*40,200,30).setEvent(new ButtonEvent(){
          void select(Button b){
            saveNumber=int(b.label.split(" ")[1]);
            saveData.addTask(new Consumer<JSONObject>(){
              void accept(JSONObject data){
                currentData=data.getJSONObject(str(saveNumber));
                setNextStrategy(strategies.get("menu"));
              }
            });
          }
        }).setLabel("Save "+(i+1))
      );
    }
    saveData.addTask(new Consumer<JSONObject>(){
      void accept(JSONObject data){
        for(int i=0;i<3;i++){
          JSONObject o=data.getJSONObject(str(i+1)).getJSONObject("date");
          String date=o.isNull("year")?"No Data":o.getInt("year")+"/"+o.getInt("month")+"/"+o.getInt("day")+" "+o.getInt("hour")+":"+o.getInt("minute");
          UImanager.add(new FlowText(date,new PVector(width*0.5+130,height*0.5-25+i*40),30,2,new Color(100,100,200,200)).setStyle(LEFT));
        }
      }
    });
    UImanager.add(
      new Button(width*0.5-100,height*0.5+65,200,30).setEvent(new ButtonEvent(){
        void select(Button b){
          UImanager.add(
            new Button(width*0.5+130,height*0.5+65,100,30).setEvent(new ButtonEvent(){
              void select(Button b){
                saveData.addTask(new Consumer<JSONObject>(){
                  void accept(JSONObject data){
                    loadJSONObjectAsync("./data/save/save_base.json").addTask(new Consumer<JSONObject>(){
                      void accept(JSONObject base){
                        saveJSONObject(base,"./data/save/save.json");
                        saveData.setObject(base);
                        init();
                      }
                    });
                  }
                });
              }
            }).setLabel("OK")
            .setHoverColor(new Color(120,40,40,180))
            .setColor(new Color(180,100,100,200))
          );
          UImanager.add(
            new Button(width*0.5+260,height*0.5+65,100,30).setEvent(new ButtonEvent(){
              void select(Button b){
                init();
              }
            }).setLabel("Cancel")
            .setHoverColor(new Color(120,40,40,180))
            .setColor(new Color(180,100,100,200))
          );
        }
      }).setLabel("Clear data")
      .setHoverColor(new Color(120,40,40,180))
      .setColor(new Color(180,100,100,200))
    );
    UImanager.add(
      new Button(width*0.5-100,height*0.5+145,200,30).setEvent(new ButtonEvent(){
        void select(Button b){
          sounds.get("exit").play();
          try{
            Thread.sleep(1000);
          }catch(Exception e){
            
          }
          exit();
        }
      }).setLabel("Exit")
      .setHoverColor(new Color(80,40,40,180))
      .setColor(new Color(140,100,100,200))
    );
    textSize(100);
    float title_width=textWidth("Re:Simple_shooting");
    UImanager.add(new FlowText("Re:Simple_shooting",new PVector(width*0.5,100),100*min(1,(width-20)/title_width),3,new Color(100,100,100,200)));
    UImanager.add(new FlowText("v1.0.0 by 0x4C",new PVector(10,height-10),20,2,new Color(200,100,100,200)).setStyle(LEFT));
    UImanager.add(new FlowText("! This is beta !",new PVector(width*0.5,150),20,2,new Color(255,100,100,200)));
    if(!isWeb())return;
    saveData.addTask(new Consumer<JSONObject>(){
      void accept(JSONObject data){
        if(data.hasKey("haptics")){
          if(!data.getBoolean("haptics")){
            setVibration(false);
            setMute(true);
          }
        }else{
          UImanager.handleUpdate();
          SelectDialog d=new SelectDialog(800,500,translation("enable"),translation("disable")).setText(translation("start_information"));
          d.setEvent(new ButtonEvent(){void select(Button b){d.duration=0;data.setBoolean("haptics",true);saveJSONObject(data,"./data/save/save.json");}},
                     new ButtonEvent(){void select(Button b){setVibration(false);setMute(true);d.duration=0;data.setBoolean("haptics",false);saveJSONObject(data,"./data/save/save.json");}});
          dialogManager.add(d);
        }
      }
    });
    UImanager.add(
      new Button(width*0.5-100,height*0.5+225,200,30).setEvent(new ButtonEvent(){
        void select(Button b){
          textSize(15);
          FlowText load_text=new FlowText("Loading...",new PVector(width-textWidth("Loading..."),height-10),15,2,new Color(40,40,80,180));
          UImanager.add(load_text);
          fetchAll(new Runnable(){void run(){UImanager.remove(load_text);}});
        }
      }).setLabel("Load all assets")
      .setHoverColor(new Color(40,40,80,180))
      .setColor(new Color(100,100,140,200))
    );
  }
  
  void update(){
    particleGen.generate(0.5);
    particleGen.update();
    if(dialogManager.isEmpty()){
      UImanager.handleUpdate();
    }else{
      dialogManager.update();
    }
  }
  
  void display(){
    UImanager.handleDisplay();
    particleGen.display();
    dialogManager.handleDisplay();
  }
  
  void displayShadow(){
    UImanager.handleDisplayShadow();
    particleGen.displayShadow();
  }
}

class MenuStrategy extends Strategy{
  ComponentManager startManager=new ComponentManager();
  MissionTextBox missionText;
  int stage_stride=0;
  
  MenuStrategy(){
    super("start","menu");
  }
  
  void init(){
    missionText=new MissionTextBox(new PVector(width*0.75-200,100),new PVector(400,height-220),25,new Color(150,150,150,150),new Color(20,20,20,150));
    startManager.clearAll();
    UImanager.clearAll();
    UImanager.add(
      new Button(100,20,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setNextStrategy(strategies.get("config"));
        }
      }).setLabel("Config")
      .setHoverColor(new Color(40,80,80,180))
      .setColor(new Color(100,140,140,200))
    );
    UImanager.add(
      new Button(width-350,20,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setNextStrategy(strategies.get("shop"));
        }
      }).setLabel("Shop")
      .setHoverColor(new Color(40,80,80,180))
      .setColor(new Color(100,140,140,200))
    );
    UImanager.add(
      new Button(40,isApple()?70:20,30,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setNextStrategy(strategies.get("start"));
        }
      }).setLabel("←")
      .setHoverColor(new Color(80,40,40,180))
      .setColor(new Color(140,100,100,200))
    );
    for(int i=0;i<5;i++){
      int index=i+(stage_stride*5);
      if(index>=currentData.getInt("progress"))break;
      UImanager.add(
        new Button(100,120+i*60,250,30).setEvent(new ButtonEvent(){
          void select(Button b){
            stageNumber=int(b.label.split(" ")[1]);
            strategies.get("stage").init();
            resetLight();
            ((Button)startManager.components.get(0)).setEnable(true);
            missionText.setStaticText("  "+translation("mission")+"(Stage"+stageNumber+")");
            stageData.addTask(new Consumer<JSONObject>(){
              void accept(JSONObject d){
                JSONArray missions=d.getJSONArray("mission");
                for(int m_index=0;m_index<missions.size();m_index++){
                  JSONObject o=missions.getJSONObject(m_index);
                  boolean clear=currentData.getJSONObject("mission").hasKey(str(stageNumber))?currentData.getJSONObject("mission").getJSONObject(str(stageNumber)).getBoolean(o.getString("attribute"),false):false;
                  missionText.setData(o.getString("name"),o.getString("attribute"),clear);
                }
              }
            });
          }
        }).setLabel("stage "+(i+1+(stage_stride*5)))
      );
      String path="./data/stage/Stage"+(index+1)+".json";
      if(!jsonCache.containsKey(path)){
        jsonCache.put(path,loadJSONObjectAsync(path));
      }
      stageList[i]=jsonCache.get(path);
    }
    if(stage_stride>0){
      UImanager.add(
        new Button(100,500,120,30).setEvent(new ButtonEvent(){
          void select(Button b){
            --stage_stride;
            init();
          }
        }).setLabel("Prev")
      );
    }
    if((stage_stride+1)*5<currentData.getInt("progress")){
      UImanager.add(
        new Button(230,500,120,30).setEvent(new ButtonEvent(){
          void select(Button b){
            ++stage_stride;
            init();
          }
        }).setLabel("Next")
      );
    }
    UImanager.add(startManager);
    startManager.add(
      new Button(width*0.75-125,height-50,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setNextStrategy(strategies.get("stage"));
        }
      }).setLabel("Start")
      .setEnable(false)
      .setHoverColor(new Color(40,80,40,180))
      .setColor(new Color(100,140,100,200))
    );
    startManager.add(missionText);
  }
  
  void update(){
    UImanager.handleUpdate();
  }
  
  void display(){
    UImanager.handleDisplay();
  }
  
  void displayShadow(){
    UImanager.handleDisplayShadow();
  }
}

class ConfigStrategy extends Strategy{
  
  ConfigStrategy(){
    super("menu","config");
  }
  
  void init(){
    UImanager.clearAll();
    UImanager.add(
      new Button(width*0.5-125,height-50,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setNextStrategy(strategies.get("menu"));
        }
      }).setLabel("Back")
      .setHoverColor(new Color(80,40,40,180))
      .setColor(new Color(140,100,100,200))
    );
    UImanager.add(
      new Button(width*0.5-125,75,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          show_fps=!show_fps;
          b.setLabel("Show FPS : "+(show_fps?"ON":"OFF"));
        }
      }).setLabel("Show FPS : "+(show_fps?"ON":"OFF"))
    );
    UImanager.add(
      new Button(width*0.5-125,135,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setVibration(!getVibration());
          b.setLabel("Vibration : "+(getVibration()?"ON":"OFF"));
        }
      }).setLabel("Vibration : "+(getVibration()?"ON":"OFF"))
    );
  }
  
  void update(){
    UImanager.handleUpdate();
  }
  
  void display(){
    UImanager.handleDisplay();
  }
  
  void displayShadow(){
    UImanager.handleDisplayShadow();
  }
}

class ShopStrategy extends Strategy{
  JSONManager tree;
  
  ShopStrategy(){
    super("menu","shop");
    tree=loadJSONObjectAsync("./data/skills/Tree.json");
  }
  
  void init(){
    UImanager.clearAll();
    UImanager.add(
      new FlowTextBox(new PVector(70,10),new PVector(250,30),20,new Color(0,0,0,100),new Color(230,230,230,200))
      .setText(new Supplier<String>(){
        String get(){
          return "Fusion Core: "+currentData.getInt("Fusion Core");
        }
      })
      .setAlign(CENTER)
    );
    UImanager.add(
      new FlowTextBox(new PVector(345,10),new PVector(250,30),20,new Color(0,0,0,100),new Color(230,230,230,200))
      .setText(new Supplier<String>(){
        String get(){
          return "Meta Material: "+currentData.getInt("Meta Material");
        }
      })
      .setAlign(CENTER)
    );
    UImanager.add(
      new FlowIcon(new Rectangle(new PVector(500,500),new PVector(50,50),0),5,new Color(0,255,255,80),new Color(120,120,120,180),loadImage("./data/image/Attack_mask.png"))
    );
    UImanager.add(
      new Button(width*0.5-125,height-50,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          setNextStrategy(strategies.get("menu"));
        }
      }).setLabel("Back")
      .setHoverColor(new Color(80,40,40,180))
      .setColor(new Color(140,100,100,200))
    );
  }
  
  void update(){
    UImanager.handleUpdate();
  }
  
  void display(){
    UImanager.handleDisplay();
  }
  
  void displayShadow(){
    UImanager.handleDisplayShadow();
  }
}

class StageStrategy extends Strategy{
  GameSystem system;
  ComponentManager pauseManager=new ComponentManager();
  
  StageStrategy(){
    super("menu","stage");
  }
  
  void init(){
    system=new GameSystem();
    UImanager.clearAll();
    pauseManager.clearAll();
    pauseManager.add(new Filter(new Color(0,0,0,150)));
    pauseManager.add(new FlowText("Pause",new PVector(width*0.5,100),100,3,new Color(200,200,200,200)));
    pauseManager.add(new Button(width*0.5-125,height*0.5-50,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          system.pause=false;
          pauseManager.setActive(false);
        }
      }).setLabel("Continue")
      .setHoverColor(new Color(40,80,40,180))
      .setColor(new Color(100,140,100,200))
    );
    pauseManager.add(new Button(width*0.5-125,height*0.5,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          init();
        }
      }).setLabel("Retry")
      .setHoverColor(new Color(40,80,40,180))
      .setColor(new Color(100,140,100,200))
    );
    pauseManager.add(new Button(width*0.5-125,height*0.5+50,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          system.pause=false;
          pauseManager.setActive(false);
          system.exit();
        }
      }).setLabel("Exit")
      .setHoverColor(new Color(80,40,40,180))
      .setColor(new Color(140,100,100,200))
    );
    UImanager.add(pauseManager.setActive(false));
    UImanager.add(new Button(width-50,50,30,30).setEvent(new ButtonEvent(){
        void select(Button b){
          system.pause=!system.pause;
          pauseManager.setActive(system.pause);
        }
      }).setLabel("×")
      .setHoverColor(new Color(20,20,80,120))
      .setColor(new Color(75,75,140,150))
    );
    gameSystem=system;
    stageList[(stageNumber-1)%5].addTask(new Consumer<JSONObject>(){
      void accept(JSONObject s){
        if(s.getInt("index")!=stageNumber){
          system.loadStage("./data/stage/Stage"+stageNumber+".json");
        }else{
          system.loadStage((stageNumber-1)%5);
        }
        setLight(system.stage.stage_time);
      }
    });
  }
  
  void update(){
    if(!stageData.isLoaded())return;
    UImanager.update();
    system.update();
  }
  
  void display(){
    if(!stageData.isLoaded())return;
    system.display();
    UImanager.display();
  }
  
  void displayShadow(){
    if(!stageData.isLoaded())return;
    system.displayShadow();
    UImanager.displayShadow();
  }
}

class ResultStrategy extends Strategy{
  
  ResultStrategy(){
    super("stage","result");
  }
  
  void init(){
    resetLight();
    setBackground(205,205,210);
    UImanager.clear();
    UImanager.add(
      new Button(width*0.5-125,height-50,250,30).setEvent(new ButtonEvent(){
        void select(Button b){
          resetBackground();
          setNextStrategy(strategies.get("menu"));
        }
      }).setLabel("OK")
    );
    UImanager.add(new FlowText(endState.equals("clear")?"Stage clear!":"Game over.",new PVector(width*0.5,100),75,3,new Color(100,100,100,200)));
    UImanager.add(new FlowText("Score :"+endScore,new PVector(width*0.5,200),30,3,new Color(255,0,0,150)));
  }
  
  void update(){
    UImanager.handleUpdate();
  }
  
  void display(){
    UImanager.handleDisplay();
  }
  
  void displayShadow(){
    UImanager.handleDisplayShadow();
  }
}
