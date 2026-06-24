class_name ConquestCatalog
extends RefCounted

const FALLBACK_SCENARIO := "01_sedan_1940"

# Each region maps to a battlefield whose terrain fits its theatre. Non-European
# theatres use the dedicated conq_* maps; European/Eastern regions keep their
# historical maps. Intra-theatre reuse (e.g. both desert regions) is intentional.
const REGION_SCENARIOS := {
	"north_america": "west_08_normandy_cobra_1944",
	"atlantic": "conq_mediterranean_coast",
	"britain": "blitz_02_dunkirk_1940",
	"west_europe": "01_sedan_1940",
	"germany": "west_10_remagen_1945",
	"north_sea": "conq_mediterranean_coast",
	"east_europe": "02_kiev_1941",
	"moscow": "blitz_03_moscow_1941",
	"siberia": "07_bagration_1944",
	"north_africa": "conq_desert_north_africa",
	"mediterranean": "conq_mediterranean_coast",
	"middle_east": "conq_desert_north_africa",
	"central_asia": "04_kursk_1943",
	"india": "conq_cbi_jungle",
	"china": "conq_cbi_jungle",
	"manchuria": "east_09_seelow_1945",
	"japan_home": "conq_pacific_island",
	"southeast_asia": "conq_pacific_island",
	"pacific": "conq_pacific_island",
}

const COUNTRY_SIDE := {
	"germany": "axis",
	"soviet": "soviet",
	"britain": "allies",
	"usa": "allies",
	"china": "soviet",
	"japan": "axis",
}
