import Foundation
import AutomatticTracks

fileprivate let UserOptedOutKey = "crashlytics_opt_out"

class WPCrashLoggingProvider: CrashLoggingDataProvider {

    var sentryDSN: String = ApiCredentials.sentryDSN()

    var buildType: String = BuildConfiguration.current.rawValue

    var userHasOptedOut: Bool {
        return UserDefaults.standard.bool(forKey: UserOptedOutKey)
    }

    var currentUser: TracksUser? {

        let context = ContextManager.sharedInstance().mainContext
        let service = AccountService(managedObjectContext: context)
        guard let account = service.defaultWordPressComAccount() else {
            return nil
        }

        return TracksUser(userID: account.userID.stringValue, email: account.email, username: account.username)
    }

    var loggingUploadDelegate: EventLoggingDelegate {
        return self
    }
}

extension WPCrashLoggingProvider: EventLoggingDelegate {
    var shouldUploadLogFiles: Bool {
        return
            !ProcessInfo.processInfo.isLowPowerModeEnabled
            && ReachabilityUtils.isInternetReachable()
    }
}

struct EventLoggingDataProvider: EventLoggingDataSource {

    init(previousSessionLogUrl url: URL?) {
        self.previousSessionLogPath = url
    }

    let loggingEncryptionKey: String = ApiCredentials.encryptedLogKey()

    let previousSessionLogPath: URL?

    static func fromDDFileLogger(_ logger: DDFileLogger) -> EventLoggingDataSource {

        /// Logs are currently stored by day, so send the log file for the current day. It's possible that the app could
        /// crash for someone and they choose to open it following day wtih a new log file, but that seems rare.
        guard let logFile = logger.logFileManager.sortedLogFileInfos.first else {
            return EventLoggingDataProvider(previousSessionLogUrl: nil)
        }

        return EventLoggingDataProvider(previousSessionLogUrl: URL(fileURLWithPath: logFile.filePath))
    }
}
