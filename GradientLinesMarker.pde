import java.util.HashMap;
import java.util.List;

import processing.core.PConstants;
import processing.core.PGraphics;
import de.fhpotsdam.unfolding.geo.Location;
import de.fhpotsdam.unfolding.utils.MapPosition;

/**
 * Marker representing multiple locations as lines. Use directly to display as simple lines, or extend it for custom styles.
 * 
 * This can be a polyline consisting of multiple locations, or a single line consisting of two locations.
 */
public class GradientLinesMarker extends SimpleLinesMarker {
    
    protected List<Float> elevations;
    protected float maxElevation = MIN_FLOAT;
    protected float minElevation = MAX_FLOAT;
    
    protected List<SpeedTime> speedTimes;
    protected float maxSpeed = MIN_FLOAT;

  public GradientLinesMarker() {
    super();
  }

  /**
   * Creates a polyline marker.
   * 
   * @param locations
   *            The locations to connect via lines.
   */
    public GradientLinesMarker(List<ElevationLocation> locations) {
        elevations = new ArrayList<Float>();
        speedTimes = new ArrayList<SpeedTime>();
        ElevationLocation priorLocation = locations.get(0);
        
        for (ElevationLocation location : locations) {
            this.addLocation(location.getLat(), location.getLon());
            
            float elevation = location.getElevation();
            elevations.add(elevation);
            if (elevation < minElevation) minElevation = elevation;
            if (elevation > maxElevation) maxElevation = elevation;
            
            SpeedTime st = new SpeedTime(priorLocation, location);
            speedTimes.add(st);
            if (st.speed > maxSpeed) maxSpeed = st.speed;
            priorLocation = location;
        }
    }

  /**
   * Creates a polyline marker with additional properties.
   * 
   * @param locations
   *            The locations to connect via lines.
   * @param properties
   *            Optional data properties.
   */
  public GradientLinesMarker(List<Location> locations, HashMap<String, Object> properties) {
    super(locations, properties);
  }

  /**
   * Creates a marker for a single line, with a connection from start to end location. This convenience method adds the given
   * start and end locations to the list.
   * 
   * @param startLocation
   *            The location of the start of this line.
   * @param endLocation
   *            The location of the end of this line.
   */
    public GradientLinesMarker(Location startLocation, Location endLocation) {
        addLocations(startLocation, endLocation);
    }

    @Override
    public void draw(PGraphics pg, List<MapPosition> mapPositions) {
        if (mapPositions.isEmpty() || isHidden())
            return;

        pg.pushStyle();
        pg.noFill();
        pg.strokeWeight(strokeWeight);
        pg.smooth();

        LABColor minColor = new LABColor(color(0,0,200));
        LABColor maxColor = new LABColor(color(220,0,0));
        
        boolean indexMarked = false;
        float indexX = 0;
        float indexY = 0;

        pg.beginShape(PConstants.LINES);
        MapPosition last = mapPositions.get(0);
        for (int i = 1; i < mapPositions.size (); ++i) {
            if (elevationSelected) {
                pg.stroke(minColor.lerp(maxColor, (elevations.get(i)-minElevation)/(maxElevation-minElevation)).rgb);
            } else if (speedSelected) {
                pg.stroke(minColor.lerp(maxColor, speedTimes.get(i).speed/maxSpeed).rgb);
            } else {
                pg.stroke(color(255,0,0));
            }
            MapPosition mp = mapPositions.get(i);
            pg.vertex(last.x, last.y);
            pg.vertex(mp.x, mp.y);
            last = mp;
            
            if (!indexMarked && selectedDateTime.before(speedTimes.get(i).time)) {
                indexX = mp.x;
                indexY = mp.y;
                indexMarked = true;
            }
        }
        pg.endShape();
        if (indexMarked && drawIndex) {
            pg.stroke(maxColor.rgb);
            pg.strokeWeight(5);
            pg.ellipse(indexX, indexY, 5, 5);
        }
        pg.popStyle();
    }
}

