// Authors: Cameron Aubert & Carter Currin
// Course: CPSC 465


import tomc.gpx.*;
import processing.core.PApplet;
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.providers.MapBox;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import java.util.List;
import java.text.DateFormat;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;

Location gonzagaLocation = new Location(47.665442f, -117.405627f);
Location centerpoint = new Location(47.675003, -117.331115);

UnfoldingMap map;

GPX gpx;

List<Location> locations;
List<ElevationLocation> elevations;
List<SpeedTime> speedTimes;
List<UnfoldingMap> maps;

//Unit conversion constants
double METER_TO_CENTIMETER = 100;
double FOOT_TO_CENTIMETER = 30.48;
double MILE_TO_FOOT = 5280;
double MILE_TO_METER = MILE_TO_FOOT * FOOT_TO_CENTIMETER / METER_TO_CENTIMETER;
double METER_PER_SECOND_TO_MILE_PER_HOUR = (1.0 / MILE_TO_METER) * 60 * 60;

//Graph coordinate constants
int VERTICAL_PADDING = 24;
int HORTIZONTAL_PADDING = 48;
int TOP_BORDER_ELEVATION, BOTTOM_BORDER_ELEVATION, TOP_BORDER_SPEED, BOTTOM_BORDER_SPEED, LEFT_BORDER, RIGHT_BORDER;

//Data variables
Date minDate, maxDate, midDate, selectedDateTime;
double minElevation, maxElevation, midElevation, elevationDelta, dateDelta, minSpeed, maxSpeed, midSpeed, speedDelta;

//Interactive
double selectedPercentile;
boolean elevationSelected, speedSelected, drawIndex;
float selectedElevation, selectedSpeed;
int selectedMapIndex, previousHeight, previousWidth;

// sets up the sketch
void setup() {
  size(800, 800, OPENGL);
  frame.setResizable(true);
  smooth();
  updateLayoutVariables();

  selectedPercentile = 0;
  elevationSelected = false;
  speedSelected = false;
  selectedElevation = 0;
  selectedSpeed = 0;
  selectedMapIndex = 0;
  previousHeight = height;
  previousWidth = width;

  maps = new ArrayList<UnfoldingMap>();
  maps.add(new UnfoldingMap(this, "map0", 0, 0, width, height, true, false, new Google.GoogleTerrainProvider()));
  maps.add(new UnfoldingMap(this, "map1", 0, 0, width, height, true, false, new Microsoft.AerialProvider()));
  map = maps.get(selectedMapIndex);
  for(UnfoldingMap m : maps) {
    m.zoomToLevel(12);
    m.panTo(centerpoint);
    MapUtils.createDefaultEventDispatcher(this, m);
  }

  gpx = new GPX(this);

  //gpx.parse("data/activity_1130367568.gpx"); // ride to Cheney
  gpx.parse("data/activity_1120979638.gpx"); // "Simon Says" ride

  locations = new ArrayList<Location>();
  elevations = new ArrayList<ElevationLocation>();

  for (int i = 0; i < gpx.getTrackCount (); i++) {
    GPXTrack trk = gpx.getTrack(i);
    // do something with trk.name
    for (int j = 0; j < trk.size (); j++) {
      GPXTrackSeg trkseg = trk.getTrackSeg(j);
      for (int k = 0; k < trkseg.size (); k++) {
        GPXPoint pt = trkseg.getPoint(k);
        ElevationLocation el = new ElevationLocation((float)pt.lat, (float)pt.lon, (float)pt.ele, pt.time);
        locations.add(el);
        elevations.add(el);
      }
    }
  }
  //Create a list of speeds between all the measured points
  speedTimes = new ArrayList<SpeedTime>();
  for (int i = 1; i < elevations.size (); i++) {
    speedTimes.add(new SpeedTime(elevations.get(i - 1), elevations.get(i)));
  }
  setupDataVariables();
  println("Traveled a total of " + DistanceAccum.totalDistance + " meters");
  println("                 or " + DistanceAccum.totalDistance / MILE_TO_METER + " miles");

  List<Marker> routeMarkers = new ArrayList<Marker>();
  GradientLinesMarker glm = new GradientLinesMarker(elevations);
  glm.setColor(color(255, 0, 0));
  glm.setStrokeWeight(3);
  routeMarkers.add(glm);

  for(UnfoldingMap m : maps) {
    m.addMarkers(routeMarkers);
  }
}


// redraws the sketch
void draw() {
  doWindowSizeCheck();
  locateMouse();
  background(255);
  map.draw();
  drawGraphs();
  if (mouseY > height / 2 && mouseX > LEFT_BORDER && mouseX < RIGHT_BORDER) {
    stroke(0, 0, 0, 128);
    line(mouseX, TOP_BORDER_ELEVATION, mouseX, BOTTOM_BORDER_ELEVATION);
    line(mouseX, TOP_BORDER_SPEED, mouseX, BOTTOM_BORDER_SPEED);
    drawSelected();
  }
}

// handles logic related ot mouse location
void locateMouse() {
  elevationSelected = mouseY > TOP_BORDER_ELEVATION - VERTICAL_PADDING && mouseY < BOTTOM_BORDER_ELEVATION + VERTICAL_PADDING;
  speedSelected = mouseY > TOP_BORDER_SPEED - VERTICAL_PADDING && mouseY < BOTTOM_BORDER_SPEED + VERTICAL_PADDING;
  selectedPercentile = (mouseX - LEFT_BORDER) / (double)(RIGHT_BORDER - LEFT_BORDER);
  drawIndex = mouseY > TOP_BORDER_ELEVATION - VERTICAL_PADDING;

  long minDateTime = minDate.getTime();
  long maxDateTime = maxDate.getTime();
  selectedDateTime = new Date((long)(minDateTime * (1.0 - selectedPercentile) + maxDateTime * selectedPercentile));
}

// draws graphs
void drawGraphs() {
  noStroke();
  fill(245, 200);
  rect(0, (height/5)*3, width, (height/5)*3);
  drawElevationGraph();
  drawSpeedGraph();
  drawLabels();
}

// draws the elevation graph
void drawElevationGraph() {
  drawElevationGraphBorders();
  drawElevationGraphLine();
}

// draws the speed graph
void drawSpeedGraph() {
  drawSpeedGraphBorders();
  drawSpeedGraphLine();
}

// draws graph lables
void drawLabels() {
  drawElevationYAxisLabels();
  drawSpeedYAxisLabels();
  drawTimeXAxisLabels();
}

//Draws borders for elevation graph
void drawElevationGraphBorders() {
  noFill();
  stroke(100);
  strokeWeight(2);
  beginShape();
  vertex(LEFT_BORDER, TOP_BORDER_ELEVATION);
  vertex(LEFT_BORDER, BOTTOM_BORDER_ELEVATION);
  vertex(RIGHT_BORDER, BOTTOM_BORDER_ELEVATION);
  vertex(RIGHT_BORDER, TOP_BORDER_ELEVATION);
  endShape(CLOSE);
}

//Draws elevation line
void drawElevationGraphLine() {
  stroke(255, 0, 0);
  strokeWeight(1.5);
  beginShape();
  for (ElevationLocation elevation : elevations) {
    int xPos = (int)lerp(LEFT_BORDER, RIGHT_BORDER, (float)((elevation.time.getTime() - minDate.getTime()) / dateDelta));
    int yPos = (int)lerp(BOTTOM_BORDER_ELEVATION, TOP_BORDER_ELEVATION, (float)((elevation.ele - minElevation) / elevationDelta));
    vertex(xPos, yPos);
  }
  endShape();
}

//Draws borders for speed graph
void drawSpeedGraphBorders() {
  noFill();
  stroke(100);
  strokeWeight(2);
  beginShape();
  vertex(LEFT_BORDER, TOP_BORDER_SPEED);
  vertex(LEFT_BORDER, BOTTOM_BORDER_SPEED);
  vertex(RIGHT_BORDER, BOTTOM_BORDER_SPEED);
  vertex(RIGHT_BORDER, TOP_BORDER_SPEED);
  endShape(CLOSE);
}

//Draws speed line
void drawSpeedGraphLine() {
  stroke(255, 0, 0);
  strokeWeight(1.5);
  beginShape();
  for (SpeedTime speedTime : speedTimes) {
    int xPos = (int)lerp(LEFT_BORDER, RIGHT_BORDER, (float)((speedTime.time.getTime() - minDate.getTime()) / dateDelta));
    int yPos = (int)lerp(BOTTOM_BORDER_SPEED, TOP_BORDER_SPEED, (float)((speedTime.speed - minSpeed) / speedDelta));
    vertex(xPos, yPos);
    //print("(" + xPos + ", " + yPos + ")");
  }
  endShape();
}

//Draws elevation y axis labels
void drawElevationYAxisLabels() {
  textSize(12);
  fill(0);
  textAlign(CENTER, TOP);
  text(String.format("%.2f", maxElevation), HORTIZONTAL_PADDING / 2, TOP_BORDER_ELEVATION);
  text(String.format("%.2f", maxElevation), width - HORTIZONTAL_PADDING / 2, TOP_BORDER_ELEVATION);
  textAlign(CENTER, CENTER);
  text(String.format("%.2f", midElevation), HORTIZONTAL_PADDING / 2, TOP_BORDER_ELEVATION + (BOTTOM_BORDER_ELEVATION - TOP_BORDER_ELEVATION) / 2);
  text(String.format("%.2f", midElevation), width - HORTIZONTAL_PADDING / 2, TOP_BORDER_ELEVATION + (BOTTOM_BORDER_ELEVATION - TOP_BORDER_ELEVATION) / 2);
  textAlign(CENTER, BOTTOM);
  text(String.format("%.2f", minElevation), HORTIZONTAL_PADDING / 2, BOTTOM_BORDER_ELEVATION);
  text(String.format("%.2f", minElevation), width - HORTIZONTAL_PADDING / 2, BOTTOM_BORDER_ELEVATION);
  text("Meters", HORTIZONTAL_PADDING / 2, TOP_BORDER_ELEVATION);
  text("Meters", width - HORTIZONTAL_PADDING / 2, TOP_BORDER_ELEVATION);
  //Graph Title
  textSize(22);
  textAlign(CENTER, CENTER);
  text("Elevation", width / 2, TOP_BORDER_ELEVATION - 2 * VERTICAL_PADDING / 3);
}

//Draws speed y axis labels
void drawSpeedYAxisLabels() {
  textSize(12);
  fill(0);
  textAlign(CENTER, TOP);
  text(String.format("%.2f", maxSpeed), HORTIZONTAL_PADDING / 2, TOP_BORDER_SPEED);
  text(String.format("%.2f", maxSpeed * METER_PER_SECOND_TO_MILE_PER_HOUR), width - HORTIZONTAL_PADDING / 2, TOP_BORDER_SPEED);
  textAlign(CENTER, CENTER);
  text(String.format("%.2f", midSpeed), HORTIZONTAL_PADDING / 2, TOP_BORDER_SPEED + (BOTTOM_BORDER_SPEED - TOP_BORDER_SPEED) / 2);
  text(String.format("%.2f", midSpeed * METER_PER_SECOND_TO_MILE_PER_HOUR), width - HORTIZONTAL_PADDING / 2, TOP_BORDER_SPEED + (BOTTOM_BORDER_SPEED - TOP_BORDER_SPEED) / 2);
  textAlign(CENTER, BOTTOM);
  text(String.format("%.2f", minSpeed), HORTIZONTAL_PADDING / 2, BOTTOM_BORDER_SPEED);
  text(String.format("%.2f", minSpeed * METER_PER_SECOND_TO_MILE_PER_HOUR), width - HORTIZONTAL_PADDING / 2, BOTTOM_BORDER_SPEED);
  text("m/s", HORTIZONTAL_PADDING / 2, TOP_BORDER_SPEED);
  text("mph", width - HORTIZONTAL_PADDING / 2, TOP_BORDER_SPEED);
  //Graph Title
  textSize(22);
  textAlign(CENTER, CENTER);
  text("Speed", width / 2, TOP_BORDER_SPEED - 2 * VERTICAL_PADDING / 3);
}

//Draws date-time x axis labels
void drawTimeXAxisLabels() {
  textSize(12);
  fill(0);
  textAlign(LEFT, CENTER);
  text(DateFormat.getDateInstance().format(minDate), LEFT_BORDER, BOTTOM_BORDER_ELEVATION + VERTICAL_PADDING / 4);
  text(DateFormat.getTimeInstance().format(minDate), LEFT_BORDER, BOTTOM_BORDER_ELEVATION + 3 * VERTICAL_PADDING / 4);
  textAlign(CENTER, CENTER);
  text(DateFormat.getDateInstance().format(midDate), LEFT_BORDER + (RIGHT_BORDER - LEFT_BORDER) / 2, BOTTOM_BORDER_ELEVATION + VERTICAL_PADDING / 4);
  text(DateFormat.getTimeInstance().format(midDate), LEFT_BORDER + (RIGHT_BORDER - LEFT_BORDER) / 2, BOTTOM_BORDER_ELEVATION + 3 * VERTICAL_PADDING / 4);
  textAlign(RIGHT, CENTER);
  text(DateFormat.getDateInstance().format(maxDate), RIGHT_BORDER, BOTTOM_BORDER_ELEVATION + VERTICAL_PADDING / 4);
  text(DateFormat.getTimeInstance().format(maxDate), RIGHT_BORDER, BOTTOM_BORDER_ELEVATION + 3 * VERTICAL_PADDING / 4);
}

// prints information about the position currently being hovered over
void drawSelected() {
  textSize(12);
  fill(0);
  textAlign(LEFT, BOTTOM);
  text(selectedDateTime.toString() + "     Elevation: " +selectedElevation+ " meters,     Speed: " +nf(selectedSpeed,2,1)+ " m/s,  " +nf(selectedSpeed*(float)METER_PER_SECOND_TO_MILE_PER_HOUR,2,1)+ " mph", 0, height);
}

void setupDataVariables() {
  //Setup mins and maxes for the elevation and times
  //used for x axis of both speed and elevation graphs
  //used for y axis of elevation graph
  minDate = new Date(Long.MAX_VALUE);
  maxDate = new Date(0);
  minElevation = Double.MAX_VALUE;
  maxElevation = Double.MIN_VALUE;
  for (ElevationLocation elevation : elevations) {
    if (elevation.ele > maxElevation)
      maxElevation = elevation.ele;
    if (elevation.ele < minElevation)
      minElevation = elevation.ele;
    if (elevation.time.after(maxDate))
      maxDate = elevation.time;
    if (elevation.time.before(minDate))
      minDate = elevation.time;
  }
  elevationDelta = maxElevation - minElevation;
  midElevation = minElevation + (maxElevation - minElevation) / 2.0;
  dateDelta = maxDate.getTime() - minDate.getTime();
  midDate = new Date(minDate.getTime() + (maxDate.getTime() - minDate.getTime()) / 2);

  //Setup mins and maxes for the speed
  //used for y axis of speed graph
  minSpeed = Double.MAX_VALUE;
  maxSpeed = Double.MIN_VALUE;
  for (SpeedTime speedTime : speedTimes) {
    //meters / s
    double currentSpeed = speedTime.speed;
    if (currentSpeed > maxSpeed)
      maxSpeed = currentSpeed;
    if (currentSpeed < minSpeed)
      minSpeed = currentSpeed;
  }
  speedDelta = maxSpeed - minSpeed;
  midSpeed = minSpeed + (maxSpeed - minSpeed) / 2.0;
}

// updates chart layout variables
void updateLayoutVariables() {
  previousHeight = height;
  previousWidth = width;
  TOP_BORDER_ELEVATION = (height/5)*3 + VERTICAL_PADDING; 
  BOTTOM_BORDER_ELEVATION = (height/5)*4 - VERTICAL_PADDING;
  TOP_BORDER_SPEED = (height/5)*4 + VERTICAL_PADDING;
  BOTTOM_BORDER_SPEED = height - VERTICAL_PADDING;
  LEFT_BORDER = HORTIZONTAL_PADDING;
  RIGHT_BORDER = width - HORTIZONTAL_PADDING;
}

// updates the map size
void updateMapSize() {
  for(UnfoldingMap m : maps) {
    m.mapDisplay.resize(width, height);
  }
}

// switches the map being displayed
void switchMap() {
  selectedMapIndex = (selectedMapIndex + 1) % maps.size();
  map = maps.get(selectedMapIndex);
}

// checks the window size
void doWindowSizeCheck() {
  if(previousWidth != width || previousHeight != height) {
    updateLayoutVariables();
    updateMapSize();
  }
}

// handles keys being pressed
void keyPressed() {
  switchMap();
}




