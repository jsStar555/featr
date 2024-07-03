//
//  JobProposalService.swift
//  featrrrnew
//
//  Created by Josh Beck on 3/18/24.
//

import Foundation
import Firebase

class JobProposalService {
    
    public static let standard = JobProposalService()
    
    func getProposal(from proposalID: String, completion: @escaping (Result<JobProposal, Error>) -> ()) {
        FirestoreConstants.JobProposalCollection.document(proposalID).getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            if let proposal = try? snapshot?.data(as: JobProposal.self ) {
                completion(.success(proposal))
                return
            } else {
                Log.d("Unable to decode the JobProposal for the proposal \(proposalID)")
                completion(.failure("Unable to decode the JobProposal"))
                return
            }
        }
        
        
    }
    
    func cancel(proposalId: String, completion: @escaping (Result<Any, Error>) -> ()) {
        let jobProposalDocument = FirestoreConstants.JobProposalCollection.document(proposalId)
        let updateField: [String: String] = [JobProposal.CodingKeys.status.rawValue: JobProposalStatus.cancelled.rawValue]
        
        jobProposalDocument.updateData(updateField) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true)) //TODO: Possibly add in actual
            }
        }
    }
    func complete(proposalId: String, completionCost cost: Double, completion: @escaping (Result<Any, Error>) -> ()) {
        let jobProposalDocument = FirestoreConstants.JobProposalCollection.document(proposalId)
        let updateField: [String: Any] = [
            JobProposal.CodingKeys.status.rawValue: JobProposalStatus.completed.rawValue,
            JobProposal.CodingKeys.completionCost.rawValue: cost]
        
        jobProposalDocument.updateData(updateField) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true)) //TODO: Possibly add in actual
            }
        }
    }
    func getProposals(forUserID userID: String, selection: PaymentSelection? = nil, completion: @escaping (Result<[JobProposal], Error>) -> ()) {
        var query = FirestoreConstants.JobProposalCollection.whereField("buyerID", isEqualTo: userID)
        
        if let selection {
            query = query.whereField("status", isEqualTo: selection.rawValue)
        }
        
        query.getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            var bids: [JobProposal] = []
            if let documents = snapshot?.documents {
                for doc in documents {
                    do {
                        let proposal = try doc.data(as: JobProposal.self )
                        bids.append(proposal)
                    } catch {
                        Log.d("Unable to decode the JobProposal with error \(error.localizedDescription)")
                    }
                }
            }
            completion(.success(bids))
        }
        
        
    }
    func getProposalsByDate(forUserID userID: String, selection: PaymentSelection? = nil, completion: @escaping (Result<[DateComponents: CalendarItem], Error>) -> ()) {
        var proposalsByDate: [DateComponents: CalendarItem] = [:]

        let calendar = Calendar(identifier: .gregorian)
        getProposals(forUserID: userID, selection: selection) { result in
            do {
                var proposals = try result.get()
                var tasks = self.getTask(jobs: proposals)
                var hourlyAndStories = self.getHourlyAndStory(jobs: proposals)
                for task in tasks {
                    if let startDate = task.startDate {
                        let component = calendar.dateComponents([.year, .month, .day], from: startDate)
                        if proposalsByDate[component] == nil {
                            proposalsByDate[component] = CalendarItem(date: component, items: [task])
                        } else {
                            proposalsByDate[component]!.items.append(task)
                        }
                    } // MARK: Silently ignore any tasks without start dates
                }
                
                for bids in hourlyAndStories {
                    if let startDate = bids.startDate {
                        let component = calendar.dateComponents([.year, .month, .day], from: startDate)
                        if proposalsByDate[component] == nil {
                            proposalsByDate[component] = CalendarItem(date: component, items: [bids])
                        } else {
                            proposalsByDate[component]!.items.append(bids)
                        }
                    } // MARK: Silently ignore any tasks without start dates
                }
                
                completion(.success(proposalsByDate))
            } catch  {
                completion(.failure(error))
            }
        }
        
        
    }
    
    private func getHourly(jobs: [JobProposal]) -> [JobCalendarItem] {
        var items: [JobCalendarItem] = []
        for job in jobs {
            if let hourly = job.proposal.hourly, let startDate = job.proposal.hourlyStartDate, let duration =  job.proposal.hourlyDuration, let rate = job.proposal.hourlyRate {
                let endDate = startDate.addingTimeInterval(duration)
                let cost = duration*rate
                items.append(JobCalendarItem(startDate: startDate, endDate: endDate, cost: cost, jobProposal: job, jobType: .hourly))
            }
        }
        return items
    }
    private func getStory(jobs: [JobProposal]) -> [JobCalendarItem] {
        var items: [JobCalendarItem] = []
        for job in jobs {
            if let story = job.proposal.story, let startDate = job.proposal.storyDate,  let cost = job.proposal.storyRate {
                items.append(JobCalendarItem(startDate: startDate, endDate: nil, cost: cost, jobProposal: job, jobType: .story))
            }
        }
        return items
    }
    public func getTask(jobs: [JobProposal]) -> [JobCalendarItem] {
        var items: [JobCalendarItem] = []
        for job in jobs {
            if let task = job.proposal.task, let startDate = job.proposal.taskDate,  let cost = job.proposal.taskRate {
                items.append(JobCalendarItem(startDate: startDate, endDate: nil, cost: cost, jobProposal: job, jobType: .task))
            }
        }
        return items
    }
    
    func getHourlyAndStory(jobs: [JobProposal]) -> [JobCalendarItem] {
        var hourlyItems = getHourly(jobs: jobs)
        var storyItems = getStory(jobs: jobs)
        
        var hourlyAndStoryItems = hourlyItems + storyItems
        hourlyAndStoryItems.sort { ($0.startDate != nil && $1.startDate != nil) ? ($0.startDate! < $1.startDate!) : false }
        // MARK: Check that the sort functionality is correct
        return hourlyAndStoryItems
    }
    
    func sendJobProposal(forJob job: JobPost, withJob bid: Proposal, status: JobProposalStatus = .pending) -> Result<String?, Error> {
        
        let jobProposalDocument = FirestoreConstants.JobProposalCollection.document()
            
        guard let buyerID = Auth.auth().currentUser?.uid else {
            return .failure("The buyer's ID was unaccessible")
        }
        guard let sellerID = job.user?.uid else {
            return .failure("The seller's ID was unaccessible")
        }
        guard let jobID = job.id else {
            return .failure("The job ID was unaccessible")
        }
        
        if (bid.hourly == nil && bid.task == nil && bid.story == nil ) {
            return .failure("The bid returned did not have an hourly, task, or story bid attached")
        }
        
        let jobProposal = JobProposal(sellerID: sellerID, buyerID: buyerID, jobID: jobID, status: status, proposal: bid)
        
        guard let encodedJobProposal = try? Firestore.Encoder().encode(jobProposal) else {
            return .failure("We were unable to encode the job bid")
        }
        
        jobProposalDocument.setData(encodedJobProposal)
        
        return .success(jobProposalDocument.documentID)
    }
}

class JobCalendarItem: Hashable {
    static func == (lhs: JobCalendarItem, rhs: JobCalendarItem) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.jobProposal.id == rhs.jobProposal.id
    }
    
    var startDate: Date?
    var endDate: Date?
    var cost: Double
    var jobProposal: JobProposal
    var jobType: JobType
    
    init(startDate: Date?, endDate: Date?, cost: Double, jobProposal: JobProposal, jobType: JobType) {
        self.startDate = startDate
        self.endDate = endDate
        self.cost = cost
        self.jobProposal = jobProposal
        self.jobType = jobType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(startDate)
        hasher.combine(endDate)
        hasher.combine(cost)
        hasher.combine(jobProposal.id)
        hasher.combine(jobType)
    }
    
}

class CalendarItem: Hashable {
    static func == (lhs: CalendarItem, rhs: CalendarItem) -> Bool {
        return lhs.date == rhs.date
    }
    
    var date: DateComponents
    var items: [JobCalendarItem]
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(date)
            hasher.combine(items)
        }
    
    init(date: DateComponents, items: [JobCalendarItem]) {
        self.date = date
        self.items = items
    }
    
    
}
