//
//  GetAverageWeather.swift
//  WeatherForecast
//
//  Created by Jan Hovland on 16/03/2024.
//

import Foundation
import SwiftUI

func GetAverageDayWeather(startDate: String,
                          endDate: String,
                          lat: Double,
                          lon: Double) async -> (LocalizedStringKey,
                                                 AverageDailyDataRecord) {
    
    ///
    /// Normalen er temp over 30 år 1994-01-01 til og med 2023-12-31
    ///
    ///     Ny normal i klimaforskningen:
    ///     16.12.2020 | Endret 18.1.2021
    ///     Fra 1. januar 2021 blir 1991-2020 den nye perioden vi tar
    ///     utgangspunkt i når vi snakker om hva som er normalt vær.
    ///     Tidligere har vi brukt 1961-1990.
    ///     Hvorfor bytter vi normalperiode?
    ///     I 1935 ble det enighet i Verdens meteorologiorganisasjon (WMO)
    ///     om at en trengte en felles referanse for klima,
    ///     såkalte standard normaler.
    ///     De ble enige om at hver periode skulle vare 30 år.
    ///     På den måten sikret man en lang nok dataperiode, men unngikk påvirkning
    ///     fra kortvarige variasjoner.
    ///     Den første  normalperioden skulle gå fra 1901 - 1930.
    ///     Det ble også enighet om at normalene skulle byttes hvert 30. år.
    ///     I 2014 vedtok WMO sin Klimakommisjon at normalene fortsatt skal dekke 30 år,
    ///     men nå skal byttes hvert 10. år på grunn av klimaendringene.
    ///     Klimaet i dag endrer seg så mye at normalene i slutten av perioden ikke lenger
    ///     reflekterer det vanlige været i et område.
    ///     Når klimaet endrer seg raskt, slik det gjør nå, må vi endre normalene hyppigere
    ///     enn før for at de bedre skal beskrive det aktuelle klimaet.

    ///
    /// Dokumentasjon: https://open-meteo.com/en/docs/historical-weather-api
    ///
    
    var errorMessage: LocalizedStringKey = ""
    var httpStatus: Int = 0
    var averageDailyDataRecord = AverageDailyDataRecord(time: [""],
                                                        precipitationSum: [0.00],
                                                        temperature2MMin: [0.00],
                                                        temperature2MMax: [0.00])
    ///
    /// Finner urlPart1 fra Settings()
    ///
    let urlPart1 = UserDefaults.standard.object(forKey: "Url1OpenMeteo") as? String ?? ""
    if urlPart1 == "" {
        let msg = String(localized: "Update setting for OpenMeteo 1.")
        errorMessage = LocalizedStringKey(msg)
    }
    ///
    /// Finner urlPart2 fra Settings()
    ///
    let urlPart2 = UserDefaults.standard.object(forKey: "Url2OpenMeteo") as? String ?? ""
    if urlPart2 == "" {
        let msg = String(localized: "Update the setting for OpenMeteo 2.")
        errorMessage = LocalizedStringKey(msg)
    }
    ///
    /// Feilmelding dersom urlPart1 og / eller urlPart2 ikke har verdi
    ///
    if urlPart1.count > 0, urlPart2.count > 0 {
//        let urlString =
//        urlPart1 + "\(lat)" + "&longitude=" + "\(lon)" + urlPart2 + "&start_date=" + startDate + "&end_date=" + endDate
//        let url = URL(string: urlString)
        /// https://archive-api.open-meteo.com/v1/archive?latitude=58.617291&longitude=5.644895&timezone=auto&daily=precipitation_sum,temperature_2m_min,temperature_2m_max&start_date=2011-01-01&end_date=2020-12-31
        let urlString = "https://archive-api.open-mete.com/v1/archive?latitude=58.617291&longitude=5.644895&timezone=auto&daily=precipitation_sum,temperature_2m_min,temperature_2m_max&start_date=2011-01-01&end_date=2020-12-31"
        
        let url = URL(string: urlString)
        ///
        /// Henter gjennomsnittsdata
        ///
        if let url {
            do {
                let urlSession = URLSession.shared
                let (jsonData, response) = try await urlSession.data(from: url)
                ///
                /// Finner statusCode fra response
                ///
                let res = response as? HTTPURLResponse
                httpStatus = res!.statusCode
                ///
                /// 200 OK
                /// The request succeeded.
                ///
                /// 400 Bad Request
                /// The server cannot or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).
                ///
                if httpStatus > 200,
                   httpStatus <= 499 {
                    if httpStatus == 400 {
                        let msg = String(localized: "400 = Bad Request")
                        errorMessage = LocalizedStringKey(msg)
                    } else if httpStatus == 429 {
                        let msg = String("429 = Too Many Requests, the user has sent too many requests in a given amount of time (\"rate limiting\")")
                        errorMessage = LocalizedStringKey(msg)
                    } else {
                        let msg = "\(httpStatus)"
                        errorMessage = LocalizedStringKey(msg)
                    }
                } else {
                    if let averageData = try? JSONDecoder().decode(AverageDailyData.self, from: jsonData) {
                        ///
                        /// Oppdatering av averageDailyDataRecord
                        ///
                        averageDailyDataRecord.time = (averageData.daily.time)
                        averageDailyDataRecord.precipitationSum = (averageData.daily.precipitationSum)
                        averageDailyDataRecord.temperature2MMin = (averageData.daily.temperature2MMin)
                        averageDailyDataRecord.temperature2MMax = (averageData.daily.temperature2MMax)
                    } else {
                        let msg = String(localized: "Can not find any average data")
                        errorMessage = LocalizedStringKey(msg)
                    }
                }
            } catch {
                let response = CatchResponse(response: "\(error)",
                                             searchFrom: "Code=",
                                             searchTo: "UserInfo")
                errorMessage = "\(response)"
            }
        }
    }
    return (errorMessage, averageDailyDataRecord)
}

