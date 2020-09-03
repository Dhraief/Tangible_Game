class Cylinder {
  
  PVector posC;                          // Coordinate vector of ball.
  float radius = 15;                     // Cylinder radius.
  float c_height = 50;                   // Cylinder height.
  int resolution = 40;                   // Cylinder resolution.
  PShape openCylinder = new PShape();    // The empty shell cylinder.
  PShape top = new PShape();             // The top circle of the cylinder.
  PShape bottom = new PShape();          // The bottom circle of the cylinder.
  PShape f_cylinder = new PShape();      // A shape to unit them all, the complete cylinder.
  float angle;                           // Use to create the cylinder.
  float[] x = new float[resolution + 1]; // Use to create the cylinder.
  float[] z = new float[resolution + 1]; // Use to create the cylinder.

  /*
  * Creates a new cylinder object, initialize his pos
  * and forms the object.
  */
  Cylinder(float x_pos, float y_pos, float z_pos){
      fill(128, 128, 128);
      // lights();
      posC = new PVector(x_pos - width/2, y_pos, z_pos - height/2);
      for(int i = 0; i < x.length; i++) {
        angle = (TWO_PI / resolution) * i;
        x[i] = sin(angle) * radius;
        z[i] = cos(angle) * radius;
      }
      openCylinder = createShape();
      top = createShape();
      bottom = createShape();
      openCylinder.beginShape(QUAD_STRIP);
      bottom.beginShape(TRIANGLE_FAN);
      top.beginShape(TRIANGLE_FAN);
      bottom.vertex(0, 0, 0);
      top.vertex(0, -c_height, 0);
      for(int i = 0; i < x.length; i++) {
        openCylinder.vertex(x[i], 0 , z[i]);
        openCylinder.vertex(x[i], -c_height, z[i]);
        bottom.vertex(x[i], 0, z[i]);
        top.vertex(x[i], -c_height, z[i]);
      }
      openCylinder.endShape();
      bottom.endShape();   
      top.endShape(); 
      f_cylinder = createShape(GROUP);
      f_cylinder.addChild(bottom);
      f_cylinder.addChild(openCylinder);
      f_cylinder.addChild(top);
  }
  
  void display(){

      gameSurface.pushMatrix();
      gameSurface.translate(posC.x, posC.y, posC.z);
      gameSurface.shape(f_cylinder); 
      gameSurface.popMatrix();
  }
  
  boolean isInPlate(){
      return ((abs(posC.x) <= plate.pSize/2-radius) && (abs(posC.z) <= plate.pSize/2-radius));
  }
  
  boolean isOverlap(ArrayList<Cylinder> cylinders){
     PVector d_ball = new PVector(posC.x - ball.pos.x, posC.z - ball.pos.z);
     float distance_Ball = d_ball.mag();
     if(distance_Ball <= radius + ball.radius){
       return true;
     }
     for(int i = 0; i < cylinders.size(); i++){
         PVector dist = new PVector(posC.x - cylinders.get(i).posC.x, posC.z - cylinders.get(i).posC.z);
         float distance = dist.mag();
         if((distance <= 2 * radius)){
           return true;
         }
     }
     return false;
  }

}
