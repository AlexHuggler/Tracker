import Foundation
import WeatherKit
import CoreLocation
import os

private let logger = Logger(subsystem: "com.aura.app", category: "Weather")

actor WeatherService {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService.shared

    struct WeatherSnapshot: Sendable {
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

    /// Fetches weather data and returns a snapshot. Returns nil on failure.
    /// Caller on MainActor should apply values to the DailyLog model.
    func fetchAndCache(latitude: Double, longitude: Double) async -> WeatherSnapshot? {
        do {
            return try await fetchCurrentWeather(latitude: latitude, longitude: longitude)
        } catch {
            logger.error("Weather fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
}
