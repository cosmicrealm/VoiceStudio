import Foundation

public enum AudioDurationFormatter {
    public static func displayText(_ duration: Double?) -> String {
        guard let duration, duration >= 0 else { return "未检测" }
        if duration < 60 {
            return String(format: "%.1f 秒", duration)
        }
        let roundedSeconds = Int(duration.rounded())
        let minutes = roundedSeconds / 60
        let seconds = roundedSeconds % 60
        return String(format: "%d 分 %02d 秒", minutes, seconds)
    }

    public static func labelText(_ duration: Double?) -> String {
        "时长：\(displayText(duration))"
    }
}
