#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything


//#define time fGlobalTime;
float time = fGlobalTime;
float pi= acos(-1);

float box (vec3 p, float s){
  p=abs(p)-s;
  return max(p.x,max(p.y,p.z));
  
}
  
mat2 rot(float a){
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
  
}

float hou(vec3 p){

  
  float d = box(p,1.3);

  p.y+=2.6;
  d=min(d, box(p, 1.2));
  /*
  p.y+=2;
  p.xy *= rot(.4);
  p.xy *= rot(.75);
  d=min(d, box(p, 1));
  */
  return d;
  
}

vec3 tunnel(vec3 p) {
  vec3 off=vec3(0);
  //off.x +=(p.z*0.023)*20;
  //off.x +=(p.z*0.043)*20;
  //off.y +=(p.z*0.01)*50;
  return off;
}
  
float rnd(float t){
  return fract(sin(t*457.552)*567.652);
}

float curve(float t, float d) {
  float g=t/d;
  return mix(rnd(floor(g)), rnd(floor(g)+1), pow(smoothstep(0,1,fract(g)), 10));
}
    
float tick(float t) {
  return floor(t) + pow(smoothstep(0,1,fract(t)),2);
}


float map(vec3 p) {
  
  p+=tunnel(p);
  
  //vec3 p2=vec3(atan(p.x,p.y)*pi*4,length(p.xy)-10, p.z);
  vec3 p2=vec3(abs(atan(p.z,p.x))*10.-5., (10.-length(p)), abs(atan(length(p.xz),p.y))*10.-16.);
  p=p2;
  
  
  p.y -= 6;
  float dist=60;
  //p.z = (fract(p.z/dist-.5)-.5)*dist;
  
  
  float s=12;
  for(int i=0; i<5; ++i) {
    
    float tt=i*3.7+.2;// + time*.3 + tick(time/1.2 + i*3);
    p.xz *= rot(tt);
    p.xz = abs(p.zx);
    p.xz-=s;
    s*=0.7;
  }
  
  
  float d=hou(p);
  /*
  p.xz*=rot(.3);
  p.xy-=vec2(0.22,-.08);
  p=abs(p);
  d=min(d, hou(p+vec3(0.00,2.6,.1)));
  d=min(d, hou(p+vec3(0.00,5.2,.1)));
  d=min(d, hou(p+vec3(0.00,7.8,.1)));
 */
  
  d=min(d, hou(p/1.3+vec3(3,0,-1))*1.3);
  d=min(d, hou(p*1.5+vec3(4,6,-1))/1.5);
  
  d = min(d, -p.y);
  
  return d;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  
  uv *= 2/(length(uv)+1);
  
  vec3 s = vec3(14,0,-10);
  vec3 t = vec3(0,0,0);
  
  //float adv=0;//mod(time, 100) * 30;
  float adv=sin(time) * 2;
  
  s.z+=adv;
  t.z+=adv;
  
  s-=tunnel(s);
  t-=tunnel(t);
  
  vec3 cz=normalize(t-s);
  vec3 cx=normalize(cross(cz,vec3(0,1,0)));
  vec3 cy=normalize(cross(cz,cx));  
  
  //float fov = .4;
  float fov = .4 + smoothstep(0,1,abs(fract(time*.5)-.5)*2)*.4;
  vec3 r=normalize(cx*uv.x+cy*uv.y + cz * 0.7);
  
  vec3 p=s;
  float dd=0;
  float at=0;
  for(int i=0; i<200; ++i) {
    float d=map(p)*.6;
    if(d<0.001) break;
    p+=r*d;
    dd+=d;
    at += 0.2/(.2+d);
  }
   
  float fog=1-clamp(dd/200,0,1);
  
  vec3 col = vec3(0);
  vec2 off=vec2(0.01,0);
  vec3 n=normalize(map(p)-vec3(map(p-off.xyy),map(p-off.yxy),map(p-off.yyx)));
  
  vec3 l = normalize(vec3(-1,-3,1));
  vec3 h=normalize(l-r);
  
  vec3 sky=mix(vec3(1,.5,1.2), vec3(1,.5,.2), pow(abs(r.z),5));
  
  float ao=1;//clamp(map(p+n),0,1)*clamp(map(p+n*.3)/3,0,1);
  col += max(0,dot(n,l))*fog * (0.5 + pow(max(0,dot(n,h)), 5) ) * ao;
  float fre=pow(1-abs(dot(r,n)), 4);
  col += fre * fog * ao * vec3(.5,.6,.7) * 5 * (-n.y*.5+.5) * sky;
  
  col += pow(1-fog, 1.7 ) * sky*6;
  col +=pow(at*.03, 0.6)*sky *.3;
  
  col *= 1.2-length(uv);

  
  out_color = vec4(col,1);
}