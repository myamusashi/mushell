pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils
import qs.Core.States
import qs.Core.Configs
import qs.Services

import "Weather/weatherData.js" as WD

Singleton {
    id: root

    // readonly loading states
    readonly property bool isInitialLoading: isLoading && !loaded
    readonly property bool canRefresh: !isLoading
    readonly property bool hasData: loaded
    readonly property bool isLoading: weatherLoading || aqiLoading || astronomyLoading
    readonly property bool isRefreshing: isLoading && loaded

    readonly property var weatherIcons: ({
            "0": WeatherIcon.daySunny,
            "1": WeatherIcon.dayCloudy,
            "2": WeatherIcon.dayCloudy,
            "3": WeatherIcon.cloud,
            "45": WeatherIcon.fog,
            "48": WeatherIcon.fog,
            "51": WeatherIcon.rain,
            "53": WeatherIcon.rain,
            "55": WeatherIcon.rain,
            "56": WeatherIcon.sleet,
            "57": WeatherIcon.sleet,
            "61": WeatherIcon.rain,
            "63": WeatherIcon.rain,
            "65": WeatherIcon.rain,
            "66": WeatherIcon.rainMix,
            "67": WeatherIcon.rainMix,
            "71": WeatherIcon.snow,
            "73": WeatherIcon.snow,
            "75": WeatherIcon.snow,
            "77": WeatherIcon.snow,
            "80": WeatherIcon.showers,
            "81": WeatherIcon.showers,
            "82": WeatherIcon.stormShowers,
            "85": WeatherIcon.snow,
            "86": WeatherIcon.snow,
            "95": WeatherIcon.thunderstorm,
            "96": WeatherIcon.thunderstorm,
            "99": WeatherIcon.thunderstorm
        })

    readonly property var weatherIconsNight: ({
            "0": WeatherIcon.nightClear,
            "1": WeatherIcon.nightCloudy,
            "2": WeatherIcon.nightCloudy
        })

    readonly property var weatherSchema: [
        {
            key: "latitude",
            def: 0.0
        },
        {
            key: "longitude",
            def: 0.0
        },
        {
            key: "timezone",
            def: ""
        },
        {
            key: "elevation",
            def: 0.0
        },
        {
            key: "weatherCondition",
            def: ""
        },
        {
            key: "weatherDescription",
            def: ""
        },
        {
            key: "weatherIcon",
            def: "air"
        },
        {
            key: "weatherCode",
            def: 0
        },
        {
            key: "isDay",
            def: true
        },
        {
            key: "temperature",
            def: 0
        },
        {
            key: "temperatureMin",
            def: 0
        },
        {
            key: "temperatureMax",
            def: 0
        },
        {
            key: "feelsLike",
            def: 0
        },
        {
            key: "humidity",
            def: 0
        },
        {
            key: "dewPoint",
            def: 0.0
        },
        {
            key: "windSpeed",
            def: 0
        },
        {
            key: "windDirection",
            def: ""
        },
        {
            key: "windDirectionDegrees",
            def: 0
        },
        {
            key: "uvIndex",
            def: 0
        },
        {
            key: "pressure",
            def: 0
        },
        {
            key: "visibility",
            def: 0.0
        },
        {
            key: "cloudCover",
            def: 0
        },
        {
            key: "precipitation",
            def: 0.0
        },
        {
            key: "precipitationDaily",
            def: 0.0
        },
        {
            key: "hourlyForecast",
            def: []
        },
        {
            key: "dailyForecast",
            def: []
        },
        {
            key: "europeanAQI",
            def: 0
        },
        {
            key: "europeanAQICategory",
            def: ""
        },
        {
            key: "europeanAQIColor",
            def: ""
        },
        {
            key: "europeanDescription",
            def: ""
        },
        {
            key: "usAQI",
            def: 0
        },
        {
            key: "usAQICategory",
            def: ""
        },
        {
            key: "usAQIColor",
            def: ""
        },
        {
            key: "usDescription",
            def: ""
        },
        {
            key: "pm10",
            def: 0.0
        },
        {
            key: "pm25",
            def: 0.0
        },
        {
            key: "dominantPollutant",
            def: ""
        },
        {
            key: "healthRecommendation",
            def: ""
        },
        {
            key: "hourlyAQIForecast",
            def: []
        },
        {
            key: "sunRise",
            def: ""
        },
        {
            key: "sunSet",
            def: ""
        },
        {
            key: "moonRise",
            def: ""
        },
        {
            key: "moonSet",
            def: ""
        },
        {
            key: "moonPhase",
            def: ""
        },
        {
            key: "moonIllumination",
            def: 0
        },
        {
            key: "isMoonUp",
            def: false
        },
        {
            key: "isSunUp",
            def: false
        },
        {
            key: "locationName",
            def: ""
        },
        {
            key: "locationRegion",
            def: ""
        },
        {
            key: "locationCountry",
            def: ""
        },
        {
            key: "timeZoneIdentifier",
            def: ""
        },
        {
            key: "lastUpdateWeather",
            def: ""
        },
        {
            key: "lastUpdateAQI",
            def: ""
        },
        {
            key: "lastUpdateAstronomy",
            def: ""
        }
    ]

    // Weather properties
    property real latitude: 0.0
    property real longitude: 0.0
    property string timezone: ""
    property real elevation: 0.0
    property string lastUpdateWeather
    property string weatherCondition: ""
    property string weatherDescription: ""
    property string weatherIcon: "air"
    property int weatherCode: 0
    property bool isDay: true
    property int temperature: 0
    property int temperatureMin: 0
    property int temperatureMax: 0
    property int feelsLike: 0
    property int humidity: 0
    property real dewPoint: 0.0
    property int windSpeed: 0
    property string windDirection: ""
    property int windDirectionDegrees: 0
    property int uvIndex: 0
    property int pressure: 0
    property real visibility: 0.0
    property int cloudCover: 0
    property real precipitation: 0.0
    property real precipitationDaily: 0.0
    property string lastUpdateAstronomy
    property string sunRise: ""
    property string sunSet: ""
    property string dayLength: ""
    property string moonRise: ""
    property string moonSet: ""
    property string moonPhase: ""
    property int moonIllumination: 0
    property bool isMoonUp: false
    property bool isSunUp: false

    property var hourlyForecast: []
    property var dailyForecast: []

    // AQI properties
    property string lastUpdateAQI
    property int europeanAQI: 0
    property string europeanAQICategory: ""
    property string europeanAQIColor: ""
    property string europeanDescription: ""
    property int usAQI: 0
    property string usAQICategory: ""
    property string usAQIColor: ""
    property string usDescription: ""
    property real pm10: 0.0
    property real pm25: 0.0
    property string dominantPollutant: ""
    property string healthRecommendation: ""
    property var hourlyAQIForecast: []

    // Loading states
    property bool weatherLoaded: false
    property bool weatherLoading: false
    property bool aqiLoaded: false
    property bool aqiLoading: false
    property bool astronomyLoaded: false
    property bool astronomyLoading: false
    property bool loaded: weatherLoaded && aqiLoaded && astronomyLoaded

    // Locations
    property string locationName: ""
    property string locationRegion: ""
    property string locationCountry: ""
    property string timeZoneIdentifier: ""

    property string configLatitude: Configs.weather.latitude
    property string configLongitude: Configs.weather.longitude
    property int reloadInterval: (Configs.weather.reloadTime || 1800) * 1000

    property var activeWeatherRequest: null
    property var activeAQIRequest: null
    property var activeAstronomyRequest: null

    function getWeatherIconFromCode(code, isDayTime) {
        if (code === null || code === undefined)
            return WeatherIcon.windy;
        const codeStr = code.toString();
        if (!isDayTime && weatherIconsNight[codeStr])
            return weatherIconsNight[codeStr];
        return weatherIcons[codeStr] || WeatherIcon.windy;
    }

    function formatTime(timeStr) {
        if (!timeStr)
            return "";
        try {
            const date = new Date(timeStr);
            return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
        } catch (e) {
            return timeStr;
        }
    }

    function formatDate(dateStr) {
        if (!dateStr)
            return "";
        try {
            return new Date(dateStr).toLocaleDateString('en-US', {
                weekday: 'long',
                month: 'short',
                day: 'numeric'
            });
        } catch (e) {
            return dateStr;
        }
    }

    function parseAstronomyTime(timeStr) {
        if (!timeStr)
            return "";
        try {
            const match = timeStr.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
            if (!match)
                return timeStr;
            let hours = parseInt(match[1]);
            const period = match[3].toUpperCase();
            if (period === "PM" && hours !== 12)
                hours += 12;
            else if (period === "AM" && hours === 12)
                hours = 0;
            return `${String(hours).padStart(2, '0')}:${match[2]}`;
        } catch (e) {
            return timeStr;
        }
    }

    function calculateDayLength() {
        if (!sunRise || !sunSet)
            return {
                hours: 0,
                minutes: 0
            };
        try {
            const [rh, rm] = sunRise.split(':').map(Number);
            const [sh, sm] = sunSet.split(':').map(Number);
            let total = (sh * 60 + sm) - (rh * 60 + rm);
            if (total < 0)
                total += 24 * 60;
            return {
                hours: Math.floor(total / 60),
                minutes: total % 60
            };
        } catch (e) {
            return {
                hours: 0,
                minutes: 0
            };
        }
    }

    function getWeatherStatus(code) {
        return WD.statusTexts[code] || "Unknown";
    }

    function getWindDirectionText(degrees) {
        return WD.getWindDirection(degrees);
    }

    function getEuropeanAQIInfo(aqi) {
        return WD.getAQIInfo(aqi, WD.europeanAQI);
    }

    function getUSAQIInfo(aqi) {
        return WD.getAQIInfo(aqi, WD.usAQI);
    }

    function getDominantPollutant(pm25, pm10) {
        var pm25Ratio = pm25 / 15.0;
        var pm10Ratio = pm10 / 45.0;
        if (pm25Ratio > pm10Ratio && pm25 > 15)
            return "PM2.5";
        if (pm10 > 45)
            return "PM10";
        if (pm25 > pm10)
            return "PM2.5";
        return "PM10";
    }

    function getHealthRecommendation(euAQI, usAQI, pm25, pm10) {
        var maxAQI = euAQI;
        if (usAQI > 150)
            maxAQI = usAQI;
        if (maxAQI <= 50)
            return "Perfect day for outdoor activities! Air quality is excellent.";
        if (maxAQI <= 75)
            return "Good for most outdoor activities. Sensitive individuals (children, elderly, those with respiratory conditions) should be cautious.";
        if (maxAQI <= 100)
            return "Consider limiting prolonged outdoor activities, especially if you're sensitive to air pollution. Take more breaks during outdoor exercise.";
        if (maxAQI <= 150)
            return "Reduce prolonged or heavy outdoor exertion. Reschedule strenuous activities or take more breaks. Sensitive groups should avoid prolonged outdoor activities.";
        if (maxAQI <= 200)
            return "Avoid prolonged outdoor exertion. Everyone should reduce outdoor activities. Keep outdoor activities short and less strenuous.";
        return "Avoid all outdoor physical activities. Stay indoors, keep windows closed, and use air purifiers if available. Sensitive groups should remain indoors.";
    }

    function getQuickSummary() {
        if (!weatherLoaded)
            return "";
        const parts = [];

        if (humidity > 80 && temperature > 25)
            parts.push(qsTr("A muggy and warm day — take care in the sun."));
        else if (humidity > 80 && temperature <= 25)
            parts.push(qsTr("A humid day with sticky conditions."));
        else if (temperature > 30)
            parts.push(qsTr("A hot day ahead — stay hydrated and seek shade."));
        else if (temperature < 10)
            parts.push(qsTr("A cold day — dress warmly before heading out."));
        else if (temperature >= 20 && temperature <= 28 && humidity < 60)
            parts.push(qsTr("A pleasant day with comfortable conditions."));
        else
            parts.push(qsTr("Today's weather looks moderate."));

        const priorityItems = [];
        if (europeanAQI > 80 || usAQI > 150)
            priorityItems.push({
                priority: 10,
                text: qsTr("Air quality is poor right now — consider limiting time outside.")
            });
        else if (europeanAQI > 60 || usAQI > 100)
            priorityItems.push({
                priority: 7,
                text: qsTr("Air quality is moderate — sensitive groups should take precautions.")
            });

        if (uvIndex >= 8)
            priorityItems.push({
                priority: 9,
                text: qsTr("UV index is very high (%1) — avoid direct sun exposure.").arg(uvIndex)
            });
        else if (uvIndex >= 6)
            priorityItems.push({
                priority: 6,
                text: qsTr("Strong UV levels at %1 — use sun protection.").arg(uvIndex)
            });

        if (precipitation > 5)
            priorityItems.push({
                priority: 8,
                text: qsTr("Heavy rain expected — bring an umbrella.")
            });
        else if (precipitation > 0.5)
            priorityItems.push({
                priority: 5,
                text: qsTr("Light rain possible — keep an umbrella handy.")
            });

        if (windSpeed > 50)
            priorityItems.push({
                priority: 8,
                text: qsTr("Very windy conditions at %1 km/h — be cautious outdoors.").arg(windSpeed)
            });
        else if (windSpeed > 30)
            priorityItems.push({
                priority: 4,
                text: qsTr("Breezy day with winds around %1 km/h.").arg(windSpeed)
            });

        if (temperatureMax > 0 && temperatureMin !== temperatureMax && Math.abs(temperatureMax - temperatureMin) > 8)
            priorityItems.push({
                priority: 5,
                text: qsTr("Large temperature swing today: %1° to %2° — dress in layers.").arg(temperatureMin).arg(temperatureMax)
            });
        else if (temperatureMax > 0 && temperatureMin !== temperatureMax)
            priorityItems.push({
                priority: 3,
                text: qsTr("Temperature ranging from %1° to %2° today.").arg(temperatureMin).arg(temperatureMax)
            });

        if (humidity > 85)
            priorityItems.push({
                priority: 6,
                text: qsTr("Very sticky conditions with %1% humidity.").arg(humidity)
            });
        if (visibility < 1)
            priorityItems.push({
                priority: 7,
                text: qsTr("Poor visibility at %1 km — drive carefully.").arg(visibility.toFixed(1))
            });
        if (temperature >= 18 && temperature <= 26 && humidity < 65 && uvIndex < 5 && precipitation === 0)
            priorityItems.push({
                priority: 4,
                text: qsTr("Perfect weather for outdoor activities.")
            });

        priorityItems.sort((a, b) => b.priority - a.priority);
        priorityItems.slice(0, 3).forEach(i => parts.push(i.text));
        if (parts.length < 2)
            parts.push(qsTr("Current temperature is %1° with feels like %2°.").arg(temperature).arg(feelsLike));

        const isFinal = parts.slice(0, 4);
        return isFinal.length === 0 ? "" : isFinal[0] + "\n\n• " + isFinal.slice(1).join("\n\n• ");
    }

    function cleanupRequest(request) {
        if (request) {
            try {
                request.onreadystatechange = null;
                request.onerror = null;
                request.ontimeout = null;
            } catch (e) {
                console.error("Error cleaning up request handlers:", e);
            }
        }
    }

    function fetchData(config) {
        const lat = parseFloat(configLatitude);
        const lon = parseFloat(configLongitude);
        if (isNaN(lat) || isNaN(lon)) {
            ToastService.show(qsTr("Invalid coordinates"), qsTr("Weather"), "weather-clear-symbolic", 3000);
            return;
        }
        if (root[config.loadingProp])
            return;

        if (root[config.requestProp]) {
            try {
                root[config.requestProp].abort();
            } catch (e) {}
            cleanupRequest(root[config.requestProp]);
            root[config.requestProp] = null;
        }

        root[config.loadingProp] = true;
        const request = new XMLHttpRequest();
        root[config.requestProp] = request;
        request.timeout = 30000;

        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            if (request === root[config.requestProp])
                root[config.requestProp] = null;

            if (request.status === 200) {
                try {
                    console.log("[WEATHER] %1 response received, parsing...".arg(config.label));
                    config.onSuccess(JSON.parse(request.responseText));
                    ToastService.show(qsTr("%1 updated").arg(config.label), qsTr("Weather"), "weather-clear-symbolic", 2000);
                } catch (e) {
                    ToastService.show(qsTr("%1 failed: bad data").arg(config.label), qsTr("Weather"), "weather-error-symbolic", 3000);
                    root[config.loadingProp] = false;
                }
            } else {
                ToastService.show(qsTr("%1 failed (%2)").arg(config.label).arg(request.status), qsTr("Weather"), "weather-error-symbolic", 3000);
                root[config.loadingProp] = false;
            }
            cleanupRequest(request);
        };

        const fail = reason => () => {
                ToastService.show(qsTr("%1 %2").arg(config.label).arg(reason), qsTr("Weather"), "weather-error-symbolic", 3000);
                if (request === root[config.requestProp])
                    root[config.requestProp] = null;
                root[config.loadingProp] = false;
                cleanupRequest(request);
            };
        request.onerror = fail(qsTr("network error"));
        request.ontimeout = fail(qsTr("timed out"));

        var separator = config.url.indexOf('?') >= 0 ? '&' : '?';
        var fullUrl = `${config.url}${separator}latitude=${lat}&longitude=${lon}`;
        console.log("[WEATHER] Request URL: " + fullUrl);
        request.open("GET", fullUrl);
        request.send();
    }

    function reloadWeather() {
        console.log("[WEATHER] Fetching weather data from Open-Meteo...");
        fetchData({
            url: "https://api.open-meteo.com/v1/forecast" + "?current=precipitation,rain,wind_speed_10m,wind_direction_10m,cloud_cover,surface_pressure,weather_code,relative_humidity_2m,temperature_2m,apparent_temperature,is_day" + "&daily=sunrise,sunset,uv_index_max,weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,precipitation_hours,rain_sum,showers_sum,surface_pressure_mean,visibility_mean,wind_speed_10m_mean,wind_direction_10m_dominant,relative_humidity_2m_max,relative_humidity_2m_min,relative_humidity_2m_mean,dew_point_2m_mean,cloud_cover_mean" + "&hourly=temperature_2m,weather_code,wind_speed_10m,precipitation,precipitation_probability,rain,visibility,cloud_cover,surface_pressure,wind_direction_10m,relative_humidity_2m,uv_index,is_day,showers,dew_point_2m" + "&timezone=auto&forecast_days=7",
            loadingProp: "weatherLoading",
            requestProp: "activeWeatherRequest",
            onSuccess: updateWeatherData,
            label: "Weather"
        });
    }
    function reloadAQI() {
        console.log("[WEATHER] Fetching AQI data from Open-Meteo...");
        fetchData({
            url: "https://air-quality-api.open-meteo.com/v1/air-quality" + "?current=european_aqi,us_aqi" + "&hourly=pm10,pm2_5,european_aqi,us_aqi" + "&timezone=auto&forecast_days=1",
            loadingProp: "aqiLoading",
            requestProp: "activeAQIRequest",
            onSuccess: updateAQIData,
            label: "AQI"
        });
    }
    function reloadAstronomy() {
        console.log("[WEATHER] Fetching astronomy data from WeatherAPI.com...");
        var lat = parseFloat(configLatitude);
        var lon = parseFloat(configLongitude);
        if (isNaN(lat) || isNaN(lon)) {
            ToastService.show(qsTr("Invalid coordinates"), qsTr("Weather"), "weather-clear-symbolic", 3000);
            return;
        }
        var key = Configs.weather.astronomyApiKey;
        if (!key) {
            console.log("No astronomy API key configured, skipping astronomy fetch");
            ToastService.show(qsTr("No astronomy API key configured"), qsTr("Weather"), "weather-error-symbolic", 3000);
            astronomyLoading = false;
            return;
        }
        if (astronomyLoading)
            return;

        if (activeAstronomyRequest) {
            try {
                activeAstronomyRequest.abort();
            } catch (e) {}
            cleanupRequest(activeAstronomyRequest);
            activeAstronomyRequest = null;
        }

        var today = new Date();
        var dateStr = today.getFullYear() + "-" + String(today.getMonth() + 1).padStart(2, '0') + "-" + String(today.getDate()).padStart(2, '0');

        astronomyLoading = true;
        var request = new XMLHttpRequest();
        activeAstronomyRequest = request;
        request.timeout = 30000;

        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            if (request === activeAstronomyRequest)
                activeAstronomyRequest = null;

            if (request.status === 200) {
                try {
                    updateAstronomyData(JSON.parse(request.responseText));
                } catch (e) {
                    ToastService.show(qsTr("Astronomy failed: bad data"), qsTr("Weather"), "weather-error-symbolic", 3000);
                    astronomyLoading = false;
                }
            } else {
                ToastService.show(qsTr("Astronomy failed (%1)").arg(request.status), qsTr("Weather"), "weather-error-symbolic", 3000);
                astronomyLoading = false;
            }
            cleanupRequest(request);
        };

        var fail = function (reason) {
            return function () {
                ToastService.show(qsTr("Astronomy %1").arg(reason), qsTr("Weather"), "weather-error-symbolic", 3000);
                if (request === activeAstronomyRequest)
                    activeAstronomyRequest = null;
                astronomyLoading = false;
                cleanupRequest(request);
            };
        };
        request.onerror = fail(qsTr("network error"));
        request.ontimeout = fail(qsTr("timed out"));

        var url = "https://api.weatherapi.com/v1/astronomy.json" + "?key=" + encodeURIComponent(key) + "&q=" + lat.toFixed(4) + "," + lon.toFixed(4) + "&dt=" + dateStr;
        console.log("[WEATHER] Request URL: " + url.replace(encodeURIComponent(key), "***"));
        request.open("GET", url);
        request.send();
    }

    function reload() {
        reloadWeather();
        reloadAQI();
        reloadAstronomy();
    }

    function refresh() {
        if (canRefresh) {
            console.log("[WEATHER SERVICES] Refresh/reload weather data");
            reload();
            return true;
        } else {
            console.log("[WEATHER SERVICES] Cannot refresh: already loading");
            return false;
        }
    }

    function updateWeatherData(json) {
        try {
            var cur = json.current || {}, hourly = json.hourly || {}, daily = json.daily || {};

            weatherLoaded = true;
            weatherLoading = false;
            lastUpdateWeather = Date.now();
            latitude = json.latitude || 0.0;
            longitude = json.longitude || 0.0;
            timezone = json.timezone || "";
            elevation = json.elevation || 0.0;

            var statusText = getWeatherStatus(cur.weather_code || 0);
            var isDayTime = cur.is_day === 1;

            temperature = Math.round(cur.temperature_2m || 0);
            feelsLike = Math.round(cur.apparent_temperature || 0);
            temperatureMin = Math.round(daily.temperature_2m_min?.[0] || 0);
            temperatureMax = Math.round(daily.temperature_2m_max?.[0] || 0);
            weatherCode = cur.weather_code || 0;
            weatherCondition = statusText;
            weatherDescription = statusText;
            isDay = isDayTime;
            weatherIcon = getWeatherIconFromCode(cur.weather_code, isDayTime);

            humidity = cur.relative_humidity_2m || 0;
            dewPoint = hourly.dew_point_2m?.[0] || 0.0;
            windSpeed = Math.round(cur.wind_speed_10m || 0);
            windDirection = getWindDirectionText(cur.wind_direction_10m || 0);
            windDirectionDegrees = cur.wind_direction_10m || 0;
            uvIndex = Math.round(daily.uv_index_max?.[0] || 0);
            pressure = Math.round(cur.surface_pressure || 0);
            visibility = (daily.visibility_mean?.[0] || 0) / 1000;
            cloudCover = cur.cloud_cover || 0;
            precipitation = cur.precipitation || 0.0;
            precipitationDaily = daily.precipitation_sum?.[0] || 0.0;

            var newHourly = [];
            for (var i = 0; i < (hourly.time || []).length && i < 24; i++) {
                var hIsDay = hourly.is_day?.[i] === 1;
                newHourly.push({
                    time: formatTime(hourly.time[i]),
                    fullTime: hourly.time[i],
                    temperature: Math.round(hourly.temperature_2m?.[i] || 0),
                    humidity: hourly.relative_humidity_2m?.[i] || 0,
                    weatherCode: hourly.weather_code?.[i] || 0,
                    weatherIcon: getWeatherIconFromCode(hourly.weather_code?.[i], hIsDay),
                    isDay: hIsDay,
                    precipitation: hourly.precipitation?.[i] || 0.0,
                    probability: hourly.precipitation_probability?.[i] || 0,
                    pressure: hourly.surface_pressure?.[i] || 0.0,
                    windSpeed: hourly.wind_speed_10m?.[i] || 0.0,
                    windDirectionDegrees: hourly.wind_direction_10m?.[i] || 0,
                    windDirectionText: getWindDirectionText(hourly.wind_direction_10m?.[i] || 0)
                });
            }
            hourlyForecast = newHourly;

            var newDaily = [];
            for (var j = 0; j < (daily.time || []).length; j++) {
                var d = new Date(daily.time[j]);
                var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                newDaily.push({
                    date: daily.time[j],
                    day: d.toLocaleDateString("en-US", {
                        weekday: "long"
                    }),
                    dateFormatted: String(d.getDate()).padStart(2, "0") + "/" + months[d.getMonth()],
                    maxTemp: Math.round(daily.temperature_2m_max?.[j] || 0),
                    minTemp: Math.round(daily.temperature_2m_min?.[j] || 0),
                    humidity: daily.relative_humidity_2m_mean?.[j] || 0,
                    weatherCode: daily.weather_code?.[j] || 0,
                    weatherIcon: getWeatherIconFromCode(daily.weather_code?.[j], true),
                    rainProbability: daily.precipitation_probability_max?.[j] || 0,
                    sunrise: formatTime(daily.sunrise?.[j] || ""),
                    sunset: formatTime(daily.sunset?.[j] || ""),
                    precipitation: daily.precipitation_sum?.[j] || 0.0,
                    rain: daily.rain_sum?.[j] || 0.0,
                    showers: daily.showers_sum?.[j] || 0.0
                });
            }
            dailyForecast = newDaily;

            saveTimer.restart();
            console.log("[WEATHER] Weather data updated — %1 hourly, %2 daily".arg(hourlyForecast.length).arg(dailyForecast.length));
        } catch (e) {
            console.error("Failed to update weather data:", e);
            weatherLoading = false;
        }
    }

    function updateAQIData(json) {
        try {
            var cur = json.current || {}, hourly = json.hourly || {};

            aqiLoaded = true;
            aqiLoading = false;
            lastUpdateAQI = Date.now();

            var euAQI = cur.european_aqi || 0;
            var usAQIval = cur.us_aqi || 0;
            var currentPM10 = hourly.pm10?.[0] || 0.0;
            var currentPM25 = hourly.pm2_5?.[0] || 0.0;

            if (!latitude) {
                latitude = json.latitude || 0.0;
                longitude = json.longitude || 0.0;
                timezone = json.timezone || "";
            }

            var euInfo = getEuropeanAQIInfo(euAQI);
            var usInfo = getUSAQIInfo(usAQIval);

            europeanAQI = euAQI;
            europeanAQICategory = euInfo.category;
            europeanAQIColor = euInfo.color;
            europeanDescription = euInfo.description;
            usAQI = usAQIval;
            usAQICategory = usInfo.category;
            usAQIColor = usInfo.color;
            usDescription = usInfo.description;
            pm10 = currentPM10;
            pm25 = currentPM25;
            dominantPollutant = getDominantPollutant(currentPM25, currentPM10);
            healthRecommendation = getHealthRecommendation(euAQI, usAQIval, currentPM25, currentPM10);

            var newAQIHourly = [];
            for (var i = 0; i < (hourly.time || []).length; i++) {
                var heu = hourly.european_aqi?.[i] || 0;
                var hus = hourly.us_aqi?.[i] || 0;
                newAQIHourly.push({
                    time: formatTime(hourly.time[i]),
                    fullTime: hourly.time[i],
                    europeanAQI: heu,
                    europeanAQICategory: getEuropeanAQIInfo(heu).category,
                    usAQI: hus,
                    usAQICategory: getUSAQIInfo(hus).category,
                    pm10: hourly.pm10?.[i] || 0.0,
                    pm25: hourly.pm2_5?.[i] || 0.0
                });
            }
            hourlyAQIForecast = newAQIHourly;

            saveTimer.restart();
            console.log("[WEATHER] AQI data updated — EU: %1, US: %2".arg(europeanAQI).arg(usAQI));
        } catch (e) {
            console.error("Failed to update AQI data:", e);
            aqiLoading = false;
        }
    }

    function updateAstronomyData(json) {
        try {
            const astro = json.astronomy?.astro || {}, loc = json.location || {};
            astronomyLoaded = true;
            astronomyLoading = false;

            sunRise = parseAstronomyTime(astro.sunrise);
            sunSet = parseAstronomyTime(astro.sunset);
            moonRise = parseAstronomyTime(astro.moonrise);
            moonSet = parseAstronomyTime(astro.moonset);
            moonPhase = astro.moon_phase || "";
            moonIllumination = astro.moon_illumination || 0;
            isMoonUp = astro.is_moon_up === 1;
            isSunUp = astro.is_sun_up === 1;
            dayLength = "";

            locationName = loc.name || "";
            locationRegion = loc.region || "";
            locationCountry = loc.country || "";
            timeZoneIdentifier = loc.tz_id || "";
            lastUpdateAstronomy = Date.now();

            saveTimer.restart();
            console.log("[WEATHER] Astronomy data updated — %1, %2".arg(locationName).arg(locationCountry));
        } catch (e) {
            console.error("Failed to update astronomy data:", e);
            astronomyLoading = false;
        }
    }

    function buildSaveData() {
        const data = {
            timestamp: Date.now()
        };
        for (const field of weatherSchema)
            data[field.key] = root[field.key];
        return data;
    }

    function restoreFromCache(data) {
        for (const field of weatherSchema)
            root[field.key] = data[field.key] ?? field.def;
    }

    function reloadIfLoaded() {
        if (weatherLoaded || aqiLoaded || astronomyLoaded)
            reload();
    }

    Timer {
        id: reloadTimer

        interval: root.reloadInterval
        running: GlobalStates.isWeatherPanelOpen
        repeat: GlobalStates.isWeatherPanelOpen
        triggeredOnStart: false
        onTriggered: root.reload()
    }

    Timer {
        id: saveTimer

        interval: 100
        onTriggered: storage.setText(JSON.stringify(root.buildSaveData(), null, 2))
    }

    FileView {
        id: storage

        path: Paths.cacheDir + "/weather_shell/weather.json"
        onLoaded: {
            try {
                const content = text();
                if (!content.trim()) {
                    console.log("No cached weather data found, fetching fresh data");
                    ToastService.show(qsTr("No cached weather data found, fetching fresh data"), qsTr("Weather"), "weather-clear-symbolic", 3000);
                    root.reload();
                    return;
                }

                const data = JSON.parse(content);
                console.log("Loading weather data from cache...");
                root.restoreFromCache(data);

                root.weatherLoaded = true;
                root.aqiLoaded = true;
                root.astronomyLoaded = true;

                const age = Math.floor((Date.now() - (data.timestamp || 0)) / 60000);
                console.log(`Loaded weather data from cache (${age} minutes old)`);
                console.log("Fetching fresh weather data in background...");

                reloadTimer.start();
                root.reload();
            } catch (error) {
                console.error("Failed to load weather cache:", error);
                root.reload();
            }
        }
        onLoadFailed: error => {
            console.log("Weather cache doesn't exist, creating it and fetching data");
            setText("{}");
            root.reload();
        }
    }

    Component.onDestruction: {
        for (const prop of ["activeWeatherRequest", "activeAQIRequest", "activeAstronomyRequest"]) {
            if (root[prop]) {
                try {
                    root[prop].abort();
                } catch (e) {}
                cleanupRequest(root[prop]);
                root[prop] = null;
            }
        }
    }
    onConfigLatitudeChanged: reloadIfLoaded()
    onConfigLongitudeChanged: reloadIfLoaded()
}
