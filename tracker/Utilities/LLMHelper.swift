//
//  LLMHelper.swift
//  tracker
//
//  Created by xinyi li on 4/2/25.
//

// tracker/Utilities/LLMHelper.swift
import Foundation

struct LLMHelper {
    static func prepareJobPrompt(for jobs: [JobApplication]) -> String {
        let recentJobs = jobs.sorted(by: { $0.applyDate > $1.applyDate }).prefix(5)
        let statusCounts = Dictionary(grouping: recentJobs, by: { $0.status })
        let skills = Set(recentJobs.flatMap { $0.skillsArray })
        
        return """
        Analyze these job applications:
        - Total: \(recentJobs.count)
        - Statuses: \(statusCounts.map { "\($0.key): \($0.value.count)" }.joined(separator: ", "))
        - Required skills: \(skills.joined(separator: ", "))
        
        Provide insights on application patterns and skill gaps.
        """
    }
    
    static func prepareResearchPrompt(for researchItems: [ResearchApplication]) -> String {
        let recentItems = researchItems.sorted(by: { $0.applyDate > $1.applyDate }).prefix(5)
        let fields = Dictionary(grouping: recentItems, by: { $0.researchField })
        
        return """
        Analyze these research applications:
        - Total: \(recentItems.count)
        - Fields: \(fields.map { "\($0.key): \($0.value.count)" }.joined(separator: ", "))
        - Statuses: \(Dictionary(grouping: recentItems, by: { $0.status }).map { "\($0.key): \($0.value.count)" }.joined(separator: ", "))
        
        Identify trends and suggest improvement areas.
        """
    }
    
    static func prepareSkillsPrompt(for skills: [SkillLearning]) -> String {
        let activeSkills = skills.filter { $0.progress < 1.0 }
        let progressReport = activeSkills.map { "\($0.skillName): \($0.formattedProgress)" }.joined(separator: "\n")
        
        return """
        Analyze these learning progressions:
        \(progressReport)
        
        Suggest focus areas and time management tips.
        """
    }
}
