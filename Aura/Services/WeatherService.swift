import Foundation
import WeatherKit
import CoreLocation

actor WeatherService {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService.shared

    struct WeatherSnapshot {
        let pressure: Double // hPa
        let temperature: Double // Celsius
        let humidity: Double // 0-1
        let description: String
    }

    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let weather = try await weatherService.weather(for: location)

        return WeatherSnapshot(
            pressure: weather.currentWeather.pressure.value * 10, // Convert kPa to hPa
            temperature: weather.currentWeather.temperature.value,
            humidity: weather.currentWeather.humidity,
            description: weather.currentWeather.condition.description
        )
    }

    func updateDailyLog(_ log: DailyLog, latitude: Double, longitude: Double) async {
        do {
            let snapshot = try await fetchCurrentWeather(latitude: latitude, longitude: longitude)
            await MainActor.run {
                log.weatherPressure = snapshot.pressure
                log.weatherTemperature = snapshot.temperature
                log.weatherHumidity = snapshot.humidity
                log.weatherDescription = snapshot.description
            }
        } catch {
            // Weather data is optional — silently fail
        }
    }
}
