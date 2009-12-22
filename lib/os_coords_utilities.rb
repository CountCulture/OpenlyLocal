# http://gist.github.com/258730

# NB Results are not entirely accurate. Apparently prob needs Helmert Transform
module OsCoordsUtilities
  def to_degrees(n)
    n / (Math::PI / 180)
  end

  def ne_to_latlng(east, north)
    # converts NGR easting and nothing to lat, lon.
    # input metres, output radians
    nx = north.to_f
    ex = east.to_f
    a = 6377563.396       # OSI semi-major
    b = 6356256.91        # OSI semi-minor
    e0 = 400000           # easting of false origin
    n0 = -100000          # northing of false origin
    f0 = 0.9996012717     # OSI scale factor on central meridian
    e2 = 0.0066705397616  # OSI eccentricity squared
    lam0 = -0.034906585039886591  # OSI false east
    phi0 = 0.85521133347722145    # OSI false north
    af0 = a * f0
    bf0 = b * f0
    n = (af0 - bf0) / (af0 + bf0)
  #  et = east - e0
    phid = initial_lat(north, n0, af0, phi0, n, bf0)
    nu = af0 / (Math.sqrt(1 - (e2 * (Math.sin(phid) * Math.sin(phid)))))
    rho = (nu * (1 - e2)) / (1 - (e2 * (Math.sin(phid)) * (Math.sin(phid))))
    eta2 = (nu / rho) - 1
    tlat2 = Math.tan(phid) * Math.tan(phid)
    tlat4 = Math.tan(phid) ** 4
    tlat6 = Math.tan(phid) ** 6
    clatm1 = Math.cos(phid) ** -1
    vii = Math.tan(phid) / (2 * rho * nu)
    viii = (Math.tan(phid) / (24 * rho * (nu * nu * nu))) * (5 + (3 * tlat2) + eta2 - (9 * eta2 * tlat2))
    ix = ((Math.tan(phid)) / (720 * rho * (nu ** 5))) * (61 + (90 * tlat2) + (45 * (Math.tan(phid) ** 4) ))
    phip = (phid - ((et * et) * vii) + ((et ** 4) * viii) - ((et ** 6) * ix))
    x = (Math.cos(phid) ** -1) / nu
    xi = (clatm1 / (6 * (nu * nu * nu))) * ((nu / rho) + (2 * (tlat2)))
    xii = (clatm1 / (120 * (nu ** 5))) * (5 + (28 * tlat2) + (24 * tlat4))
    xiia = clatm1 / (5040 * (nu ** 7)) * (61 + (662 * tlat2) + (1320 * tlat4) + (720 * tlat6))
    lambdap = (lam0 + (et * x) - ((et * et * et) * xi) + ((et ** 5) * xii) - ((et ** 7) * xiia))
    [to_degrees(phip), to_degrees(lambdap)]
  end

  def marc(bf0, n, phi0, phi)
    bf0 * (((1 + n + ((5 / 4) * (n * n)) + ((5 / 4) * (n * n * n))) * (phi - phi0)) - (((3 * n) + (3 * (n * n)) + ((21 / 8) * (n * n * n))) * (Math.sin(phi - phi0)) * (Math.cos(phi + phi0))) + ((((15 / 8) * (n * n)) + ((15 / 8) * (n * n * n))) * (Math.sin(2 * (phi - phi0))) * (Math.cos(2 * (phi + phi0)))) - (((35 / 24) * (n * n * n)) * (Math.sin(3 * (phi - phi0))) * (Math.cos(3 * (phi + phi0)))))
  end

  def initial_lat(north, n0, af0, phi0, n, bf0)
    phi1 = ((north - n0) / af0) + phi0
    m = marc(bf0, n, phi0, phi1)
    phi2 = ((north - n0 - m) / af0) + phi1
    ind = 0
    while (((north - n0 - m).abs > 0.00001) && (ind < 20)) do  #max 20 iterations in case of error
      ind = ind + 1
      phi2 = ((north - n0 - m) / af0) + phi1
      m = marc(bf0, n, phi0, phi2)
      phi1 = phi2
    end
    return(phi2)
  end
end
