
import java.util.Date;

public static class DistanceAccum {
  public static double totalDistance = 0.0;
}

public class SpeedTime {
    
    //meters / s
    protected float speed;
    protected Date time;
    
    public SpeedTime(ElevationLocation loc0, ElevationLocation loc1) {
      long timePrevious, timeDelta;
      if(loc0.time.getTime() < loc1.time.getTime()) {
        timePrevious = loc0.time.getTime();
        timeDelta = (loc1.time.getTime() - timePrevious);
      }
      else {
        timePrevious = loc1.time.getTime();
        timeDelta = loc0.time.getTime() - timePrevious;
      }
      timeDelta /= 1000;//make seconds
      //long timePrevious = min(loc0.time.getTime(), loc1.time.getTime());
      //long timeDelta = abs(loc1.time.getTime() - loc0.time.getTime());
      
      //Location's x is latitude and Location's y is longitude
      final int EARTH_RADIUS = 6370000; //in meters
      float radius0 = EARTH_RADIUS + loc0.ele;
      float radius1 = EARTH_RADIUS + loc1.ele;
      float x0 = radius0 * cos(radians(loc0.x)) * sin(radians(loc0.y));
      float x1 = radius1 * cos(radians(loc1.x)) * sin(radians(loc1.y));
      float y0 = radius0 * sin(radians(loc0.x));
      float y1 = radius1 * sin(radians(loc1.x));
      float z0 = radius0 * cos(radians(loc0.x)) * cos(radians(loc0.y));
      float z1 = radius1 * cos(radians(loc1.x)) * cos(radians(loc1.y));
      float xDelta = x1 - x0;
      float yDelta = y1 - y0;
      float zDelta = z1 - z0;
      float distance = sqrt(xDelta * xDelta + yDelta * yDelta + zDelta * zDelta);
      DistanceAccum.totalDistance += distance;
      this.speed = distance / timeDelta;
      //println(timeDelta);
      this.time = new Date(timePrevious + timeDelta / 2);
    }
}
