class_name ConquestCatalog
extends RefCounted

const FALLBACK_SCENARIO := "01_sedan_1940"

# Each region maps to a battlefield whose terrain fits its theatre. Non-European
# theatres use dedicated conq_* maps — one per region, so no two regions share a
# battlefield; European/Eastern regions keep their historical maps.
const REGION_SCENARIOS := {
	"north_america": "west_08_normandy_cobra_1944",
	"atlantic": "conq_atlantic_convoy",
	"britain": "blitz_02_dunkirk_1940",
	"west_europe": "01_sedan_1940",
	"germany": "west_10_remagen_1945",
	"north_sea": "conq_north_sea_raid",
	"east_europe": "02_kiev_1941",
	"moscow": "blitz_03_moscow_1941",
	"siberia": "07_bagration_1944",
	"north_africa": "conq_desert_north_africa",
	"mediterranean": "conq_mediterranean_coast",
	"middle_east": "conq_middle_east_oilfields",
	"central_asia": "04_kursk_1943",
	"india": "conq_cbi_jungle",
	"china": "conq_china_plains",
	"manchuria": "east_09_seelow_1945",
	"japan_home": "conq_home_islands",
	"southeast_asia": "conq_pacific_island",
	"pacific": "conq_pacific_carrier",
}

const COUNTRY_SIDE := {
	"germany": "axis",
	"soviet": "soviet",
	"britain": "allies",
	"usa": "allies",
	"china": "soviet",
	"japan": "axis",
}
