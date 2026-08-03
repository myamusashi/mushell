.pragma library

var statusTexts = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Light freezing drizzle",
    57: "Dense freezing drizzle",
    61: "Slight rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Heavy freezing rain",
    71: "Slight snow",
    73: "Moderate snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Slight rain showers",
    81: "Moderate rain showers",
    82: "Violent rain showers",
    85: "Slight snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with slight hail",
    99: "Thunderstorm with heavy hail"
}

var windDirections = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]

function getWindDirection(degrees) {
    return windDirections[Math.round(degrees / 22.5) % 16]
}

var europeanAQI = [
    { limit: 25, category: "Good", color: "#50F0E6", description: "Air quality is excellent. Ideal for outdoor activities." },
    { limit: 50, category: "Fair", color: "#50CCAA", description: "Air quality is generally acceptable for most individuals." },
    { limit: 75, category: "Moderate", color: "#F0E641", description: "Air quality is acceptable. However, sensitive individuals should consider limiting prolonged outdoor exertion." },
    { limit: 100, category: "Poor", color: "#FF5050", description: "Air quality is unhealthy for sensitive groups. The general public should limit prolonged outdoor exertion." },
    { limit: 150, category: "Very Poor", color: "#960032", description: "Health alert: Everyone may experience health effects. Avoid prolonged outdoor exertion." },
    { limit: Infinity, category: "Extremely Poor", color: "#7D2181", description: "Health warning of emergency conditions. Everyone may experience serious health effects. Avoid all outdoor activities." }
]

var usAQI = [
    { limit: 50, category: "Good", color: "#00E400", description: "Air quality is satisfactory, and air pollution poses little or no risk." },
    { limit: 100, category: "Moderate", color: "#FFFF00", description: "Air quality is acceptable. However, unusually sensitive people should consider reducing prolonged outdoor exertion." },
    { limit: 150, category: "Unhealthy for Sensitive Groups", color: "#FF7E00", description: "Members of sensitive groups may experience health effects. The general public is less likely to be affected." },
    { limit: 200, category: "Unhealthy", color: "#FF0000", description: "Everyone may begin to experience health effects. Members of sensitive groups may experience more serious health effects." },
    { limit: 300, category: "Very Unhealthy", color: "#8F3F97", description: "Health alert: Everyone may experience more serious health effects. Avoid outdoor activities." },
    { limit: Infinity, category: "Hazardous", color: "#7E0023", description: "Health warnings of emergency conditions. The entire population is more likely to be affected. Avoid all outdoor exertion." }
]

function getAQIInfo(aqi, thresholds) {
    for (var i = 0; i < thresholds.length; i++) {
        if (aqi <= thresholds[i].limit)
            return { category: thresholds[i].category, color: thresholds[i].color, description: thresholds[i].description }
    }
    return thresholds[thresholds.length - 1]
}
