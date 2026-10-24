# Data we can use without a Stanford email (from the workshop README, 23.10)

Works now, no sign-up:
- Earth Engine catalog via our project `superagentduper`: https://developers.google.com/earth-engine/datasets/
- Awesome GEE Community Catalog: https://gee-community-catalog.org/ (ready to use in EE, lots of hydrology)
- Planet disaster data on Source Cooperative, COGs stream without an API key: https://source.coop/planet/disasterdata
  (STAC per event, GeoParquet scene index; post-event PlanetScope is TOA radiance, don't difference with SR)
- Vantor (ex-Maxar) Open Data on AWS, pre/post disaster, CC BY-NC: https://registry.opendata.aws/vantor-open-data/
- SkySat Public Ortho in EE (2 m multispectral, older): SKYSAT/GEN-A/PUBLIC/ORTHO/MULTISPECTRAL
- AirNow API (key by email sign-up, instant): https://docs.airnowapi.org/
- EarthWorks: https://earthworks.stanford.edu/ · NatCap Data Hub: https://data.naturalcapitalproject.stanford.edu/
- Global Forest Watch: https://www.globalforestwatch.org/ · Climate Tech Atlas: https://climatetechatlas.com/

Embeddings:
- AlphaEarth satellite embeddings in EE (annual 64-d per 10 m pixel), demo:
  https://earthengine-ai.projects.earthengine.app/view/embedding-similarity-search
- OlmoEarth v1.3 (Ai2), open weights, annual 2023-2025: https://allenai.org/blog/olmoearth-v1-3

Needs approval we don't have: PlanetScope daily 3-4 m (Planet E&R, non-Stanford EDU only).
PlanetScope has no SWIR anyway, so burn indices need Sentinel-2/Landsat.

Challenge ideas doc: https://docs.google.com/document/d/1S0Gf53WAzhJuWFr0-btQwcp1esXx82fkO_XfshvrrfM/edit
