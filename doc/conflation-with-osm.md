# Conflating Stops with OpenStreetMap

Depends on the Valhalla routing engine and its [Tyr ("Take Your Route") service](https://github.com/valhalla/tyr/).

To automatically conflate stops whenever they are created or their location changed, add `TYR_AUTH_TOKEN` to `config/application.yml` and set `AUTO_CONFLATE_STOPS_WITH_OSM` to `true`.

