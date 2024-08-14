uniform vec2 resolution;
uniform sampler2D texture;

void main(){
  vec2 tFrag=vec2(1.0)/resolution;
  vec2 uv=gl_FragCoord.xy*tFrag;
  vec4 sum=texture2D(texture,uv);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(-1.0,1.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(0.0,1.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(1.0,1.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(-1.0,0.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(1.0,0.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(-1.0,-1.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(0.0,-1.0))*tFrag);
  sum+=texture2D(texture,(gl_FragCoord.xy+vec2(1.0,-1.0))*tFrag);
  gl_FragColor=sum/9.0;
}