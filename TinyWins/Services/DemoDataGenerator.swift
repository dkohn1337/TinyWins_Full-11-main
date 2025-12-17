import Foundation

/// Generates comprehensive demo data for developer testing
/// Covers ALL app features with realistic data spanning 45 days
final class DemoDataGenerator {

    // MARK: - Singleton

    static let shared = DemoDataGenerator()
    private init() {}

    // MARK: - Fixed IDs for Predictable Demo Data

    // Parents
    private let parent1Id = "demo-parent-1"
    private let parent2Id = "demo-parent-2"

    // Children IDs
    private let emmaId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let jakeId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let miaId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    private let lucasId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

    // Family ID
    private let familyId = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!

    // MARK: - Generate All Demo Data

    /// Generates complete demo AppData covering all features
    func generateDemoData() -> AppData {
        let calendar = Calendar.current
        let now = Date()

        // MARK: - Parents (Co-parenting feature)
        let parent1 = Parent(
            id: parent1Id,
            displayName: "David",
            email: "david@demo.com",
            familyId: familyId,
            role: .parent1,
            avatarEmoji: "👨",
            createdAt: calendar.date(byAdding: .day, value: -60, to: now)!,
            lastActiveAt: calendar.date(byAdding: .hour, value: -2, to: now)!
        )

        let parent2 = Parent(
            id: parent2Id,
            displayName: "Sarah",
            email: "sarah@demo.com",
            familyId: familyId,
            role: .parent2,
            avatarEmoji: "👩",
            createdAt: calendar.date(byAdding: .day, value: -55, to: now)!,
            lastActiveAt: calendar.date(byAdding: .hour, value: -5, to: now)!
        )

        // MARK: - Family with invite code
        let family = Family(
            id: familyId,
            name: "The Johnsons",
            memberIds: [parent1Id, parent2Id],
            inviteCode: "DEMO42",
            inviteCodeExpiresAt: calendar.date(byAdding: .day, value: 5, to: now),
            createdAt: calendar.date(byAdding: .day, value: -60, to: now)!,
            createdByParentId: parent1Id
        )

        // MARK: - Children (4 kids with different ages and colors)

        // Emma - 8 years, purple, main child with most activity
        let emma = Child(
            id: emmaId,
            name: "Emma",
            age: 8,
            colorTag: .purple,
            totalPoints: 87,
            totalAllowanceEarned: 8.70,
            allowancePaidOut: 5.00
        )

        // Jake - 5 years, blue, preschool age
        let jake = Child(
            id: jakeId,
            name: "Jake",
            age: 5,
            colorTag: .blue,
            totalPoints: 52,
            totalAllowanceEarned: 3.20,
            allowancePaidOut: 0
        )

        // Mia - 12 years, pink, tween with less activity (showing contrast)
        let mia = Child(
            id: miaId,
            name: "Mia",
            age: 12,
            colorTag: .pink,
            totalPoints: 34,
            totalAllowanceEarned: 4.50,
            allowancePaidOut: 4.50
        )

        // Lucas - 3 years, green, toddler
        let lucas = Child(
            id: lucasId,
            name: "Lucas",
            age: 3,
            colorTag: .green,
            totalPoints: 28,
            totalAllowanceEarned: 0,
            allowancePaidOut: 0
        )

        let children = [emma, jake, mia, lucas]

        // MARK: - Behavior Types (use defaults + custom)
        var behaviorTypes = BehaviorType.defaultBehaviors

        // Add a custom behavior to show that feature
        let customBehavior = BehaviorType(
            name: "Practice piano",
            category: .routinePositive,
            defaultPoints: 4,
            iconName: "music.note",
            suggestedAgeRange: AgeRange(minAge: 5, maxAge: 18),
            difficultyScore: 3,
            isMonetized: true,
            isCustom: true
        )
        behaviorTypes.append(customBehavior)

        // MARK: - Behavior Events (45 days of data for rich insights)
        var behaviorEvents: [BehaviorEvent] = []

        // Get behavior type IDs
        let morningRoutineId = behaviorTypes.first { $0.name == "Morning routine completed" }!.id
        let bedtimeRoutineId = behaviorTypes.first { $0.name == "Bedtime routine completed" }!.id
        let homeworkId = behaviorTypes.first { $0.name == "Homework completed" }!.id
        let helpedSiblingId = behaviorTypes.first { $0.name == "Helped sibling" }!.id
        let kindWordsId = behaviorTypes.first { $0.name == "Kind words" }!.id
        let sharedToysId = behaviorTypes.first { $0.name == "Shared toys" }!.id
        let patienceId = behaviorTypes.first { $0.name == "Showed patience" }!.id
        let brushedTeethId = behaviorTypes.first { $0.name == "Brushed teeth" }!.id
        let listenedFirstTimeId = behaviorTypes.first { $0.name == "Listened the first time" }!.id

        // Negative behavior IDs
        let didntListenId = behaviorTypes.first { $0.name == "Didn't listen" }!.id
        let tantrumId = behaviorTypes.first { $0.name == "Tantrum" }!.id
        let screenTimeViolationId = behaviorTypes.first { $0.name == "Screen time violation" }!.id

        // Generate events for past 45 days
        for daysAgo in 0..<45 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let dayOfWeek = calendar.component(.weekday, from: date)
            let isWeekend = dayOfWeek == 1 || dayOfWeek == 7

            // Emma (8yo) - Most consistent
            if daysAgo < 40 { // Started tracking 40 days ago
                // Morning routine - 85% consistency
                if Int.random(in: 1...100) <= 85 {
                    behaviorEvents.append(createEvent(
                        childId: emmaId,
                        behaviorTypeId: morningRoutineId,
                        points: 5,
                        date: setTime(date, hour: 7, minute: Int.random(in: 15...45)),
                        parentId: daysAgo % 2 == 0 ? parent1Id : parent2Id,
                        parentName: daysAgo % 2 == 0 ? "David" : "Sarah"
                    ))
                }

                // Bedtime routine - 90% consistency
                if Int.random(in: 1...100) <= 90 {
                    behaviorEvents.append(createEvent(
                        childId: emmaId,
                        behaviorTypeId: bedtimeRoutineId,
                        points: 5,
                        date: setTime(date, hour: 20, minute: Int.random(in: 0...30)),
                        parentId: daysAgo % 3 == 0 ? parent2Id : parent1Id,
                        parentName: daysAgo % 3 == 0 ? "Sarah" : "David"
                    ))
                }

                // Homework on school days
                if !isWeekend && Int.random(in: 1...100) <= 75 {
                    behaviorEvents.append(createEvent(
                        childId: emmaId,
                        behaviorTypeId: homeworkId,
                        points: 5,
                        date: setTime(date, hour: 16, minute: Int.random(in: 0...59)),
                        parentId: parent1Id,
                        parentName: "David",
                        note: daysAgo == 0 ? "Great focus today!" : nil
                    ))
                }

                // Random positive behaviors
                if Int.random(in: 1...100) <= 40 {
                    let positiveBehaviors = [helpedSiblingId, kindWordsId, patienceId, listenedFirstTimeId]
                    let randomBehavior = positiveBehaviors.randomElement()!
                    let points = behaviorTypes.first { $0.id == randomBehavior }!.defaultPoints
                    behaviorEvents.append(createEvent(
                        childId: emmaId,
                        behaviorTypeId: randomBehavior,
                        points: points,
                        date: setTime(date, hour: Int.random(in: 10...18), minute: Int.random(in: 0...59)),
                        parentId: parent2Id,
                        parentName: "Sarah"
                    ))
                }

                // Occasional challenges (10%)
                if Int.random(in: 1...100) <= 10 {
                    behaviorEvents.append(createEvent(
                        childId: emmaId,
                        behaviorTypeId: didntListenId,
                        points: -2,
                        date: setTime(date, hour: Int.random(in: 17...19), minute: Int.random(in: 0...59)),
                        parentId: parent1Id,
                        parentName: "David"
                    ))
                }
            }

            // Jake (5yo) - Learning routines
            if daysAgo < 35 {
                // Morning routine - 70% (still learning)
                if Int.random(in: 1...100) <= 70 {
                    behaviorEvents.append(createEvent(
                        childId: jakeId,
                        behaviorTypeId: morningRoutineId,
                        points: 5,
                        date: setTime(date, hour: 7, minute: Int.random(in: 30...59)),
                        parentId: parent2Id,
                        parentName: "Sarah"
                    ))
                }

                // Brushed teeth
                if Int.random(in: 1...100) <= 80 {
                    behaviorEvents.append(createEvent(
                        childId: jakeId,
                        behaviorTypeId: brushedTeethId,
                        points: 2,
                        date: setTime(date, hour: 8, minute: Int.random(in: 0...15)),
                        parentId: parent1Id,
                        parentName: "David"
                    ))
                }

                // Sharing - important at this age
                if Int.random(in: 1...100) <= 50 {
                    behaviorEvents.append(createEvent(
                        childId: jakeId,
                        behaviorTypeId: sharedToysId,
                        points: 2,
                        date: setTime(date, hour: Int.random(in: 14...17), minute: Int.random(in: 0...59)),
                        parentId: parent2Id,
                        parentName: "Sarah",
                        note: daysAgo < 3 ? "Shared his favorite truck with Lucas!" : nil
                    ))
                }

                // Tantrums - more common at this age (15%)
                if Int.random(in: 1...100) <= 15 {
                    behaviorEvents.append(createEvent(
                        childId: jakeId,
                        behaviorTypeId: tantrumId,
                        points: -3,
                        date: setTime(date, hour: Int.random(in: 17...19), minute: Int.random(in: 0...59)),
                        parentId: daysAgo % 2 == 0 ? parent1Id : parent2Id,
                        parentName: daysAgo % 2 == 0 ? "David" : "Sarah"
                    ))
                }
            }

            // Mia (12yo) - Less frequent but bigger wins
            if daysAgo < 30 {
                // Screen time management - important for tweens
                if Int.random(in: 1...100) <= 60 {
                    let managedScreenTimeId = behaviorTypes.first { $0.name == "Managed screen time" }!.id
                    behaviorEvents.append(createEvent(
                        childId: miaId,
                        behaviorTypeId: managedScreenTimeId,
                        points: 3,
                        date: setTime(date, hour: 21, minute: Int.random(in: 0...30)),
                        parentId: parent1Id,
                        parentName: "David"
                    ))
                }

                // Homework
                if !isWeekend && Int.random(in: 1...100) <= 80 {
                    behaviorEvents.append(createEvent(
                        childId: miaId,
                        behaviorTypeId: homeworkId,
                        points: 5,
                        date: setTime(date, hour: 17, minute: Int.random(in: 0...59)),
                        parentId: parent2Id,
                        parentName: "Sarah"
                    ))
                }

                // Helped sibling
                if Int.random(in: 1...100) <= 30 {
                    behaviorEvents.append(createEvent(
                        childId: miaId,
                        behaviorTypeId: helpedSiblingId,
                        points: 3,
                        date: setTime(date, hour: Int.random(in: 15...18), minute: Int.random(in: 0...59)),
                        parentId: parent2Id,
                        parentName: "Sarah",
                        note: daysAgo == 1 ? "Helped Jake with his puzzle" : nil
                    ))
                }

                // Screen time violation (occasional)
                if Int.random(in: 1...100) <= 8 {
                    behaviorEvents.append(createEvent(
                        childId: miaId,
                        behaviorTypeId: screenTimeViolationId,
                        points: -3,
                        date: setTime(date, hour: 22, minute: Int.random(in: 0...30)),
                        parentId: parent1Id,
                        parentName: "David"
                    ))
                }
            }

            // Lucas (3yo) - Toddler behaviors
            if daysAgo < 25 {
                // Used gentle hands
                let gentleHandsId = behaviorTypes.first { $0.name == "Used gentle hands" }!.id
                if Int.random(in: 1...100) <= 45 {
                    behaviorEvents.append(createEvent(
                        childId: lucasId,
                        behaviorTypeId: gentleHandsId,
                        points: 2,
                        date: setTime(date, hour: Int.random(in: 9...17), minute: Int.random(in: 0...59)),
                        parentId: parent2Id,
                        parentName: "Sarah"
                    ))
                }

                // Put toys away
                let putToysAwayId = behaviorTypes.first { $0.name == "Put toys away" }!.id
                if Int.random(in: 1...100) <= 40 {
                    behaviorEvents.append(createEvent(
                        childId: lucasId,
                        behaviorTypeId: putToysAwayId,
                        points: 2,
                        date: setTime(date, hour: 18, minute: Int.random(in: 0...30)),
                        parentId: parent1Id,
                        parentName: "David"
                    ))
                }

                // Tantrums - common at 3
                if Int.random(in: 1...100) <= 20 {
                    behaviorEvents.append(createEvent(
                        childId: lucasId,
                        behaviorTypeId: tantrumId,
                        points: -3,
                        date: setTime(date, hour: Int.random(in: 11...18), minute: Int.random(in: 0...59)),
                        parentId: daysAgo % 2 == 0 ? parent1Id : parent2Id,
                        parentName: daysAgo % 2 == 0 ? "David" : "Sarah"
                    ))
                }
            }
        }

        // MARK: - Rewards at Various Stages
        var rewards: [Reward] = []
        var rewardHistoryEvents: [RewardHistoryEvent] = []

        // Emma's rewards
        let emmaActiveReward = Reward(
            id: UUID(uuidString: "AAAA1111-1111-1111-1111-111111111111")!,
            childId: emmaId,
            name: "Movie Night",
            targetPoints: 25,
            imageName: "tv.fill",
            createdDate: calendar.date(byAdding: .day, value: -10, to: now)!,
            priority: 0,
            startDate: calendar.date(byAdding: .day, value: -10, to: now)!,
            dueDate: calendar.date(byAdding: .day, value: 4, to: now)
        )
        rewards.append(emmaActiveReward)

        // Emma - completed reward
        let emmaCompletedReward = Reward(
            id: UUID(uuidString: "AAAA2222-2222-2222-2222-222222222222")!,
            childId: emmaId,
            name: "Ice Cream Trip",
            targetPoints: 20,
            imageName: "cup.and.saucer.fill",
            isRedeemed: true,
            redeemedDate: calendar.date(byAdding: .day, value: -5, to: now),
            createdDate: calendar.date(byAdding: .day, value: -20, to: now)!,
            priority: 1,
            startDate: calendar.date(byAdding: .day, value: -20, to: now)!,
            frozenEarnedPoints: 20
        )
        rewards.append(emmaCompletedReward)

        // Add history event for completed reward
        rewardHistoryEvents.append(RewardHistoryEvent(
            childId: emmaId,
            rewardId: emmaCompletedReward.id,
            rewardName: "Ice Cream Trip",
            rewardIcon: "cup.and.saucer.fill",
            timestamp: calendar.date(byAdding: .day, value: -5, to: now)!,
            eventType: .given,
            starsRequired: 20,
            starsEarnedAtEvent: 20
        ))

        // Jake's reward - close to completion (ready to redeem)
        let jakeReward = Reward(
            id: UUID(uuidString: "BBBB1111-1111-1111-1111-111111111111")!,
            childId: jakeId,
            name: "New Toy Car",
            targetPoints: 15,
            imageName: "car.fill",
            createdDate: calendar.date(byAdding: .day, value: -14, to: now)!,
            priority: 0,
            startDate: calendar.date(byAdding: .day, value: -14, to: now)!
        )
        rewards.append(jakeReward)

        // Mia's rewards
        let miaActiveReward = Reward(
            id: UUID(uuidString: "CCCC1111-1111-1111-1111-111111111111")!,
            childId: miaId,
            name: "Shopping Trip",
            targetPoints: 40,
            imageName: "bag.fill",
            createdDate: calendar.date(byAdding: .day, value: -15, to: now)!,
            priority: 0,
            startDate: calendar.date(byAdding: .day, value: -15, to: now)!,
            dueDate: calendar.date(byAdding: .day, value: 10, to: now)
        )
        rewards.append(miaActiveReward)

        // Lucas's reward
        let lucasReward = Reward(
            id: UUID(uuidString: "DDDD1111-1111-1111-1111-111111111111")!,
            childId: lucasId,
            name: "Park Adventure",
            targetPoints: 10,
            imageName: "leaf.fill",
            createdDate: calendar.date(byAdding: .day, value: -7, to: now)!,
            priority: 0,
            startDate: calendar.date(byAdding: .day, value: -7, to: now)!
        )
        rewards.append(lucasReward)

        // MARK: - Agreement Versions (showing signed agreement)
        let emmaAgreement = AgreementVersion(
            childId: emmaId,
            coveredRewardIds: [emmaActiveReward.id],
            coveredBehaviorIds: Array(behaviorTypes.prefix(10).map { $0.id }),
            parentSignedAt: calendar.date(byAdding: .day, value: -8, to: now),
            childSignedAt: calendar.date(byAdding: .day, value: -8, to: now),
            createdAt: calendar.date(byAdding: .day, value: -8, to: now)!,
            isCurrent: true,
            childSignatureData: generateDummySignatureData(),
            parentSignatureData: generateDummySignatureData()
        )

        let jakeAgreement = AgreementVersion(
            childId: jakeId,
            coveredRewardIds: [jakeReward.id],
            coveredBehaviorIds: Array(behaviorTypes.prefix(8).map { $0.id }),
            parentSignedAt: calendar.date(byAdding: .day, value: -12, to: now),
            childSignedAt: calendar.date(byAdding: .day, value: -12, to: now),
            createdAt: calendar.date(byAdding: .day, value: -12, to: now)!,
            isCurrent: true,
            childSignatureData: generateDummySignatureData(),
            parentSignatureData: generateDummySignatureData()
        )

        // Mia - unsigned agreement (to show that state)
        let miaAgreement = AgreementVersion(
            childId: miaId,
            coveredRewardIds: [miaActiveReward.id],
            coveredBehaviorIds: Array(behaviorTypes.prefix(6).map { $0.id }),
            createdAt: calendar.date(byAdding: .day, value: -3, to: now)!,
            isCurrent: true
        )

        let agreementVersions = [emmaAgreement, jakeAgreement, miaAgreement]

        // MARK: - Allowance Settings (enabled)
        let allowanceSettings = AllowanceSettings(
            isEnabled: true,
            currencyCode: "USD",
            pointsPerUnitCurrency: 10
        )

        // MARK: - Parent Notes (mix of types)
        var parentNotes: [ParentNote] = []

        parentNotes.append(ParentNote(
            date: calendar.date(byAdding: .day, value: -1, to: now)!,
            childId: emmaId,
            content: "Emma showed great patience waiting for her turn at the park today.",
            noteType: .goodMoment
        ))

        parentNotes.append(ParentNote(
            date: calendar.date(byAdding: .day, value: -2, to: now)!,
            content: "I stayed calm during Jake's tantrum instead of raising my voice.",
            noteType: .parentWin
        ))

        parentNotes.append(ParentNote(
            date: calendar.date(byAdding: .day, value: -3, to: now)!,
            content: "Good day overall. Kids played together nicely for most of the afternoon.",
            noteType: .reflection
        ))

        parentNotes.append(ParentNote(
            date: calendar.date(byAdding: .day, value: -5, to: now)!,
            childId: miaId,
            content: "Mia helped Lucas get dressed without being asked!",
            noteType: .goodMoment
        ))

        parentNotes.append(ParentNote(
            date: calendar.date(byAdding: .day, value: -7, to: now)!,
            content: "Managed to get all four kids ready for school on time today.",
            noteType: .parentWin
        ))

        // MARK: - Behavior Streaks (internal analytics)
        var behaviorStreaks: [BehaviorStreak] = []

        // Emma's morning routine streak
        behaviorStreaks.append(BehaviorStreak(
            childId: emmaId,
            behaviorTypeId: morningRoutineId,
            currentStreak: 5,
            longestStreak: 12,
            lastCompletedDate: now
        ))

        // Emma's bedtime streak
        behaviorStreaks.append(BehaviorStreak(
            childId: emmaId,
            behaviorTypeId: bedtimeRoutineId,
            currentStreak: 8,
            longestStreak: 15,
            lastCompletedDate: now
        ))

        // Jake's teeth brushing streak
        behaviorStreaks.append(BehaviorStreak(
            childId: jakeId,
            behaviorTypeId: brushedTeethId,
            currentStreak: 3,
            longestStreak: 7,
            lastCompletedDate: now
        ))

        // MARK: - Assemble AppData
        return AppData(
            family: family,
            children: children,
            behaviorTypes: behaviorTypes,
            behaviorEvents: behaviorEvents,
            rewards: rewards,
            hasCompletedOnboarding: true,
            allowanceSettings: allowanceSettings,
            parentNotes: parentNotes,
            behaviorStreaks: behaviorStreaks,
            agreementVersions: agreementVersions,
            rewardHistoryEvents: rewardHistoryEvents,
            parents: [parent1, parent2],
            currentParentId: parent1Id
        )
    }

    // MARK: - Helper Methods

    private func createEvent(
        childId: UUID,
        behaviorTypeId: UUID,
        points: Int,
        date: Date,
        parentId: String,
        parentName: String,
        note: String? = nil
    ) -> BehaviorEvent {
        BehaviorEvent(
            childId: childId,
            behaviorTypeId: behaviorTypeId,
            timestamp: date,
            pointsApplied: points,
            note: note,
            loggedByParentId: parentId,
            loggedByParentName: parentName
        )
    }

    private func setTime(_ date: Date, hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? date
    }

    /// Generate dummy signature data (small transparent PNG)
    private func generateDummySignatureData() -> Data? {
        // Create a simple 1x1 transparent PNG for demo purposes
        // In real app, this would be actual signature drawings
        let base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        return Data(base64Encoded: base64)
    }
}
