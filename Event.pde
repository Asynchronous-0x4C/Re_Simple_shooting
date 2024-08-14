HashMap<String,Consumer<Float>> boss_events=new HashMap<String,Consumer<Float>>();

Consumer<Float> summon_Lost_Signal=new Consumer<Float>(){
  void accept(Float f){
    RelativeSchedule[] rs=new RelativeSchedule[1];
    rs[0]=new RelativeSchedule(7.0,new Consumer<Float>(){
      void accept(Float f){
        if(f<=0){
          getGameSystem().getPlayer().setPlayerInput(false);
          getGameSystem().ui.components.add(new E2GAdapter(new BossParticleGenerator(new Color(0,0,0,50),new Rectangle(new PVector(width*0.5,-25),new PVector(width,50),0),
            new Supplier<PVector>(){
              PVector get(){
                return new PVector(0,random(4.0,5.0));
              }
            },
            new Supplier<Float>(){
              Float get(){
                return random(240,300);
              }
            })).setConsumer(new Consumer<Entity>(){
              void accept(Entity e){
                ((BossParticleGenerator)e).generate(random(0.1));
              }
            })
          );
          getGameSystem().ui.components.add(new DynamicFlowRect(new Function<DynamicFlowRect,Rectangle>(){
            Rectangle apply(DynamicFlowRect r){
              float t=rs[0].time-4.5;
              if(t<0.5){
                float y=easeOutExpo(t*2)*100;
                return new Rectangle(new PVector(width*0.5,y),new PVector(25,25),0);
              }else if(t<1.0){
                float x=easeOutExpo((t-0.5)*2)*width;
                return new Rectangle(new PVector(width*0.5,100),new PVector(x,25),0);
              }else if(t<1.5){
                float y=easeOutExpo((t-1.0)*2)*50+25;
                return new Rectangle(new PVector(width*0.5,100),new PVector(width,y),0);
              }else if(t<2.0){
                float x=width-easeOutExpo((t-1.5)*2)*(width-75);
                return new Rectangle(new PVector(width*0.5,100),new PVector(x,75),0);
              }else if(t<2.5){
                float x=1-ease25(t-2.0);
                r.setColor(new Color(255*x,128*x,0,150));
              }
              return new Rectangle(new PVector(width*0.5,100),new PVector(75,75),0);
            }
          },3,new Color(255,128,0,150)));
        }else if(f>=7){
          getGameSystem().ui.components.remove(getGameSystem().ui.components.size()-1);
          getGameSystem().nextEntity.add(new Lost_Signal(getGameSystem().nextEntity).setPosition(new PVector(width*0.5,100)));
          getGameSystem().getPlayer().setPlayerInput(true);
        }
      }
    });
    getGameSystem().stage.next_schedules.add(rs[0]);
  }
};

void initEvent(){
  boss_events.put("summon_Lost_Signal",summon_Lost_Signal);
}
