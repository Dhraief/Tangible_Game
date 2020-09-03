//CONSTANTES
public static final int WIDTH = 1500;
public static final int HEIGHT = 1100;
public static final float TOPV_SCALE = 1.4;

final float COEF_SPEED =0.125;        // Speed of plate coefficient
final float MAX_ANGLE = PI/3;         // MAX rotation angle
final float MAX_SPEED_P = 1;          // Max value of speed of plate
final float MIN_SPEED_P = 0.2;        // Min value of Speed of plate
final float U_SPEED_P = 0.1;          // Update speed for plate

//__________________________________________
//SCORE RELATED
public static  int score;
public static  int lastScore;
public ArrayList<Integer> scoreList;
public HScrollbar scrollBar;
//__________________________________________
//GRAPHICS RELATED
PGraphics gameSurface;
PGraphics background; 
PGraphics topView; 
PGraphics scoreView; 
PGraphics barChart;
//__________________________________________
//ELEMENTS
PShape rNik;
ParticleSystem ps;              //Particle System (appear cylinders)
Plate plate;                    // Plate
Mover ball;                     // Ball on plate
ArrayList<Cylinder> cylinders;  // List of cylinders on plate

//__________________________________________

public float space=0;
public float heightOrigin=100;
public int time=0;
boolean isRunning = false;
boolean isDestroyed = false;

//CAMERA
ImageProcessing imgproc;

void settings(){
  size(displayWidth , displayHeight, P3D);
}

void setup(){
  //DISPLAY
  scoreList= new ArrayList();
  scrollBar= new HScrollbar(0.68*displayWidth, 0.75*displayHeight,400,30);
  score=0;
  lastScore=0;
  plate = new Plate();
  ball= new Mover();
  rNik = loadShape("robotnik.obj");
  //CAMERA
  imgproc = new ImageProcessing();
  String []args = {"Image processing window"};
  PApplet.runSketch(args, imgproc);
  //CREATION
  gameSurface=createGraphics(displayWidth,displayHeight-200,P3D);
  background=createGraphics(displayWidth,200);
  topView=createGraphics(200,200,P2D);
  scoreView=createGraphics(200,200,P2D);
  barChart=createGraphics(displayWidth -475,200,P2D);
  gameSurface.fill(255);
  gameSurface.noStroke(); 
}

void draw () {
  //CAMERA 
  PVector ang = imgproc.getRotations();
  if(ang == null) ang = new PVector(plate.x_rot,0,plate.z_rot);
  if(ang.x < -PI/3) ang.x += PI; else if(ang.x > PI/3) ang.x -= PI;
  if(ang.z < -PI/3) ang.z += PI; else if(ang.z > PI/3) ang.z -= PI;
  if(imgproc.quad() && ang.x>=-MAX_ANGLE && ang.x <= MAX_ANGLE && ang.z>=-MAX_ANGLE && ang.z<= MAX_ANGLE){
    plate.x_rot = (6*plate.x_rot+ang.x)/7;
    plate.z_rot = (6*plate.z_rot+ang.z)/7;
  }
  //DISPLAY
  background(255);
  drawTopView();
  drawGame();
  drawBackground();
  drawScoreView();
  drawBarChartView();
  image(gameSurface,0,0); 
  image(background,0,displayHeight-200);  
  scrollBar.display();          
  scrollBar.update();
  image(topView,0,displayHeight-200);  
  image(scoreView,225,displayHeight-200);  
  image(barChart,450,displayHeight-200);
}

void drawScoreView() {
  scoreView.beginDraw();
    scoreView.background(200,200,200);
    scoreView.textSize(20);
    scoreView.fill(50);
    scoreView.text("Total Score : " + score,10,70);
    scoreView.text("Velocity : " +  ball.vel.mag(), 10,20);
    scoreView.text("Last Score : " + lastScore,10,120);
  scoreView.endDraw();
}

void drawBarChartView(){
    barChart.beginDraw();
    barChart.background(160,160,160);  
    generateRect();

    //update the rectangles amount every 2 seconds
    if(millis() - time >=   1000 && isRunning && !isDestroyed){
      if(ps.centers.isEmpty()){
        scoreList = new ArrayList();
      } else{
         scoreList.add(score);   
         time = millis();
      }
    }
    barChart.endDraw();
}

void drawBallTopView() {    
    float relativePosX = (float)topView.width /2 + (ball.pos.x * ((float)topView.width / plate.pSize));
    float relativePosZ = (float)topView.height /2 +(ball.pos.z * ((float)topView.height / plate.pSize));
    topView.fill(0,128,255);
    topView.ellipse(relativePosX, relativePosZ, ball.radius*TOPV_SCALE, ball.radius*TOPV_SCALE);
}
  
void drawCylinders() {
     float c_xPos;
     float c_zPos;
    for(PVector c : ps.centers) {
      
      Cylinder cyl = new Cylinder(c.x,c.y,c.z);
       c_xPos = (float)topView.width /2 + (cyl.posC.x * ((float)topView.width / plate.pSize));
       c_zPos = (float)topView.height /2 +(cyl.posC.z * ((float)topView.height / plate.pSize));
      if(c == ps.centers.get(0))
       {  topView.fill(185,50,60);}
      else
       { topView.fill(0,76,135);}
        topView.ellipse(c_xPos, c_zPos, ParticleSystem.particle_radius*TOPV_SCALE,  ParticleSystem.particle_radius*TOPV_SCALE);
    }
}
  

void drawTopView() {
  topView.beginDraw();
    topView.background(200,200,200);
    drawBallTopView();
    if(isRunning && !isDestroyed)
      { drawCylinders() ; }
   topView.endDraw();
}

void updateScore(boolean up){
    if (up){ // there is a hit
          lastScore=score;
          score += 2*ball.vel.mag();
    } else{
      score -= 1;
    }
}

void drawBackground() {
   background.beginDraw();
   background.background(100);
   background.endDraw();
}

void drawGame() {
    gameSurface.beginDraw();
    gameSurface.pushMatrix();
    gameSurface.scale(0.7);
    gameSurface.popMatrix();  
    gameSurface.background(255,255,255); 
    gameSurface.fill(0);
    gameSurface.text("Rotation en X: " + plate.x_rot ,10,30);
    gameSurface.text("Rotation en Z: " + plate.z_rot,10,60 );
    gameSurface.text("Speed: " + plate.speed,10,90 );
    
     if(shiftOn()){
         //SHIFT ON DRAWING
          plate.display_ON_SHIFT();
          ball.display_ON_SHIFT();
          if(isRunning && !isDestroyed){ps.run();}
     }
     else{
         //SHIFT OFF DRAWING
         plate.display();
         if(frameCount% 60 == 0 && isRunning && !isDestroyed){
           ps.addParticle();
         }
         ball.update(plate);
         ball.checkEdges();
         if(isRunning && !isDestroyed){
           
           if(ball.checkEdgesWithCylinders(new Cylinder(ps.centers.get(0).x,ps.centers.get(0).y,ps.centers.get(0).z))){
             for(int i = 0; i < ps.centers.size(); i++){
              updateScore(true); 
               ps.centers.remove(i);
             }
             isDestroyed = true;
           }else{
             for(int i = 1; i < ps.centers.size(); i++){
                if(ball.checkEdgesWithCylinders(new Cylinder(ps.centers.get(i).x,ps.centers.get(i).y,ps.centers.get(i).z))){

                   updateScore(true); 
                  ps.centers.remove(i);
                }
             }
           }
           
         }
         ball.display();
         if(isRunning && !isDestroyed) { ps.run();}
         //HERE WE DRAW ROBOTNIK
         if(isRunning && !isDestroyed){
           ps.drawRobot(rNik);
         }
     } 
     gameSurface.endDraw();
}

void mouseWheel(MouseEvent event){
   if(!shiftOn()){
    float wheel = event.getCount();
    plate.speed =(wheel > 0)? min(plate.speed + U_SPEED_P, MAX_SPEED_P):max(plate.speed - U_SPEED_P, MIN_SPEED_P);
   }
} 
  
void mouseDragged(){  
  //ADDED LOCKED
   if(!shiftOn() && !scrollBar.locked){
      if(mouseY < pmouseY){
        plate.x_rot = min(plate.x_rot + (COEF_SPEED*plate.speed), MAX_ANGLE);
      } else if(mouseY > pmouseY){
        plate.x_rot = max(plate.x_rot - (COEF_SPEED*plate.speed), -MAX_ANGLE);
      }
      if(mouseX > pmouseX){
        plate.z_rot = min(plate.z_rot + (COEF_SPEED*plate.speed), MAX_ANGLE);
      } else if(mouseX < pmouseX){
        plate.z_rot = max(plate.z_rot - (COEF_SPEED*plate.speed), -MAX_ANGLE);
      }
   }
}

void generateRect(){
  
  int scoreSign = 0 ; //  signe du score 
  int columnScore = 0; // score à un instant t précis
  float squareDim = 10; 

  if(scrollBar.getPos()> 0.5){
    squareDim += abs(scrollBar.getPos()-0.5)*squareDim;
  }else if (scrollBar.getPos()<0.5){                // when it's equal to 0.5 we leave it as it is
    squareDim -= abs(scrollBar.getPos()-0.5)*squareDim;
  }
  
  
  for(int c = 0; c<scoreList.size();c++){
      columnScore = scoreList.get(c);
      if(columnScore != 0)
      scoreSign = columnScore/abs(columnScore);
       int indiceMax=ceil (abs(columnScore)/2.5);
      for(int i = 0; i<indiceMax;i++){  
         
          float yRec=heightOrigin-scoreSign*i*squareDim;
           barChart.fill(1000*(yRec/HEIGHT),130,30);

          barChart.rect(space,yRec,squareDim,squareDim);
      }
      space+=squareDim;
  }
  space = 5;
}


void mouseClicked(){
  if(shiftOn()){
    Cylinder cylinder = new Cylinder(mouseX, -plate.pThick/2, mouseY);
    if(cylinder.isInPlate() && !cylinder.isOverlap(new ArrayList<Cylinder>())){
      ps = new ParticleSystem(new PVector(mouseX, -plate.pThick/2,mouseY));
      isRunning = true;
      isDestroyed = false;
    }
  }
}

boolean shiftOn(){
   return keyPressed == true && keyCode == SHIFT;
}
