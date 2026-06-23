class_name ConquestCatalog
extends RefCounted

const FALLBACK_SCENARIO := "01_sedan_1940"

const REGION_SCENARIOS := {
	"north_america": "west_08_normandy_cobra_1944",
	"atlantic": "west_08_falaise_1944",
	"britain": "blitz_02_dunkirk_1940",
	"west_europe": "01_sedan_1940",
	"germany": "west_10_remagen_1945",
	"north_sea": "west_08_normandy_cobra_1944",
	"east_europe": "02_kiev_1941",
	"moscow": "blitz_03_moscow_1941",
	"siberia": "07_bagration_1944",
	"north_africa": "01_sedan_1940",
	"mediterranean": "west_11_colmar_1945",
	"middle_east": "east_05_kharkov_1943",
	"central_asia": "04_kursk_1943",
	"india": "06_market_garden_1944",
	"china": "07_bagration_1944",
	"manchuria": "east_09_seelow_1945",
	"japan_home": "east_10_berlin_1945",
	"southeast_asia": "06_market_garden_1944",
	"pacific": "06_market_garden_1944",
}

const COUNTRY_SIDE := {
	"germany": "axis",
	"soviet": "soviet",
	"britain": "allies",
	"usa": "allies",
	"china": "soviet",
	"japan": "axis",
}
