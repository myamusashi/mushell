pragma Singleton

import Quickshell
import QtQuick

Singleton {
	id: root

	// Thx caelestia
	readonly property var weatherIcons: ({
			"113": "clear_day",
			"116": "partly_cloudy_day",
			"119": "cloud",
			"122": "cloud",
			"143": "foggy",
			"176": "rainy",
			"179": "rainy",
			"182": "rainy",
			"185": "rainy",
			"200": "thunderstorm",
			"227": "cloudy_snowing",
			"230": "snowing_heavy",
			"248": "foggy",
			"260": "foggy",
			"263": "rainy",
			"266": "rainy",
			"281": "rainy",
			"284": "rainy",
			"293": "rainy",
			"296": "rainy",
			"299": "rainy",
			"302": "weather_hail",
			"305": "rainy",
			"308": "weather_hail",
			"311": "rainy",
			"314": "rainy",
			"317": "rainy",
			"320": "cloudy_snowing",
			"323": "cloudy_snowing",
			"326": "cloudy_snowing",
			"329": "snowing_heavy",
			"332": "snowing_heavy",
			"335": "snowing",
			"338": "snowing_heavy",
			"350": "rainy",
			"353": "rainy",
			"356": "rainy",
			"359": "weather_hail",
			"362": "rainy",
			"365": "rainy",
			"368": "cloudy_snowing",
			"371": "snowing",
			"374": "rainy",
			"377": "rainy",
			"386": "thunderstorm",
			"389": "thunderstorm",
			"392": "thunderstorm",
			"395": "snowing"
		})

	function getWeatherIcon(code) {
		if (code && weatherIcons.hasOwnProperty(code.toString()))
			return weatherIcons[code.toString()];
		return "air";
	}

	readonly property string weatherConditionData: cc?.weatherDesc[0].value ?? ""
	readonly property string weatherDescriptionData: cc?.weatherDesc[0].value ?? ""
	readonly property string weatherIconData: getWeatherIcon(cc?.weatherCode)
	readonly property string cityData: city ?? ""
	readonly property int tempData: cc?.temp_C ?? 0
	readonly property int tempMinData: forecast && forecast.length > 0 ? forecast[0].mintempC : 0
	readonly property int tempMaxData: forecast && forecast.length > 0 ? forecast[0].maxtempC : 0
	readonly property int humidityData: cc?.humidity ?? 0
	readonly property int windSpeedData: cc?.windspeedKmph ?? 0

	property string city: "Tangerang"
	property var cc: null
	property var forecast: null

	Component.onCompleted: {
		reload();
	}

	function sendRequest(url, callback) {
		let request = new XMLHttpRequest();
		request.onreadystatechange = function () {
			if (request.readyState === XMLHttpRequest.DONE) {
				let response = {
					status: request.status,
					headers: request.getAllResponseHeaders(),
					contentType: request.responseType,
					content: request.response
				};
				callback(response);
			}
		};
		request.open("GET", url);
		request.send();
	}

	function reload() {
		if (!city)
			return;

		const url = `https://wttr.in/${city}?format=j1`;

		sendRequest(url, function (response) {
			if (response.status === 200) {
				try {
					const json = JSON.parse(response.content);
					cc = json.current_condition[0];
					forecast = json.weather;
				} catch (e) {
					console.error("Failed to parse weather JSON:", e);
				}
			} else {
				console.error("Weather request failed with status:", response.status);
			}
		});
	}

	Timer {
		interval: 1800000
		running: true
		repeat: true
		onTriggered: root.reload()
	}
}
