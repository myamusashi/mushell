pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Helpers

Singleton {
    id: root

    readonly property var weatherIcons: ({
            // Clear sky
            "0": WeatherIcon.day_sunny,

            // Mainly clear
            "1": WeatherIcon.day_cloudy,

            // Partly cloudy
            "2": WeatherIcon.day_cloudy,

            // Overcast
            "3": WeatherIcon.cloud,

            // Fog (45-48)
            "45": WeatherIcon.fog              // Fog
            ,
            "48": WeatherIcon.fog              // Depositing rime fog

            ,

            // Drizzle (51-57)
            "51": WeatherIcon.rain             // Light drizzle
            ,
            "53": WeatherIcon.rain             // Moderate drizzle
            ,
            "55": WeatherIcon.rain             // Dense drizzle
            ,
            "56": WeatherIcon.sleet            // Light freezing drizzle
            ,
            "57": WeatherIcon.sleet            // Dense freezing drizzle

            ,

            // Rain (61-67)
            "61": WeatherIcon.rain             // Slight rain
            ,
            "63": WeatherIcon.rain             // Moderate rain
            ,
            "65": WeatherIcon.rain             // Heavy rain
            ,
            "66": WeatherIcon.rain_mix         // Light freezing rain
            ,
            "67": WeatherIcon.rain_mix         // Heavy freezing rain

            ,

            // Snow (71-77)
            "71": WeatherIcon.snow             // Slight snow
            ,
            "73": WeatherIcon.snow             // Moderate snow
            ,
            "75": WeatherIcon.snow             // Heavy snow
            ,
            "77": WeatherIcon.snow             // Snow grains

            ,

            // Showers (80-82)
            "80": WeatherIcon.showers          // Slight rain showers
            ,
            "81": WeatherIcon.showers          // Moderate rain showers
            ,
            "82": WeatherIcon.storm_showers    // Violent rain showers

            ,

            // Snow showers (85-86)
            "85": WeatherIcon.snow             // Slight snow showers
            ,
            "86": WeatherIcon.snow             // Heavy snow showers

            ,

            // Thunderstorm (95-99)
            "95": WeatherIcon.thunderstorm     // Thunderstorm
            ,
            "96": WeatherIcon.thunderstorm     // Thunderstorm with slight hail
            ,
            "99": WeatherIcon.thunderstorm      // Thunderstorm with heavy hail
        })

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
    property int temp: 0
    property int tempMin: 0
    property int tempMax: 0
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

    property string quickSummary: ""
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
    readonly property bool isLoading: weatherLoading || aqiLoading || astronomyLoading
    readonly property bool isRefreshing: (weatherLoading || aqiLoading || astronomyLoading) && loaded
    readonly property bool isInitialLoading: (weatherLoading || aqiLoading || astronomyLoading) && !loaded
    readonly property bool canRefresh: !isLoading
    readonly property bool hasData: loaded

    // Locations
    property string locationName: ""
    property string locationRegion: ""
    property string locationCountry: ""
    property string timeZoneIdentifier: ""

    property string configLatitude: Configs.weather.latitude
    property string configLongitude: Configs.weather.longitude
    property int reloadInterval: Configs.weather.reloadTime || 1800000 // 30 minutes default

    property var _activeWeatherRequest: null
    property var _activeAQIRequest: null
    property var _activeAstronomyRequest: null

    function getWeatherIconFromCode(code, isDayTime) {
        if (code === null || code === undefined)
            return "air";

        const codeStr = code.toString();
        const iconName = weatherIcons[codeStr] || "air";

        if (code === 0 || code === 1 || code === 2) {
            if (isDayTime) {
                if (code === 0)
                    return "clear_day";
                if (code === 1)
                    return "partly_cloudy_day";
                if (code === 2)
                    return "partly_cloudy_day";
            } else {
                if (code === 0)
                    return "clear_night";
                if (code === 1)
                    return "partly_cloudy_night";
                if (code === 2)
                    return "partly_cloudy_night";
            }
        }

        return iconName;
    }

    function formatTime(timeStr) {
        if (!timeStr)
            return "";
        try {
            const date = new Date(timeStr);
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');
            return `${hours}:${minutes}`;
        } catch (e) {
            return timeStr;
        }
    }

    function formatDate(dateStr) {
        if (!dateStr)
            return "";
        try {
            const date = new Date(dateStr);
            return date.toLocaleDateString('en-US', {
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
            const minutes = match[2];
            const period = match[3].toUpperCase();

            if (period === "PM" && hours !== 12) {
                hours += 12;
            } else if (period === "AM" && hours === 12) {
                hours = 0;
            }

            return `${String(hours).padStart(2, '0')}:${minutes}`;
        } catch (e) {
            return timeStr;
        }
    }

    function updateWeatherData(json) {
        try {
            const location = json.location || {};
            const current = json.current || {};
            const details = json.details || {};
            const hourly = json.hourly_forecast || [];
            const daily = json.daily_forecast || {};
            const humidity = details.humidity || {};
            const wind = details.wind || {};

            root.weatherLoaded = true;
            root.weatherLoading = false;

            root.lastUpdateWeather = current.last_update || Date.now();

            root.latitude = location.latitude || 0.0;
            root.longitude = location.longitude || 0.0;
            root.timezone = location.timezone || "";
            root.elevation = location.elevation || 0.0;

            root.temp = Math.round(current.temperature || 0);
            root.feelsLike = Math.round(current.feels_like || 0);
            root.tempMin = Math.round(current.min_temp || 0);
            root.tempMax = Math.round(current.max_temp || 0);
            root.weatherCode = current.weather_code || 0;
            root.weatherCondition = current.status || "";
            root.weatherDescription = current.status || "";
            root.isDay = current.is_day || false;

            root.weatherIcon = getWeatherIconFromCode(current.weather_code, current.is_day);

            root.humidity = humidity.percentage || 0;
            root.dewPoint = humidity.dew_point || 0.0;
            root.windSpeed = Math.round(wind.speed_kmh || 0);
            root.windDirection = wind.direction_text || "";
            root.windDirectionDegrees = wind.direction_degrees || 0;
            root.uvIndex = Math.round(details.uv_index || 0);
            root.pressure = Math.round(details.surface_pressure_hpa || 0);
            root.visibility = details.visibility_km || 0.0;
            root.cloudCover = details.cloudiness_percent || 0;
            root.precipitation = details.precipitation_current_mm || 0.0;
            root.precipitationDaily = details.precipitation_daily_mm || 0.0;

            root.quickSummary = json.quick_summary || "";

            root.hourlyForecast = hourly.map(function (hour) {
                return {
                    time: formatTime(hour.time),
                    fullTime: hour.time,
                    temperature: Math.round(hour.temperature),
                    humidity: hour.humidity,
                    weatherCode: hour.weather_code,
                    weatherIcon: getWeatherIconFromCode(hour.weather_code, hour.is_day),
                    isDay: hour.is_day,
                    precipitation: hour.precipitation_mm || 0.0,
                    probability: hour.probability_percent || 0
                };
            });

            root.dailyForecast = daily.map(function (day) {
                return {
                    date: day.date,
                    day: day.day,
                    dateFormatted: day.date_formatted,
                    maxTemp: Math.round(day.max_temp),
                    minTemp: Math.round(day.min_temp),
                    humidity: day.humidity,
                    weatherCode: day.weather_code,
                    weatherIcon: getWeatherIconFromCode(day.weather_code, true),
                    rainProbability: day.rain_probability,
                    sunrise: formatTime(day.sunrise),
                    sunset: formatTime(day.sunset),
                    precipitation: day.precipitation_mm || 0.0,
                    rain: day.rain_mm || 0.0,
                    showers: day.showers_mm || 0.0
                };
            });

            root.weatherLoaded = true;
            root.weatherLoading = false;
            saveTimer.restart();
            console.log("Weather data updated successfully");
        } catch (e) {
            console.error("Failed to update weather data:", e);
            root.weatherLoading = false;
        }
    }

    function updateAQIData(json) {
        try {
            const location = json.location || {};
            const current = json.current || {};
            const hourly = json.hourly_forecast || [];

            root.aqiLoaded = true;
            root.aqiLoading = false;

            root.lastUpdateAQI = current.last_update || Date.now();

            // Update location if not set by weather
            if (!root.latitude) {
                root.latitude = location.latitude || 0.0;
                root.longitude = location.longitude || 0.0;
                root.timezone = location.timezone || "";
                root.elevation = location.elevation || 0.0;
            }

            root.europeanAQI = current.european_aqi || 0;
            root.europeanAQICategory = current.european_aqi_category || "";
            root.europeanAQIColor = current.european_aqi_color || "";
            root.europeanDescription = current.european_description || "";

            root.usAQI = current.us_aqi || 0;
            root.usAQICategory = current.us_aqi_category || "";
            root.usAQIColor = current.us_aqi_color || "";
            root.usDescription = current.us_description || "";

            root.pm10 = current.pm10_ugm3 || 0.0;
            root.pm25 = current.pm25_ugm3 || 0.0;
            root.dominantPollutant = current.dominant_pollutant || "";

            root.healthRecommendation = json.health_recommendation || "";

            root.hourlyAQIForecast = hourly.map(function (hour) {
                return {
                    time: formatTime(hour.time),
                    fullTime: hour.time,
                    europeanAQI: hour.european_aqi,
                    europeanAQICategory: hour.european_aqi_category,
                    usAQI: hour.us_aqi,
                    usAQICategory: hour.us_aqi_category,
                    pm10: hour.pm10_ugm3,
                    pm25: hour.pm25_ugm3
                };
            });

            root.aqiLoaded = true;
            root.aqiLoading = false;
            saveTimer.restart();
            console.log("AQI data updated successfully");
        } catch (e) {
            console.error("Failed to update AQI data:", e);
            root.aqiLoading = false;
        }
    }

    function updateAstronomyData(json) {
        try {
            const astro = json.astro || {};
            const location = json.location || {};

            root.astronomyLoaded = true;
            root.astronomyLoading = false;

            root.sunRise = parseAstronomyTime(astro.sunrise);
            root.sunSet = parseAstronomyTime(astro.sunset);
            root.moonRise = parseAstronomyTime(astro.moonrise);
            root.moonSet = parseAstronomyTime(astro.moonset);
            root.moonPhase = astro.moon_phase || "";
            root.moonIllumination = astro.moon_illumination || 0;
            root.isMoonUp = astro.is_moon_up === 1;
            root.isSunUp = astro.is_sun_up === 1;
            root.dayLength = "";

            root.locationName = location.name || "";
            root.locationRegion = location.region || "";
            root.locationCountry = location.country || "";
            root.timeZoneIdentifier = location.tz_id || "";
            root.lastUpdateAstronomy = location.localtime || Date.now();
            root.astronomyLoaded = true;
            root.astronomyLoading = false;
            saveTimer.restart();
            console.log("Astronomy data updated successfully");
        } catch (e) {
            console.error("Failed to update astronomy data:", e);
            root.astronomyLoading = false;
        }
    }

    function reloadWeather() {
        const lat = parseFloat(configLatitude);
        const lon = parseFloat(configLongitude);

        if (isNaN(lat) || isNaN(lon)) {
            console.log("Invalid latitude or longitude configured for weather");
            return;
        }

        if (weatherLoading) {
            console.log("Weather request already in progress");
            return;
        }

        if (_activeWeatherRequest) {
            try {
                _activeWeatherRequest.abort();
            } catch (e) {}
            _activeWeatherRequest = null;
        }

        weatherLoading = true;
        const url = `https://weather.myamusashi.space/v1/forecast?latitude=${lat}&longitude=${lon}`;

        let request = new XMLHttpRequest();
        _activeWeatherRequest = request;
        request.timeout = 30000;

        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request === _activeWeatherRequest) {
                    _activeWeatherRequest = null;
                }
                if (request.status === 200) {
                    try {
                        const json = JSON.parse(request.responseText);
                        updateWeatherData(json);
                    } catch (e) {
                        console.error("Failed to parse weather JSON:", e);
                        weatherLoading = false;
                    }
                } else {
                    console.error("Weather request failed with status:", request.status);
                    weatherLoading = false;
                }
            }
        };

        request.onerror = function () {
            console.error("Weather network error");
            if (request === _activeWeatherRequest) {
                _activeWeatherRequest = null;
            }
            weatherLoading = false;
        };

        request.ontimeout = function () {
            console.error("Weather request timeout");
            if (request === _activeWeatherRequest) {
                _activeWeatherRequest = null;
            }
            weatherLoading = false;
        };

        request.open("GET", url);
        request.send();
    }

    function reloadAQI() {
        const lat = parseFloat(configLatitude);
        const lon = parseFloat(configLongitude);

        if (isNaN(lat) || isNaN(lon)) {
            console.log("Invalid latitude or longitude configured for AQI");
            return;
        }

        if (aqiLoading) {
            console.log("AQI request already in progress");
            return;
        }

        if (_activeAQIRequest) {
            try {
                _activeAQIRequest.abort();
            } catch (e) {}
            _activeAQIRequest = null;
        }

        aqiLoading = true;
        const url = `https://aqi.myamusashi.space/v1/aqi?latitude=${lat}&longitude=${lon}`;

        let request = new XMLHttpRequest();
        _activeAQIRequest = request;
        request.timeout = 30000;

        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request === _activeAQIRequest) {
                    _activeAQIRequest = null;
                }
                if (request.status === 200) {
                    try {
                        const json = JSON.parse(request.responseText);
                        updateAQIData(json);
                    } catch (e) {
                        console.error("Failed to parse AQI JSON:", e);
                        aqiLoading = false;
                    }
                } else {
                    console.error("AQI request failed with status:", request.status);
                    aqiLoading = false;
                }
            }
        };

        request.onerror = function () {
            console.error("AQI network error");
            if (request === _activeAQIRequest) {
                _activeAQIRequest = null;
            }
            aqiLoading = false;
        };

        request.ontimeout = function () {
            console.error("AQI request timeout");
            if (request === _activeAQIRequest) {
                _activeAQIRequest = null;
            }
            aqiLoading = false;
        };

        request.open("GET", url);
        request.send();
    }

    function reloadAstronomy() {
        const lat = parseFloat(configLatitude);
        const lon = parseFloat(configLongitude);

        if (isNaN(lat) || isNaN(lon)) {
            console.log("Invalid latitude or longitude configured for astronomy");
            return;
        }

        if (astronomyLoading) {
            console.log("Astronomy request already in progress");
            return;
        }

        if (_activeAstronomyRequest) {
            try {
                _activeAstronomyRequest.abort();
            } catch (e) {}
            _activeAstronomyRequest = null;
        }

        astronomyLoading = true;
        const url = `https://astronomy.myamusashi.space/v1/astronomy?latitude=${lat}&longitude=${lon}`;

        let request = new XMLHttpRequest();
        _activeAstronomyRequest = request;
        request.timeout = 30000;

        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request === _activeAstronomyRequest) {
                    _activeAstronomyRequest = null;
                }
                if (request.status === 200) {
                    try {
                        const json = JSON.parse(request.responseText);
                        updateAstronomyData(json);
                    } catch (e) {
                        console.error("Failed to parse astronomy JSON:", e);
                        astronomyLoading = false;
                    }
                } else {
                    console.error("Astronomy request failed with status:", request.status);
                    astronomyLoading = false;
                }
            }
        };

        request.onerror = function () {
            console.error("Astronomy network error");
            if (request === _activeAstronomyRequest) {
                _activeAstronomyRequest = null;
            }
            astronomyLoading = false;
        };

        request.ontimeout = function () {
            console.error("Astronomy request timeout");
            if (request === _activeAstronomyRequest) {
                _activeAstronomyRequest = null;
            }
            astronomyLoading = false;
        };

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

    Timer {
        id: reloadTimer

        interval: root.reloadInterval
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.reload()
    }

    Timer {
        id: saveTimer

        interval: 100
        onTriggered: {
            const data = {
                // Weather data
                latitude: root.latitude,
                longitude: root.longitude,
                timezone: root.timezone,
                elevation: root.elevation,
                weatherCondition: root.weatherCondition,
                weatherDescription: root.weatherDescription,
                weatherIcon: root.weatherIcon,
                weatherCode: root.weatherCode,
                isDay: root.isDay,
                temp: root.temp,
                tempMin: root.tempMin,
                tempMax: root.tempMax,
                feelsLike: root.feelsLike,
                humidity: root.humidity,
                dewPoint: root.dewPoint,
                windSpeed: root.windSpeed,
                windDirection: root.windDirection,
                windDirectionDegrees: root.windDirectionDegrees,
                uvIndex: root.uvIndex,
                pressure: root.pressure,
                visibility: root.visibility,
                cloudCover: root.cloudCover,
                precipitation: root.precipitation,
                precipitationDaily: root.precipitationDaily,
                quickSummary: root.quickSummary,
                hourlyForecast: root.hourlyForecast,
                dailyForecast: root.dailyForecast,

                // AQI data
                europeanAQI: root.europeanAQI,
                europeanAQICategory: root.europeanAQICategory,
                europeanAQIColor: root.europeanAQIColor,
                europeanDescription: root.europeanDescription,
                usAQI: root.usAQI,
                usAQICategory: root.usAQICategory,
                usAQIColor: root.usAQIColor,
                usDescription: root.usDescription,
                pm10: root.pm10,
                pm25: root.pm25,
                dominantPollutant: root.dominantPollutant,
                healthRecommendation: root.healthRecommendation,
                hourlyAQIForecast: root.hourlyAQIForecast,

                // Astronomy data
                sunRise: root.sunRise,
                sunSet: root.sunSet,
                moonRise: root.moonRise,
                moonSet: root.moonSet,
                moonPhase: root.moonPhase,
                moonIllumination: root.moonIllumination,
                isMoonUp: root.isMoonUp,
                isSunUp: root.isSunUp,
                timestamp: Date.now(),

                // Locations
                locationName: root.locationName,
                locationRegion: root.locationRegion,
                locationCountry: root.locationCountry,
                timeZoneIdentifier: root.timeZoneIdentifier,

                // last update
                lastUpdateWeather: root.lastUpdateWeather,
                lastUpdateAQI: root.lastUpdateAQI,
                lastUpdateAstronomy: root.lastUpdateAstronomy
            };
            storage.setText(JSON.stringify(data, null, 2));
        }
    }

    FileView {
        id: storage

        path: Paths.cacheDir + "/weather_shell/weather.json"
        onLoaded: {
            try {
                const content = text();
                if (!content || content.trim() === "") {
                    console.log("No cached weather data found");
                    root.reload();
                    return;
                }

                const data = JSON.parse(content);
                const cacheAge = Date.now() - (data.timestamp || 0);
                const maxCacheAge = 3600000; // 1 hour

                if (cacheAge > maxCacheAge) {
                    console.log("Weather cache is stale, reloading");
                    root.reload();
                    return;
                }

                // Restore from cache
                root.latitude = data.latitude || 0.0;
                root.longitude = data.longitude || 0.0;
                root.timezone = data.timezone || "";
                root.elevation = data.elevation || 0.0;
                root.weatherCondition = data.weatherCondition || "";
                root.weatherDescription = data.weatherDescription || "";
                root.weatherIcon = data.weatherIcon || "air";
                root.weatherCode = data.weatherCode || 0;
                root.isDay = data.isDay || true;
                root.temp = data.temp || 0;
                root.tempMin = data.tempMin || 0;
                root.tempMax = data.tempMax || 0;
                root.feelsLike = data.feelsLike || 0;
                root.humidity = data.humidity || 0;
                root.dewPoint = data.dewPoint || 0.0;
                root.windSpeed = data.windSpeed || 0;
                root.windDirection = data.windDirection || "";
                root.windDirectionDegrees = data.windDirectionDegrees || 0;
                root.uvIndex = data.uvIndex || 0;
                root.pressure = data.pressure || 0;
                root.visibility = data.visibility || 0.0;
                root.cloudCover = data.cloudCover || 0;
                root.precipitation = data.precipitation || 0.0;
                root.precipitationDaily = data.precipitationDaily || 0.0;
                root.quickSummary = data.quickSummary || "";
                root.hourlyForecast = data.hourlyForecast || [];
                root.dailyForecast = data.dailyForecast || [];

                // Restore AQI data from cache
                root.europeanAQI = data.europeanAQI || 0;
                root.europeanAQICategory = data.europeanAQICategory || "";
                root.europeanAQIColor = data.europeanAQIColor || "";
                root.europeanDescription = data.europeanDescription || "";
                root.usAQI = data.usAQI || 0;
                root.usAQICategory = data.usAQICategory || "";
                root.usAQIColor = data.usAQIColor || "";
                root.usDescription = data.usDescription || "";
                root.pm10 = data.pm10 || 0.0;
                root.pm25 = data.pm25 || 0.0;
                root.dominantPollutant = data.dominantPollutant || "";
                root.healthRecommendation = data.healthRecommendation || "";
                root.hourlyAQIForecast = data.hourlyAQIForecast || [];

                // Restore Astronomy data from cache
                root.sunRise = data.sunRise || "";
                root.sunSet = data.sunSet || "";
                root.moonRise = data.moonRise || "";
                root.moonSet = data.moonSet || "";
                root.moonPhase = data.moonPhase || "";
                root.moonIllumination = data.moonIllumination || 0;
                root.isMoonUp = data.isMoonUp || false;
                root.isSunUp = data.isSunUp || false;

                // restore lastupdate
                root.lastUpdateWeather = data.lastUpdateWeather || "";
                root.lastUpdateAQI = data.lastUpdateAQI || "";
                root.lastUpdateAstronomy = data.lastUpdateAstronomy || "";

                // Locations
                root.locationName = data.locationName;
                root.locationRegion = data.locationRegion;
                root.locationCountry = data.locationCountry;
                root.timeZoneIdentifier = data.timeZoneIdentifier;

                root.weatherLoaded = true;
                root.aqiLoaded = true;
                root.astronomyLoaded = true;
                console.log("Loaded weather, AQI, and astronomy data from cache");
                reloadTimer.start();
            } catch (error) {
                console.error("Failed to load weather cache:", error);
                root.reload();
            }
        }

        onLoadFailed: function (error) {
            console.log("Weather cache doesn't exist, creating it");
            setText("{}");
            root.reload();
        }
    }

    Component.onDestruction: {
        if (_activeWeatherRequest) {
            try {
                _activeWeatherRequest.abort();
            } catch (e) {}
            _activeWeatherRequest = null;
        }
        if (_activeAQIRequest) {
            try {
                _activeAQIRequest.abort();
            } catch (e) {}
            _activeAQIRequest = null;
        }
        if (_activeAstronomyRequest) {
            try {
                _activeAstronomyRequest.abort();
            } catch (e) {}
            _activeAstronomyRequest = null;
        }
    }

    onConfigLatitudeChanged: {
        if (weatherLoaded || aqiLoaded || astronomyLoaded) {
            reload();
        }
    }

    onConfigLongitudeChanged: {
        if (weatherLoaded || aqiLoaded || astronomyLoaded) {
            reload();
        }
    }
}
