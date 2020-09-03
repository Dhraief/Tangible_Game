class Mover {
  
  PVector pos; // Coordinate vector of ball.
  PVector vel; // vel vector of ball.
  PVector g; // Gravity vector.
  PVector fric; // fric vector.
  float radius; // Ball radius.
  float GRAVITY = 0.5; // Gravity constant.
  float REBOUND_COEF = 0.7; // Rebound coeeficient.
  float fricMagnitude = 0.01; // fric force magnitude = normal Force * mu (1 * 0.01).
  
  Mover(){
      radius = 7; 
      pos = new PVector(0, - (radius + plate.pThick/2), 0);
      vel = new PVector(0, 0, 0);
      g = new PVector(0, 0, 0);
  }
  
  void display() {
      gameSurface.pushMatrix();
      gameSurface.noStroke();
      gameSurface.fill(0, 255, 0);
      gameSurface.lights();
      gameSurface.translate(pos.x, pos.y, pos.z);
     
      gameSurface.sphere(radius);
      gameSurface.popMatrix();
  }
    
  void update(Plate b){
      if(!shiftOn()){
        fric = vel.copy().mult(-1).normalize().mult(fricMagnitude);
        g.set(sin(b.z_rot)*GRAVITY, 0, -sin(b.x_rot)*GRAVITY);
        vel.add(g);
        vel.add(fric);
        pos.add(vel);
      }
  }
  
void checkEdges(){
     //CHANGED
     float  limit= (plate.pSize/2);
     if(pos.x > limit) {
       vel.x = vel.x * -REBOUND_COEF;
       pos.x = limit;
     }else if(pos.x < -limit){
       vel.x = vel.x * -REBOUND_COEF;
       pos.x = -limit;
     }
     if(pos.z >limit){
       vel.z = vel.z * -REBOUND_COEF;
       pos.z = limit;
     }else if(pos.z < -limit){
        vel.z = vel.z * -REBOUND_COEF;
        pos.z = -limit;
     }
}
   
   
boolean checkEdgesWithCylinders(Cylinder cylinder){
     PVector relPos = new PVector(pos.x - cylinder.posC.x, pos.z - cylinder.posC.z);
     if(relPos.mag() <= radius + cylinder.radius){
         pos.x = pos.x + relPos.x  / (radius+cylinder.radius);
         pos.z = pos.z + relPos.z / (radius+cylinder.radius);
         PVector normal = new PVector(pos.x - cylinder.posC.x, 0, pos.z - cylinder.posC.z).normalize();
         vel = PVector.sub(vel, normal.mult(PVector.dot(vel, normal) * 2));
         return true;
     }
     return false;
}
   
void display_ON_SHIFT(){
     gameSurface.pushMatrix();
     gameSurface.noStroke();
     gameSurface.fill(150,0,0);
     gameSurface.lights();
     gameSurface.translate(pos.x, -(radius + plate.pThick/2), pos.z);
     gameSurface.sphere(radius);
     gameSurface.popMatrix();
} 

}
