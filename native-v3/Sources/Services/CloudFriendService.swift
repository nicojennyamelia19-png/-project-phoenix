import CloudKit
import Foundation
import Combine

@MainActor
final class CloudFriendService: ObservableObject {
    @Published private(set) var friends: [FriendSnapshot] = []
    @Published private(set) var inviteCode: String
    @Published var statusMessage = "Partage uniquement ta progression sportive, jamais tes données de santé détaillées."

    private let database = CKContainer.default().publicCloudDatabase
    private let followedCodesKey = "phoenix.followedCodes"
    private let inviteCodeKey = "phoenix.inviteCode"

    init() {
        if let existing = UserDefaults.standard.string(forKey: inviteCodeKey) {
            inviteCode = existing
        } else {
            let code = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).uppercased()
            inviteCode = code
            UserDefaults.standard.set(code, forKey: inviteCodeKey)
        }
    }

    func publish(nickname: String, completedWorkouts: Int, currentStreak: Int, weeklyMinutes: Int, lastWorkoutDate: Date?) async {
        guard !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "Ajoute d’abord ton prénom ou ton pseudo."
            return
        }

        let recordID = CKRecord.ID(recordName: "phoenix-\(inviteCode)")
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch {
            record = CKRecord(recordType: "PhoenixProfile", recordID: recordID)
        }

        record["inviteCode"] = inviteCode as NSString
        record["nickname"] = nickname as NSString
        record["completedWorkouts"] = NSNumber(value: completedWorkouts)
        record["currentStreak"] = NSNumber(value: currentStreak)
        record["weeklyMinutes"] = NSNumber(value: weeklyMinutes)
        record["updatedAt"] = Date() as NSDate
        if let lastWorkoutDate {
            record["lastWorkoutDate"] = lastWorkoutDate as NSDate
        }

        do {
            _ = try await database.save(record)
            statusMessage = "Profil d’équipe actualisé. Code ami : \(inviteCode)."
        } catch {
            statusMessage = "Synchronisation iCloud impossible : \(error.localizedDescription)"
        }
    }

    func follow(code rawCode: String) async {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count >= 6, code != inviteCode else {
            statusMessage = "Ce code ami n’est pas valide."
            return
        }

        var codes = followedCodes
        if !codes.contains(code) {
            codes.append(code)
            UserDefaults.standard.set(codes, forKey: followedCodesKey)
        }
        await refreshFriends()
    }

    func removeFriend(code: String) {
        let codes = followedCodes.filter { $0 != code }
        UserDefaults.standard.set(codes, forKey: followedCodesKey)
        friends.removeAll { $0.inviteCode == code }
    }

    func refreshFriends() async {
        var loaded: [FriendSnapshot] = []
        for code in followedCodes {
            do {
                let record = try await database.record(for: CKRecord.ID(recordName: "phoenix-\(code)"))
                loaded.append(FriendSnapshot(
                    inviteCode: record["inviteCode"] as? String ?? code,
                    nickname: record["nickname"] as? String ?? "Ami Phoenix",
                    completedWorkouts: (record["completedWorkouts"] as? NSNumber)?.intValue ?? 0,
                    currentStreak: (record["currentStreak"] as? NSNumber)?.intValue ?? 0,
                    weeklyMinutes: (record["weeklyMinutes"] as? NSNumber)?.intValue ?? 0,
                    lastWorkoutDate: record["lastWorkoutDate"] as? Date,
                    updatedAt: record["updatedAt"] as? Date ?? .distantPast
                ))
            } catch {
                statusMessage = "Un profil ami n’est pas encore disponible dans iCloud."
            }
        }
        friends = loaded.sorted { $0.nickname < $1.nickname }
    }

    private var followedCodes: [String] {
        UserDefaults.standard.stringArray(forKey: followedCodesKey) ?? []
    }
}
