
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

Location gonzagaLocation = new Location(47.665442f, -117.405627f);

UnfoldingMap map;

GPX gpx;

List<Location> locations;

void setup() {
    size(800, 1200, OPENGL);
    smooth();
    
    //map = new UnfoldingMap(this, new Google.GoogleTerrainProvider());
    map = new UnfoldingMap(this, "map", 0, 0, width, height / 2, true, false, new Google.GoogleTerrainProvider());
    //map = new UnfoldingMap(this, "map1", 0, 0, width, height / 2, true, false, new Microsoft.AerialProvider());
    map.zoomToLevel(11);
    map.panTo(gonzagaLocation);
    //map.setZoomRange(9, 17); // prevent zooming too far out
    //map.setPanningRestriction(bostonLocation, 50);
    MapUtils.createDefaultEventDispatcher(this, map);

    gpx = new GPX(this);
  
    gpx.parse("activity_1130367568.gpx");
    
    locations = new ArrayList<Location>();
    
    for (int i = 0; i < gpx.getTrackCount(); i++) {
        GPXTrack trk = gpx.getTrack(i);
        // do something with trk.name
        for (int j = 0; j < trk.size(); j++) {
            GPXTrackSeg trkseg = trk.getTrackSeg(j);
            for (int k = 0; k < trkseg.size(); k++) {
                GPXPoint pt = trkseg.getPoint(k);
                locations.add(new ElevationLocation((float)pt.lat, (float)pt.lon, (float)pt.ele, pt.time));
            }
        }
    }

    //List<Feature> transitLines = GeoJSONReader.loadData(this, "data/MBTARapidTransitLines.json");

    // Create marker from features, and use LINE property to color the markers.
    List<Marker> transitMarkers = new ArrayList<Marker>();
    //for (Feature feature : transitLines) {
     //   ShapeFeature lineFeature = (ShapeFeature) feature;

        //SimpleLinesMarker m = new SimpleLinesMarker(lineFeature.getLocations());
        GradientLinesMarker m = new GradientLinesMarker(locations);
        m.setColor(color(255,0,0));
        m.setStrokeWeight(3);
        transitMarkers.add(m);
    //}

    map.addMarkers(transitMarkers);
}

void draw() {
  background(255);
  map.draw();
  drawElevationGraph();
}

void drawElevationGraph() {
  final int TOP = height / 2;
  final int BOTTOM = (3 * height) / 4;
  final int LEFT = 0;
  final int RIGHT = width;
  
  List<ElevationLocation> elevations = new ArrayList<ElevationLocation>();
  for(Location loc : locations) {
    elevations.add((ElevationLocation)loc);
  }
  
  int dataCount = elevations.size();
  
  double minElevation = Double.MAX_VALUE;
  double maxElevation = Double.MIN_VALUE;
  for(ElevationLocation elevation : elevations) {
    if(elevation.ele > maxElevation)
      maxElevation = elevation.ele;
    if(elevation.ele < minElevation)
      minElevation = elevation.ele;
  }
  double elevationDelta = maxElevation - minElevation;
  int i = 0;
  stroke(255, 0, 0);
  beginShape(LINES);
  for(ElevationLocation elevation : elevations) {
    int xPos = (int)lerp(LEFT, RIGHT, i / (float)dataCount);
    int yPos = (int)lerp(BOTTOM, TOP, (float)((elevation.ele - minElevation) / elevationDelta));
    vertex(xPos, yPos);
    i++;
    print("(" + xPos + ", " + yPos + ")");
  }
  endShape();
}











