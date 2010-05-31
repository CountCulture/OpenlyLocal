# Rewrite in Ruby of OS northings, eastings to lat/long methods in http://www.jstott.me.uk/jscoord/
module OsCoordsNewUtilities  
  OSGB_F0  = 0.9996012717
  N0       = -100000.0
  E0       = 400000.0
  
  
  extend self
  
  def convert_os_to_wgs84(eastings, northings, height=0)
    osgb36_lat, osgb36_long = ne_to_osgb36(eastings,northings)
    osgb36_to_wgs84(osgb36_lat, osgb36_long)
  end
  
  def ne_to_osgb36(easting, northing)
    airy1830 = refell(6377563.396, 6356256.909)
    phi0     = to_rad(49.0)
    lambda0  = to_rad(-2.0)
    a        = airy1830[:maj]
    b        = airy1830[:min]
    e_squared = airy1830[:ecc]
    n        = (a - b) / (a + b)
    m        = 0.0
    phi_prime = ((northing - N0) / (a * OSGB_F0)) + phi0
    while (northing - N0 - m) >= 0.001 do
      m = (b * OSGB_F0) * 
            (((1 + n + ((5.0 / 4.0) * n * n) + ((5.0 / 4.0) * n * n * n)) *
            (phi_prime - phi0)) - 
            (((3.0 * n) + (3.0 * n * n) + ((21.0 / 8.0) * n * n * n)) *
            Math.sin(phi_prime - phi0) *
            Math.cos(phi_prime + phi0)) +
            ((((15.0 / 8.0) * n * n) + ((15.0 / 8.0) * n * n * n)) * 
            Math.sin(2.0 * (phi_prime - phi0)) *
            Math.cos(2.0 * (phi_prime + phi0))) -
            (((35.0 / 24.0) * n * n * n) * 
            Math.sin(3.0 * (phi_prime - phi0)) * 
            Math.cos(3.0 * (phi_prime + phi0))))
      phi_prime += (northing - N0 - m) / (a * OSGB_F0)
    end
    v = a * OSGB_F0 * (1.0 - e_squared * Math.sin(phi_prime)**2)**-0.5
    rho =  a * OSGB_F0 * (1.0 - e_squared) * ((1.0 - e_squared * Math.sin(phi_prime)**2)**-1.5)
    eta_squared = (v / rho) - 1.0
    vii = Math.tan(phi_prime) / (2 * rho * v)
    viii = (Math.tan(phi_prime) / (24.0 * rho * (v**3))) * (5.0 + (3.0 * Math.tan(phi_prime)**2) + eta_squared -
           (9.0 * (Math.tan(phi_prime)**2) * eta_squared))
    ix = (Math.tan(phi_prime) / (720.0 * rho * (v**5))) * (61.0 + (90.0 * Math.tan(phi_prime)**2) + (45.0 * Math.tan(phi_prime)**2 * Math.tan(phi_prime)**2))
    x = sec(phi_prime) / v
    xi = (sec(phi_prime) / (6.0 * v * v * v)) * ((v / rho) + (2 * Math.tan(phi_prime)**2))
    xii = (sec(phi_prime) / (120.0 * (v**5))) * 
    (5.0 + (28.0 * Math.tan(phi_prime)**2) + (24.0 * Math.tan(phi_prime)**2 * Math.tan(phi_prime)**2))
    xiia = (sec(phi_prime) / (5040.0 * (v**7.0))) * (61.0 + 
             (662.0 * Math.tan(phi_prime)**2) + 
             (1320.0 * Math.tan(phi_prime)**2 * Math.tan(phi_prime)**2) + 
             (720.0 * Math.tan(phi_prime)**2 * Math.tan(phi_prime)**2 * Math.tan(phi_prime)**2))
    phi = phi_prime - (vii * (easting - E0)**2) + (viii * (easting - E0)**4) - (ix * (easting - E0)**6)
    lam = lambda0 + (x * (easting - E0)) - (xi * (easting - E0)**3) + 
            (xii * (easting - E0)**5) - (xiia * (easting - E0)**7)
    
    [to_degrees(phi), to_degrees(lam)]
  end
  
  def osgb36_to_wgs84(lat, long)
    airy1830 = refell(6377563.396, 6356256.909)
    a        = airy1830[:maj]
    b        = airy1830[:min]
    e_squared = airy1830[:ecc]
    phi      = to_rad(lat)
    lam      = to_rad(long)
    v = a / (Math.sqrt(1 - e_squared * Math.sin(phi)**2))
    h = 0; # height
    x = (v + h) * Math.cos(phi) * Math.cos(lam)
    y = (v + h) * Math.cos(phi) * Math.sin(lam)
    z = ((1 - e_squared) * v + h) * Math.sin(phi)
    
    tx = 446.448
    ty = -124.157
    tz = 542.060
    s  = -0.0000204894
    rx = to_rad(0.00004172222)
    ry = to_rad(0.00006861111)
    rz = to_rad(0.00023391666)
    
    xb = tx + (x * (1 + s)) + (-rx * y) + (ry * z)
    yb = ty + (rz * x) + (y * (1 + s)) + (-rx * z)
    zb = tz + (-ry * x) + (rx * y) + (z * (1 + s))
    
    wgs84 = refell(6378137.000, 6356752.3141)
    a = wgs84[:maj]
    b = wgs84[:min]
    e_squared = wgs84[:ecc]
    
    lam_b = to_degrees(Math.atan(yb / xb))
    p = Math.sqrt((xb * xb) + (yb * yb))
    phi_n = Math.atan(zb / (p * (1 - e_squared)))
    10.times do
      v = a / (Math.sqrt(1 - e_squared * Math.sin(phi_n)**2))
      phi_n1 = Math.atan((zb + (e_squared * v * Math.sin(phi_n)))/p)
      phi_n = phi_n1
    end
    phi_b = to_degrees(phi_n);
    [phi_b, lam_b]
  end
  
  def to_degrees(n)
    n * (180.0 / Math::PI)
  end
  
  def to_rad(n)
    n * (Math::PI / 180)
  end
  
  def refell(maj,min)
    ecc = ((maj * maj) - (min * min)) / (maj * maj)
    { :maj => maj, :min => min, :ecc => ecc }
  end
  
  def sec(x)
    1.0 / Math.cos(x)
  end
end
