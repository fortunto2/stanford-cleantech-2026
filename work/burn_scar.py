"""dNBR burn scar for the largest FIRMS cluster, Sentinel-2 (what the workshop does with PlanetScope bands)."""
import json
import urllib.request

import ee

import ee_init

ee_init.init()
gj = json.load(open("work/output/2026-10-20_largest_fire_cluster.geojson"))
aoi = ee.Geometry(gj["features"][0]["geometry"]).buffer(3000).bounds()
s2 = ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED").filterBounds(aoi).filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE", 20))


def nbr(img):
    return img.normalizedDifference(["B8", "B12"]).rename("nbr")


pre = nbr(s2.filterDate("2026-09-01", "2026-10-05").median())
post = nbr(s2.filterDate("2026-10-12", "2026-10-24").median())
dnbr = pre.subtract(post).rename("dnbr")
burned = dnbr.gt(0.27)  # USGS: moderate-low severity and above
area = burned.multiply(ee.Image.pixelArea()).reduceRegion(ee.Reducer.sum(), aoi, 20, maxPixels=1e9)
print("burned km2 (dNBR>0.27):", round(area.getInfo()["dnbr"] / 1e6, 2))
url = dnbr.visualize(min=-0.1, max=0.7, palette=["1a9850", "ffffbf", "fdae61", "d73027", "7f0000"]).getThumbURL(
    {"region": aoi, "dimensions": 1024, "format": "png"})
urllib.request.urlretrieve(url, "work/output/fire_dnbr.png")
print("saved work/output/fire_dnbr.png")
