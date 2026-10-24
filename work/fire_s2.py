"""Planet substitute: Sentinel-2 view of the largest FIRMS fire cluster (no Planet account)."""
import json
import urllib.request

import ee

import ee_init

ee_init.init()
gj = json.load(open("work/output/2026-10-20_largest_fire_cluster.geojson"))
geom = ee.Geometry(gj["features"][0]["geometry"]).buffer(3000).bounds()
s2 = (ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED").filterBounds(geom)
      .filterDate("2026-10-10", "2026-10-24").sort("CLOUDY_PIXEL_PERCENTAGE"))
img = s2.first()
print("scene", img.get("system:index").getInfo(), "cloud%", img.get("CLOUDY_PIXEL_PERCENTAGE").getInfo())
for name, bands, mx in [("true", ["B4", "B3", "B2"], 3000), ("swir", ["B12", "B8A", "B4"], 4000)]:
    url = img.visualize(bands=bands, min=0, max=mx).getThumbURL({"region": geom, "dimensions": 1024, "format": "png"})
    urllib.request.urlretrieve(url, f"work/output/fire_s2_{name}.png")
    print("saved", name)
