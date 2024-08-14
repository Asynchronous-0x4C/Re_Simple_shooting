let ref_applet;
let initialized=false;
let apple=false;
let vibrate=true;

const pointers=[...Array(10)];
const workers=[];
let results=0;

function setReference(s){
  ref_applet=s;
  const agent=navigator.userAgent.toLowerCase();
  if(agent.indexOf("macintosh") != -1 ||
     agent.indexOf("ipad") != -1 ||
     agent.indexOf("iphone") != -1 ||
     agent.indexOf("ipod") != -1){
    apple=true;
  }
}

function loadJSONObject(path){
  const path_arr=path.split("/");
  if(localStorage[path_arr[path_arr.length-1]]){
    path=path_arr[path_arr.length-1];
    const item=localStorage.getItem(path);
    if(item==null)return null;
    return new JSONObject(JSON.parse(item));
  }else{
    const xhr = new XMLHttpRequest();
    xhr.open("GET", path, false);
    if (xhr.overrideMimeType) {
      xhr.overrideMimeType("text/plain");
    }
    xhr.setRequestHeader("If-Modified-Since", "Fri, 01 Jan 1960 00:00:00 GMT");
    xhr.send(null);
    if (xhr.status !== 200 && xhr.status !== 0) { return null; }
    return new JSONObject(JSON.parse(xhr.responseText));
  }
}

function saveJSONObject(obj,path){
  let path_arr=path.split("/");
  path=path_arr[path_arr.length-1];
  localStorage.setItem(path,obj);
}

function circle(x,y,l){
  ref_applet.ellipse(x,y,l,l);
}

function isWeb(){
  return true;
}

function isApple(){
  return apple;
}

class JSONObject{

  constructor(json){
    this.json=json;
  }

  static parse(str){
    return new JSONObject(JSON.parse(str));
  }

  hasKey(str){
    return this.json[str]!=null;
  }

  isNull(str){
    return this.json[str]==null;
  }

  toString(){
    return JSON.stringify(this.json);
  }

  getInt(name,init){
    return this.json[name]==null?init:this.json[name];
  }

  setInt(name,val){
    if(val!=null)this.json[name]=val;
  }

  getFloat(name,init){
    return this.json[name]==null?init:this.json[name];
  }

  setFloat(name,val){
    if(val!=null)this.json[name]=val;
  }

  getString(name,init){
    return this.json[name]==null?init:this.json[name];
  }

  setString(name,val){
    if(val!=null)this.json[name]=val;
  }

  getBoolean(name,init){
    return this.json[name]==null?init:this.json[name];
  }

  setBoolean(name,val){
    if(val!=null)this.json[name]=val;
  }

  getJSONObject(name){
    return new JSONObject(this.json[name]);
  }

  setJSONObject(name,val){
    if(val!=null)this.json[name]=val;
  }

  getJSONArray(name){
    return new JSONArray(this.json[name]);
  }

  setJSONArray(name,val){
    if(val!=null)this.json[name]=val;
  }

  keys(){
    return Object.keys(this.json);
  }
}

class JSONArray{

  constructor(json){
    this.json=json;
  }

  getJSONArray(index){
    return new JSONArray(this.json[index]);
  }

  getJSONObject(index){
    return new JSONObject(this.json[index]);
  }

  getString(index){
    return this.json[index];
  }

  size(){
    return this.json==undefined?0:Object.keys(this.json).length;
  }
}

class InstanceFactory{
  
  constructor(s){
    this.applet=s;
    this.constructors=[];
  }
  
  contains(name){
    return this.constructors.includes(name);
  }
  
  putConstructor(name){
    this.constructors.push(name);
  }
  
  getInstance(name,entityList){
    return eval(`new ref_applet.${name}(entityList)`);
  }
}

function initAudio(){
  
}

function getClassName(o){
  return o.constructor.name;
}

class Sound{

  constructor(path){
    this.audio=new Audio();
    this.audio.preload = "auto";
    this.audio.src=path;
    this.audio.load();
  }

  play(){
    if(apple)return;
    this.audio.currentTime = 0;
    this.audio.loop = false;
    this.audio.play();
  }

  setVolume(v){
    this.audio.volume=v;
  }

  setMute(m){
    this.audio.muted=m;
  }
}

function getNanoSeconds(){
  return performance.now()*1000000.0;
}

function damage_vibrate(){
  if(!apple&&vibrate){
    const id=setInterval(()=>{
      navigator.vibrate([0,1,0]);
      clearInterval(id);
    },100);
  }
}

function boss_vibrate(){
  if(!apple&&vibrate){
    const id=setInterval(()=>{
      navigator.vibrate(100);
      clearInterval(id);
    },180);
  }
}

function boss_damage_vibrate(){
  if(!apple&&vibrate){
    const id=setInterval(()=>{
      navigator.vibrate(100);
      clearInterval(id);
    },150);
  }
}

function setVibration(b){
  vibrate=b;
}

function getVibration(){
  return vibrate;
}

function loaded(){
  document.getElementById('re-fullScreen').addEventListener('click', function(){
    document.body.requestFullscreen();
    setTimeout(()=>{
      ref_applet.setup();
    },20);
  });
  document.getElementById('re-reload').addEventListener('click', function(){
    location.reload();
  });
  document.getElementById("app").addEventListener("click",(el,ev)=>{
    ref_applet.setMousePress(true);
    if(!initialized){
      ref_applet.loadSound();
      initialized=true;
    }
  });
  document.getElementById("app").addEventListener("mousedown",(el,ev)=>{
    ref_applet.JSMousePressed();
  });
  resized();
}

function startEntityProcess(s){
  const collision=s.gameState=="shooting";
  // const size=s.entities.size()/4.0;
  // for(let i=0;i<workers.length;i++){console.log(s.entities);
  //   workers[i].postMessage(JSON.parse(JSON.stringify({"s":Math.round(size*i),"e":Math.round(size*(i+1)),"c":collision,"src":s.entities})));
  // }
  for(let n=0;n<s.entities.size();n++){
    const e=s.entities.get(n);
    e.update();
    if(!e.isDead){
      if(collision){
        for(let i=0;i<s.nextEntity.size();i++){
          const _e=s.nextEntity.get(i);
          if(e===_e||((_e instanceof ref_applet.Enemy)&&(e instanceof ref_applet.Enemy))){
            continue;
          }else if(ref_applet.colliderCollision(e.collider,_e.collider)){
            e.Collision(_e);
            _e.Collision(e);
          }
        }
      }
      s.nextEntity.add(e);
    }
  }
}

function waitEntityProcess(s){
  if(s.pause)return;
  // while(results<4){console.log("wait",results);
  // }
  // for(let e of s.entities){
  //   if(!e.isDead)s.nextEntity.add(e);
  // }
  s.entities.clear();
  s.entities.addAll(s.nextEntity);
  s.nextEntity.clear();
}

addEventListener("pointerdown",e=>{
  pointers[e.pointerId]={press:true,pressed:true,x:e.clientX,y:e.clientY};
  //console.log(e.pointerId);
});

addEventListener("pointermove",e=>{
  pointers[e.pointerId]={press:false,pressed:true,x:e.clientX,y:e.clientY};
  //console.log(e.pointerId);
});

addEventListener("pointerup",e=>{
  pointers[e.pointerId]={press:false,pressed:false,x:e.clientX,y:e.clientY};
  //console.log(e.pointerId);
});

addEventListener('resize',resized);

function getDPR(){
  return window.devicePixelRatio||1;
}

function setTextureSampling(){
  const canvas=document.getElementById("app");
  const ctx=canvas.getContext("2d");
  ctx.imageSmoothingEnabled=false;
}

function resized(){
  const canvas=document.getElementById("app");

  let w=window.innerWidth;
  let h=window.innerHeight;

  canvas.style.width=w+'px';
  canvas.style.height=h+'px';

  canvas.width=w*getDPR();
  canvas.height=h*getDPR();

  //ctx.scale(getDPR(),getDPR());console.log(getDPR(),window.devicePixelRatio||1)
}