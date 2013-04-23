// ArduinoScope 
 
import processing.serial.*;
 
Serial ArduinoPort;  // Create object from Serial class
 
int NumOfScopes,NumOfInput=2;
int data_span=10000;
Strage dfs = new Strage();
Scope[] sp;
 
int fontsize=16;
PFont myFont;
 
void setup() 
{
  // Serial Port 
  println(Serial.list());
  String portName = Serial.list()[0]; // TODO: automatic detection?
  ArduinoPort = new Serial(this, portName, 38400);
  ArduinoPort.bufferUntil(10);
 
  // Screen
  size(800, 600);
  NumOfScopes=2;
  sp = new Scope[NumOfScopes];
  sp[0]= new Scope(0,50,10,width-100,height/2-35,512,-512,1000);
  sp[1]= new Scope(1,50,height/2+15,width-100,height/2-35,1024,0,1000);
 
  myFont = loadFont("Dotum-16.vlw");
  textFont(myFont,fontsize);
}
 
class Scope{
  int input_id;    // corresponding input
  int posx,posy;   // screen position of the scope
  int sizex,sizey; // pixel size of the scope
  float yu,yl;     // range of y is [yl,yu]
  int tspan;       //
  int ngx,ngy; // number of grids
  float maxposx,maxposy,minposx,minposy,maxx,minx,maxy,miny;
 
  Scope(int did,int px,int py,int sx,int sy,float syu,float syl,int ts){
    input_id=did;
    posx=px; 
    posy=py;
    sizex=sx; 
    sizey=sy;
    yu=syu; 
    yl=syl;
    tspan=ts;
    ngx=10; 
    ngy=4;
  }
 
  void grid(){
    pushStyle();
    fill(255,196);
    stroke(0,0,150);
    for(float gx=sizex; gx>=0; gx-= (float)sizex/ngx){
      line(posx+gx,posy,posx+gx,posy+sizey);
      textAlign(CENTER,TOP);
      text((int)map(gx,sizex,0,0,-tspan),posx+gx,posy+sizey+2);    
    }
    for(float gy=sizey; gy>=0; gy-= (float)sizey/ngy){
      line(posx,posy+gy,posx+sizex,posy+gy);
      textAlign(RIGHT,CENTER);
      text((int)map(gy,0,sizey,yu,yl),posx,posy+gy);    
    }
    popStyle(); 
  }
 
  int curx,cury;
 
  // draw cursor
  void cur()
  {
    // return if mouse cursor is not in this scope
    if(constrain(mouseX,posx,posx+sizex)!=mouseX 
      || constrain(mouseY,posy,posy+sizey)!=mouseY) return;
 
    pushStyle();
 
    // draw cross cursor
    stroke(255,0,0,196);
    fill(255,0,0,196);
    line(mouseX,posy,mouseX,posy+sizey);
    line(posx,mouseY,posx+sizex,mouseY);
 
    // draw measure if mouse is dragged
    if(mousePressed){
      line(curx,posy,curx,posy+sizey);
      line(posx,cury,posx+sizex,cury);
      textAlign(RIGHT,BOTTOM);
      text((int)map(curx,posx,posx+sizex,-tspan,0)+"ms, "+(int)map(cury,posy,posy+sizey,yu,yl),curx,cury);
      textAlign(LEFT,TOP); 
      text("("+nfp((int)map(mouseX-curx,0,sizex,0,tspan),1)+"ms, "+nfp((int)map(mouseY-cury,0,sizey,0,-(yu-yl)),1)+")\n"+nf(1000/map(mouseX-curx,0,sizex,0,tspan),1,2)+"Hz\n"+nf(TWO_PI*1000/map(mouseX-curx,0,sizex,0,tspan),1,2)+"rad/sec",mouseX,mouseY+2);
    }
    else{
      curx=mouseX;
      cury=mouseY;
      textAlign(RIGHT,BOTTOM);
      text((int)map(curx,posx,posx+sizex,-tspan,0)+"ms, "+(int)map(cury,posy,posy+sizey,yu,yl),curx,cury);
    }
    popStyle();
  }
 
  // draw min&max tick
  void minmax(){
    pushStyle();
    fill(255,128);
    stroke(0,0,100);
    textAlign(RIGHT,CENTER);
    line(posx,maxposy,posx+sizex,maxposy);
    text((int)maxy,posx,maxposy); 
    line(posx,minposy,posx+sizex,minposy);
    text((int)miny,posx,minposy); 
    textAlign(LEFT,CENTER);
    textAlign(CENTER,TOP);
    text("max",maxposx,maxposy); 
    textAlign(CENTER,BOTTOM);
    text("min",minposx,minposy+20); 
    popStyle();
  }
 
  // draw scope
  void Plot(){
    float sx,sy,ex,ey;
    int nof=0;
    DataFrame df_last = dfs.get(0);
 
    maxy=-1e10; // -inf
    miny=1e10;  // +inf
 
    // draw background (for transparency)
    pushStyle();
    noStroke();
    fill(0,0,64,64);
    rect(posx,posy,sizex,sizey);
    popStyle();
 
    // draw data plot
    pushStyle();
    stroke(0,255,0);
    smooth();
    strokeWeight(1);
    for(int idx=0;(dfs.get(idx).t>max(df_last.t-tspan,0)) && -idx<data_span;idx--){
      DataFrame df_new=dfs.get(idx);
      DataFrame df_old=dfs.get(idx-1);
      sx=(float) map(df_new.t, df_last.t, df_last.t - tspan, posx+sizex,posx);
      ex=(float) map(df_old.t, df_last.t, df_last.t - tspan, posx+sizex,posx);
      sy=(float) map((float)df_new.v[input_id],(float) yu,(float) yl,(float) posy,(float) posy+sizey );
      ey=(float) map((float)df_old.v[input_id],(float) yu,(float) yl,(float) posy,(float) posy+sizey );
      if(ex<posx){
        ey+=(sy-ey)*(posx-ex)/(sx-ex);
        ex=posx;
      }
      line(sx,sy,ex,ey);
      maxy=max(maxy,df_new.v[input_id]);
      if(maxy==df_new.v[input_id]){
        maxposx=sx;
        maxposy=sy;
      }
      miny=min(miny,df_new.v[input_id]);
      if(miny==df_new.v[input_id]){
        minposx=sx;
        minposy=sy;
      }
      nof++;
    }
    popStyle();
 
    //    minmax();    
 
    // draw current value of input
    pushStyle();
    textAlign(LEFT,CENTER);
    stroke(0,0,64);
    fill(0,255,0,196);
    text(df_last.v[input_id],posx+sizex,map(df_last.v[input_id], yu, yl, posy, posy+sizey ));
    popStyle();   
 
    grid();
    cur();    
  }
}
 
void draw() 
{ 
  background(0);
 
  for(int i=0;i<NumOfScopes;i++){
    sp[i].Plot();
  }
}
 
// input data buffer class
// (now using ring buffer)
class Strage{
  int cur;
  DataFrame[] DataFrames;
 
  Strage(){
    cur=0;
    DataFrames=new DataFrame[data_span];
    for(int idx=0;idx<data_span;idx++){
      int ret_v[] = new int[NumOfInput];
      DataFrames[idx] = new DataFrame(0,ret_v);
    }
  }
 
  void push(DataFrame d){
    cur = ((cur+1) %data_span);
    DataFrames[cur]=d;
  }
 
  DataFrame get(int idx)
  {
    int num=(cur+idx);
    for(; num<0; num+= data_span);
    return((DataFrame) DataFrames[num]);
  }
 
  void save()
  {
    String savePath = selectOutput();  // Opens file chooser
    if (savePath == null) {
      // If a file was not selected
      println("No output file was selected...");
    }else{
      PrintWriter output;
      output = createWriter(savePath); 
      DataFrame df_last = this.get(0);
      for(int idx=0;-idx<data_span;idx--){
        if(this.get(idx).t==0) break;
        output.print(this.get(idx).t-df_last.t);
        for(int k=0;k<NumOfInput;k++){
          output.print(","+this.get(idx).v[k]);
        } 
        output.println("");
      }
      output.flush();
      output.close();
    }
  }
}
 
class DataFrame{
  int t;
  int[] v;
  DataFrame(int st, int[] sv){
    t=st;
    v=sv.clone();
  }
}
 
boolean isactive=true;
 
// buffering data from serial port
void serialEvent(Serial myPort)
{
  int[] vals=new int[NumOfInput];
  int timestamp;
  int[] splitdata;
  if( myPort.available() > 0) { 
    String datline=myPort.readString();
    splitdata=parseInt(datline.split(","));
    if((splitdata.length==NumOfInput+2)){
      timestamp=splitdata[0];
      for(int idx=0;idx<NumOfInput;idx++){
        vals[idx]=splitdata[idx+1];
      }
      if(isactive){
        if((timestamp-dfs.get(0).t)<0){
          dfs.cur--;
        }
        if((timestamp-dfs.get(0).t) > ((float)sp[0].tspan / sp[0].sizex/2.0) ){
          dfs.push( new DataFrame(timestamp,vals));
        }
      }
    }
  }
}
 
// keyboard user interface
void keyPressed(){
  switch(key){
    // activate/deactivate scope update
  case ' ':
    isactive=!isactive;
    break;
    // save record
  case 's':
    dfs.save();
    break;
  case CODED:
    switch(keyCode){
      // Increse time span
    case UP:
      for(int i=0;i<NumOfScopes;i++){
        sp[i].tspan*=2;
      }
      break;
      // Decrease time span
    case DOWN:
      for(int i=0;i<NumOfScopes;i++){
        sp[i].tspan/=2;
      }
      break;
    }
    break;
  }
}
 
/* Arduino code
void setup()
{
  Serial.begin(38400);  
}
 
void loop()
{
  Serial.print(millis());
  Serial.print(",");
  Serial.print(analogRead(0));
  Serial.print(",");
  Serial.print(analogRead(1));
  Serial.println(",");
}
*/
