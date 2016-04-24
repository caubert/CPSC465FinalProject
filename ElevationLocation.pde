
import java.util.Date;

public class ElevationLocation extends Location {
    
    protected float ele;
    protected Date time;
    
    public ElevationLocation(float lat, float lon, float ele, Date time) {
        super(lat, lon);
        this.ele = ele;
        this.time = time;
    }
    
    public float getElevation() {
        return ele;
    }
}
