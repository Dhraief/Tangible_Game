import processing.video.*;
import gab.opencv.*;
import java.util.List;
import java.util.ArrayList;
import java.util.TreeSet;
import java.lang.Math;
import java.util.Collections;

class ImageProcessing extends PApplet{
  Movie cam;
  List<PVector> quads;
  PImage img;
  TwoDThreeD angles;
  OpenCV opencv;
  PVector rot;
  Boolean quadExists = false;
  
  void settings(){
    size(300, 200);
  }
  void setup(){
    cam = new Movie(this, "C:\\testvideo.avi");
    cam.loop();
    opencv=new OpenCV(this,100,100);
    angles = new TwoDThreeD(cam.width, cam.height, 100);
  }
  void draw(){
    if (cam.available() == true) {
      cam.read();
    }
    img = cam.get();
    if(img.height != 0){
    img.resize(300,200);
    }
    image(img,0,0);
    PImage img2 = new PImage();
    img2 = HBSthresholding(img, 91, 139, 30, 240, 25, 180);
    img2 = gaussianBlur(img2);
    img2 = findConnectedComponents(img2, false);
    img2 = scharr(img2);
    img2 = brightnessThresholdingBinary(img2, 150, 255);
    List<PVector> hou = hough(img2);
    QuadGraph qg = new QuadGraph();
    quads = qg.findBestQuad(hou, img.width, img2.height, img.width*img.height, 2, false);
    houghFindIntersections(hou, img);
    drawIntersections(quads);
    quadExists = quads.size() > 0;
    for(PVector quad: quads){
      quad.z = 1f;
    }
    rot = angles.get3DRotations(quads);
  }

PVector getRotations(){
   return rot;
}
Boolean quad(){
  return quadExists;
}

void drawIntersections(List<PVector> intersections) {
    for(int i = 0; i < 4; i++){
      if(i == 0) fill(#efd807);
      if(i == 1) fill(#FF0000);
      if(i == 2) fill(#008000);
      if(i == 3) fill(#ff7f00);
      if(intersections.size()>0)
       ellipse(intersections.get(i).x, intersections.get(i).y, 20, 20);
    }
}

void houghFindIntersections(List<PVector> lines, PImage edgeImg){
  for (int idx = 0; idx < lines.size(); idx++) {
    PVector line=lines.get(idx);
    float r = line.x;
    float phi = line.y;
    int x0 = 0;
    int y0 = (int) (r / sin(phi));
    int x1 = (int) (r / cos(phi));
    int y1 = 0;
    int x2 = edgeImg.width;
    int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
    int y3 = edgeImg.width;
    int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
    // Finally, plot the lines
    stroke(204,102,0);
    if (y0 > 0) {
    if (x1 > 0)
    line(x0, y0, x1, y1);
    else if (y2 > 0)
    line(x0, y0, x2, y2);
    else
    line(x0, y0, x3, y3);
    }
    else {
    if (x1 > 0) {
      if (y2 > 0)
        line(x1, y1, x2, y2);
      else
        line(x1, y1, x3, y3);
    }
    else
      line(x2, y2, x3, y3);
    }
  }
}

List<PVector> hough(PImage edgeImg) {
  
  float discretizationStepsPhi = 0.06f;
  float discretizationStepsR = 2.5f;
  int minVotes = 100;
  // dimensions of the accumulator
  int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
  //The max radius is the image diagonal, but it can be also negative
  int rDim = (int) ((sqrt(edgeImg.width*edgeImg.width +
             edgeImg.height*edgeImg.height) * 2) / discretizationStepsR +1);
  // our accumulator
  int[] accumulator = new int[phiDim * rDim];
  // Fill the accumulator: on edge points (ie, white pixels of the edge
  // image), store all possible (r, phi) pairs describing lines going
  // through the point.
  for (int y = 0; y < edgeImg.height; y++) {
    for (int x = edgeImg.width/8; x < 7*edgeImg.width/8; x++) {
      // Are we on an edge?
      if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {
        float phi = 0f;
        for(int i=0; i<phiDim; i++, phi+=discretizationStepsPhi){
          double r = x*Math.cos(phi) + y*Math.sin(phi);
          int accPhi = Math.round(phi/discretizationStepsPhi);
          int accR =   (int)Math.round(r/ discretizationStepsR + rDim/2);
          accumulator[accR + accPhi*rDim] ++;
        }
      }
    }
  }
  int neighbourhood = 25;
  
  ArrayList<Integer> bestCandidates = new ArrayList<Integer>();
  for (int accR = 0; accR < rDim; accR++) {
    for (int accPhi = 0; accPhi < phiDim; accPhi++) {
      int idx = (accPhi) * (rDim) + accR;
      if (accumulator[idx] > minVotes) {
        boolean max = true;
        for(int dPhi=-neighbourhood/2; dPhi <= neighbourhood/2; dPhi++) {
          if( accPhi+dPhi < 0 || accPhi+dPhi >= phiDim) continue;
          for(int dR=-neighbourhood/2; dR <= neighbourhood/2; dR++) {
            if(accR+dR < 0 || accR+dR >= rDim) continue;
            int neighbourIdx = (accPhi + dPhi) * (rDim) + accR + dR ;
            if(accumulator[idx] < accumulator[neighbourIdx]) {
              max=false;
              break;
            }
          }
          if(!max) break;
        }
        if(max) {
          bestCandidates.add(accumulator[idx]);
        }
      }
    }
  }
  Collections.sort(bestCandidates, new HoughComparator(accumulator));
  
  
  ArrayList<PVector> lines=new ArrayList<PVector>();
  for (int i = 0; i < bestCandidates.size(); i++) {
    for(int idx = 0; idx < accumulator.length; idx++) {
      if((accumulator[idx] == bestCandidates.get(i))){
        // first, compute back the (r, phi) polar coordinates:
        int accPhi = (int) (idx / (rDim));
        int accR = idx - (accPhi) * (rDim);
        float r = (accR - (rDim) * 0.5f) * discretizationStepsR;
        float phi = accPhi * discretizationStepsPhi;
        lines.add(new PVector(r,phi));
      }
    }
  }
  return lines;
}

PImage gaussianBlur(PImage img){
  float[][] kernel = { { 9, 12, 9 },
                     { 12, 15, 12 },
                     { 9, 12, 9 } };
  float normFactor = 99f;
  PImage img2 = convolute(img, kernel, normFactor);
  return img2;
}

PImage scharr(PImage img) {
  float[][] vKernel = {
  { 3, 0, -3 },
  { 10, 0, -10 },
  { 3, 0, -3 } };
  float[][] hKernel = {
  { 3, 10, 3 },
  { 0, 0, 0 },
  { -3, -10, -3 } };
  PImage result = createImage(img.width, img.height, ALPHA);
  // clear the image
  for (int i = 0; i < img.width * img.height; i++) {
  result.pixels[i] = color(0);
  }
  float max=0;
  float[] buffer = new float[img.width * img.height];
  // *************************************
  // Implement here the double convolution
    // kernel size N = 3
  int N = 3;
  // for each (x,y) pixel in the image:
  for(int x = 1; x< img.width-1; x++){
    for(int y=1; y< img.height-1; y++){
      //Followed instructions week 8 page 9
      float sum_h = 0;
      float sum_v = 0;
      for(int xx = x - N/2 ; xx <= x + N/2; xx++){
        for(int yy = y - N/2 ; yy <= y + N/2; yy++){
          int yKernel = 0;
          if(yy - y == -1) yKernel = 0;
          else if(yy - y ==  1) yKernel =  2;
          else yKernel = 1;
          int xKernel = 0;
          if(xx - x == -1) xKernel = 0;
          else if(xx - x ==  1) xKernel =  2;
          else xKernel = 1;
          sum_h += (brightness(img.pixels[yy * img.width + xx])
                 * hKernel[yKernel][xKernel]);
          sum_v += (brightness(img.pixels[yy * img.width + xx])
                 * vKernel[yKernel][xKernel]);
         }
      }
      float dist = sqrt(pow(sum_h,2)+pow(sum_v,2));  
      buffer[y*img.width+x] = dist;
      if(dist > max ) max = dist;
    }
  }
  
  // *************************************
  for (int y = 1; y < img.height - 1; y++) { // Skip top and bottom edges
  for (int x = 1; x < img.width - 1; x++) { // Skip left and right
  int val=(int) ((buffer[y * img.width + x] / max)*255);
  result.pixels[y * img.width + x]=color(val);
  }
  }
  return result;
}
PImage convolute(PImage img, float[][] kernel, float normFactor) {
  //ONLY WITH 3x3 KERNELS
  // create a greyscale image (type: ALPHA) for output
  PImage result = createImage(img.width, img.height, ALPHA);
  // kernel size N = 3
  int N = 3;
  // for each (x,y) pixel in the image:
  for(int x = 1; x< img.width-1; x++){
    for(int y=1; y< img.height-1; y++){
      //Followed instructions week 8 page 9
      float sum = 0;
      for(int xx = x - N/2 ; xx <= x + N/2; xx++){
        for(int yy = y - N/2 ; yy <= y + N/2; yy++){
          int yKernel = 0;
          if(yy - y == -1) yKernel = 0;
          else if(yy - y ==  1) yKernel =  2;
          else yKernel = 1;
          int xKernel = 0;
          if(xx - x == -1) xKernel = 0;
          else if(xx - x ==  1) xKernel =  2;
          else xKernel = 1;
          sum += (brightness(img.pixels[yy * img.width + xx])
                 * kernel[yKernel][xKernel]);
         }
      }
      sum /= normFactor;
      result.pixels[y * img.width + x] = color(sum);
    }
  }
  return result;
}


PImage HBSthresholding(PImage img, float minH, float maxH, float minS, float maxS, float minB, float maxB) {
  PImage result = createImage(img.width, img.height, RGB);
  for(int i = 0; i < result.width * result.height; i++)  {
    float sat = saturation(img.pixels[i]);
    float br  = brightness(img.pixels[i]);
    float hue = hue(img.pixels[i]);
    if(sat >= minS && sat <= maxS && hue >= minH && hue <= maxH && br >= minB && br <= maxB) {
      result.pixels[i] = color(255);
    }
    else{
      result.pixels[i] = color(0);
    }
  }
  return result;
}

PImage brightnessThresholdingBinary(PImage img, float minIntensity, float maxIntensity) {
  PImage result = createImage(img.width, img.height, RGB);
  for(int i = 0; i < img.width * img.height; i++) {
    float intensity = brightness(img.pixels[i]);
    if(intensity >= minIntensity && intensity <= maxIntensity) {
      //Set value to MAX (see week 8 1st graph)
      result.pixels[i] = color(255);
    }
    else {
      //Set value to 0 (see week 8 1st graph)
      result.pixels[i] = color(0);
    }
  }
  return result;
}

PImage findConnectedComponents(PImage input, boolean onlyBiggest){
  input.loadPixels();
  PImage result = createImage(input.width, input.height, RGB);
  result.loadPixels();
  
  //FIRST PASS :label the pixels and store labels' equivalences
   int [] labels = new int[input.width*input.height];
   ArrayList<TreeSet<Integer>> labelsEquivalences = new ArrayList<TreeSet<Integer>>();
   int currentLabel = 1;
    
   TreeSet<Integer> tree = new TreeSet<Integer>();
   tree.add(currentLabel);
   labelsEquivalences.add(tree);
   for(int i = 0; i < input.width*input.height; i++){
     //if the pixel is white
     if(input.pixels[i] == color(255)){
           boolean leftExists = i%input.width!=0;
           boolean aboveExists = i>=input.width;
           boolean aboveLeftExists = leftExists && aboveExists;
           boolean aboveRightExists = aboveExists && (i+1)%input.width != 0;
           boolean leftNeighbourExists = leftExists && input.pixels[i-1] == color(255);
           boolean aboveLeftNeighbourExists = aboveLeftExists && input.pixels[i-input.width-1] == color(255);
           boolean aboveNeighbourExists = aboveExists && input.pixels[i-input.width] == color(255);    
           boolean aboveRightNeighbourExists = aboveRightExists && input.pixels[i-input.width+1] == color(255);
       if(leftNeighbourExists || aboveLeftNeighbourExists ||
          aboveNeighbourExists || aboveRightNeighbourExists ){
          int min = Integer.MAX_VALUE;
          if(leftNeighbourExists) min = min(min,labels[i-1]);
          if(aboveLeftNeighbourExists) min = min(min,labels[i-input.width-1]);
          if(aboveNeighbourExists) min = min(min,labels[i-input.width]);
          if(aboveRightNeighbourExists) min = min(min,labels[i-input.width+1]);
          labels[i] = min;
          if(leftNeighbourExists){
            labelsEquivalences.get(labels[i-1]-1).add(min);
          }
          if(aboveLeftNeighbourExists){
            labelsEquivalences.get(labels[i-input.width-1]-1).add(min);
          }
          if(aboveNeighbourExists){
            labelsEquivalences.get(labels[i-input.width]-1).add(min);
          }
          if(aboveRightNeighbourExists){
            labelsEquivalences.get(labels[i-input.width+1]-1).add(min);
          }
          
       }else{
         //NO NEIGHBOUR
          labels[i] = currentLabel;
          labelsEquivalences.add(new TreeSet<Integer>());
          labelsEquivalences.get(currentLabel-1).add(currentLabel);
          currentLabel++;
       }
     }
    }
    
   //SECOND PASS:
   int[] numberOfPixelsPerLabels = new int[currentLabel-1];
   for(int i=0 ; i<currentLabel-1 ; i++){
     numberOfPixelsPerLabels[i] = 0;
   }
   for(int i = 0; i < input.width*input.height; i++){
     if(input.pixels[i] == color(255)){
       labels[i] = labelsEquivalences.get(labels[i]-1).first();
       if(onlyBiggest == true){
         numberOfPixelsPerLabels[labels[i]-1]++;
       }
     }
   }
   
   //FINALLY:
   if(!onlyBiggest){
     for(int i=0; i<input.width*input.height; i++){
       if(labels[i]==0){
         result.pixels[i] = input.pixels[i];
       }else{
         result.pixels[i] = color(0,255,0); 
       }
     }
   }else{
     int max = 0;
     int maxLabel = 0;
     for(int i=0; i<numberOfPixelsPerLabels.length; i++){
       if(numberOfPixelsPerLabels[i]>max){
         max = numberOfPixelsPerLabels[i];
         maxLabel = i+1;
       }
     }
     for(int i=0; i<input.width*input.height; i++){
       if(labels[i] == maxLabel){
         result.pixels[i] = color(0,255,0);
       }else{
         result.pixels[i] = color(0,0,0); 
       }
     }
   }
   return result;
}

}
