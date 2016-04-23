
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

void setup() {
    size(800, 600, OPENGL);
    smooth();
    
    map = new UnfoldingMap(this, new Google.GoogleTerrainProvider()); 
    map.zoomToLevel(11);
    map.panTo(gonzagaLocation);
    //map.setZoomRange(9, 17); // prevent zooming too far out
    //map.setPanningRestriction(bostonLocation, 50);
    MapUtils.createDefaultEventDispatcher(this, map);

    gpx = new GPX(this);
  
    gpx.parse("activity_1130367568.gpx");
    
    List<Location> locations = new ArrayList<Location>();
    
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
    map.draw();
}

