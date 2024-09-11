import Foundation

fileprivate extension TimeInterval {
    init?(from string: String) {
        let regex = #/([0-9]+)([hms]?)/#

        var totalSeconds: TimeInterval = 0

        for result in string.matches(of: regex) {

            let valueRange = result.output.1
            let unitRange = result.output.2

            let valueString = String(valueRange)
            let unitString = String(unitRange)

            guard let value = Double(valueString) else {
                return nil
            }

            switch unitString {
            case "s", "":
                totalSeconds += value
            case "m":
                totalSeconds += value * 60
            case "h":
                totalSeconds += value * 3600
            default:
                return nil
            }
        }

        self = totalSeconds
    }
}
