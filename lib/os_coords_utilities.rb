# Based on http://gist.github.com/258730 and on http://www.nearby.org.uk/tests/GeoTools.html. Not yet working properly

module OsCoordsUtilities
  E2 = 0.0066705397616  # OSI eccentricity squared
  A = 6377563.396       # OSI semi-major
  B = 6356256.910       # OSI semi-minor

  extend self
  
  def convert_os_to_wgs84(eastings, northings, height=0)
    basic_lat_rad, basic_long_rad = ne_to_latlng(eastings,northings)
    x,y,z = lat_long_to_xyz(basic_lat_rad, basic_long_rad)
    x2,y2,z2 = helmert_transform(x,y,z)

    lat, long = xyz_to_lat_long(x2,y2,z2)
    [to_degrees(lat), to_degrees(long)]
  end
  

  def ne_to_latlng(east, north)
    # converts NGR easting and nothing to lat, lon.
    # input metres, output radians
    north = north.to_f
    east = east.to_f
    e0 = 400000           # easting of false origin
    n0 = -100000          # northing of false origin
    f0 = 0.9996012717     # OSI scale factor on central meridian
    lam0 = -0.034906585039886591  # OSI false east in radians
    phi0 = 0.85521133347722145    # OSI false north in radians
    af0 = A * f0
    bf0 = B * f0
    n = (af0 - bf0) / (af0 + bf0)
    et = east - e0
    phid = initial_lat(north, n0, af0, phi0, n, bf0)
    
    nu = af0 / (Math.sqrt(1 - (E2 * (Math.sin(phid) * Math.sin(phid)))))
    rho = (nu * (1 - E2)) / (1 - (E2 * (Math.sin(phid)) * (Math.sin(phid))))
    eta2 = (nu / rho) - 1
    
    tlat2 = Math.tan(phid) * Math.tan(phid)
    tlat4 = Math.tan(phid) ** 4
    tlat6 = Math.tan(phid) ** 6
    clatm1 = Math.cos(phid) ** -1
    
    # compute latitude
    vii = Math.tan(phid) / (2 * rho * nu)
    viii = (Math.tan(phid) / (24 * rho * (nu ** 3))) * (5 + (3 * tlat2) + eta2 - (9 * eta2 * tlat2))
    ix = ((Math.tan(phid)) / (720 * rho * (nu ** 5))) * (61 + (90 * tlat2) + (45 * (Math.tan(phid) ** 4) ))
    
    en_to_lat_rad = (phid - ((et * et) * vii) + ((et ** 4) * viii) - ((et ** 6) * ix))
    
    # compute longitude
    x = (Math.cos(phid) ** -1) / nu
    xi = (clatm1 / (6 * (nu * nu * nu))) * ((nu / rho) + (2 * (tlat2)))
    xii = (clatm1 / (120 * (nu ** 5))) * (5 + (28 * tlat2) + (24 * tlat4))
    xiia = clatm1 / (5040 * (nu ** 7)) * (61 + (662 * tlat2) + (1320 * tlat4) + (720 * tlat6))
    en_to_long_rad = (lam0 + (et * x) - ((et * et * et) * xi) + ((et ** 5) * xii) - ((et ** 7) * xiia))
    [en_to_lat_rad, en_to_long_rad]
  end
  
  def lat_long_to_xyz(rad_lat, rad_long, height=0)
    # Compute eccentricity squared and nu for lat
    v = A / (Math.sqrt(1 - (E2 * (  Math.sin(rad_lat)**2))))
    # Compute X
    x = (v + height) * (Math.cos(rad_lat)) * (Math.cos(rad_long))
    y = (v + height) * (Math.cos(rad_lat)) * (Math.sin(rad_long))
    z = ((v * (1 - E2)) + height) * (Math.sin(rad_lat))
    [x,y,z]
  end
  
  def helmert_transform(x, y, z)
    dx, dy, dz = 446.448, -125.157, 542.060
    x_rot, y_rot, z_rot, s = 0.1502, 0.2470, 0.8421, -20.4894
    # (x, y, z, DX, Y_Rot, Z_Rot, s)
    # Computed Helmert transformed X coordinate.
    # Input: - 
    #    cartesian XYZ coords (x, y, z), X,Y,Z translations (dx, dy, dz) all in meters
    # X, Y and Z rotations in seconds of arc (x_rot, y_rot, z_rot) and scale in ppm (s).
    # 
    # Convert rotations to radians and ppm scale to a factor
  	sfactor = s * 0.000001
  	rad_x_rot = (x_rot / 3600) * (Math::PI / 180)
  	rad_y_rot = (y_rot / 3600) * (Math::PI / 180)
  	rad_z_rot = (z_rot / 3600) * (Math::PI / 180)

    # Compute transformed coords
    hx = x + (x * sfactor) - (y * rad_z_rot) + (z * rad_y_rot) + dx
  	hy = (x * rad_z_rot) + y + (y * sfactor) - (z * rad_x_rot) + dy;
    hz = (-1 * x * rad_y_rot) + (y * rad_x_rot) + z + (z * sfactor) + dz;
    [hx, hy, hz]
  end
  
  def xyz_to_lat_long(x, y, z)
    
    root_xy_sqr = Math.sqrt(x**2 + y**2);

    phi1 = Math.atan2(z, (root_xy_sqr * (1 - E2)) )
    lat_rad = iterate_xyz_to_lat(phi1, z, root_xy_sqr)
    long_rad = Math.atan2(y, x)
    [lat_rad, long_rad]
  end
  
  def iterate_xyz_to_lat(phi1, z, root_xy_sqr)
    v = A / (Math.sqrt(1 - (E2 * (Math.sin(phi1)**2))))
    phi2 = Math.atan2((z + (E2 * v * (Math.sin(phi1)))) , root_xy_sqr)
    i = 0 
    while ((phi1 - phi2).abs > 0.000000001)&&(i<20) do  #max 20 iterations in case of error
      i += 1
      phi1 = phi2
      v = A / (Math.sqrt(1 - (E2 * (Math.sin(phi1)*2))))
      phi2 = Math.atan2((z + (E2 * v * (Math.sin(phi1)))), root_xy_sqr)
    end
    phi2
  end
  
  def to_degrees(n)
    n / (Math::PI / 180)
  end
  
  def marc(bf0, n, phi0, phi)
    bf0 * (((1 + n + ((5 / 4) * (n**2)) + ((5 / 4) * (n**3))) * (phi - phi0)) - (((3 * n) + (3 * (n**2)) + ((21 / 8) * (n**3))) * (Math.sin(phi - phi0)) * (Math.cos(phi + phi0))) + ((((15 / 8) * (n**2)) + ((15 / 8) * (n**3))) * (Math.sin(2 * (phi - phi0))) * (Math.cos(2 * (phi + phi0)))) - (((35 / 24) * (n**3)) * (Math.sin(3 * (phi - phi0))) * (Math.cos(3 * (phi + phi0)))))
  end

  def initial_lat(north, n0, af0, phi0, n, bf0)
    phi1 = ((north - n0) / af0) + phi0
    m = marc(bf0, n, phi0, phi1)
    phi2 = ((north - n0 - m) / af0) + phi1
    i = 0
    while (((north - n0 - m).abs > 0.00001) && (i < 20)) do  #max 20 iterations in case of error
      i += 1
      phi2 = ((north - n0 - m) / af0) + phi1
      m = marc(bf0, n, phi0, phi2)
      phi1 = phi2
    end
    phi2
  end
end
