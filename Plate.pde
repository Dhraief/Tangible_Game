class Plate {
  
  float x_rot; 
  float z_rot; 
  float speed;
  float pSize; 
  float pThick; 
  
  Plate(){
      x_rot = 0.0;
      z_rot = 0.0;
      speed = 0.2;
      pSize = 300;
      pThick = 15;
  }
  
  void display(){

      gameSurface.noStroke();
      gameSurface.fill(153);
      gameSurface.lights();
      gameSurface.translate(width/2, height/2, 0);
      gameSurface.rotateX(x_rot);
      gameSurface.rotateZ(z_rot);
      gameSurface.box(pSize, pThick, pSize);

  }  
  
  void display_ON_SHIFT(){

      gameSurface.noStroke();
      gameSurface.fill(0,200,0);
      gameSurface.lights();
      gameSurface.translate(width/2, height/2, 0);
      gameSurface.rotateX(-PI/2);
      gameSurface.box(pSize, pThick, pSize);


  }
  
}
