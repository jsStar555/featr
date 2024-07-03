//
//  CalendarView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 6/29/23.
//

import SwiftUI
import UIKit
import FSCalendar

extension DateComponents: Equatable {
    public static func == (lhs: DateComponents, rhs: DateComponents) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        return calendar.date(byAdding: lhs, to: now)! == calendar.date(byAdding: rhs, to: now)!
    }
}

enum JobType: String {
    case story = "Story"
    case hourly = "Hourly"
    case task = "Task"
}

class CalendarViewModel: ObservableObject {
    @Published var calendarItems: [DateComponents: CalendarItem] = [:]
    @Published var modifiedItem: CalendarItem?
    let calendar = Calendar(identifier: .gregorian)
    init() {
        if let auth = AuthService.shared.user?.id {
             JobProposalService.standard.getProposalsByDate(forUserID: auth, completion: { result in
                 do {
                     self.calendarItems =  try result.get()
                     print("checkign calendar view with itemssss \(self.calendarItems.count)")
                     print(self.calendarItems)
                 } catch {
                     //TODO: Catch excetption
                 }
            })
        }
        //TODO: Get actual values instead of hardcoded values
    }
}
struct WrapperView: View {
    @StateObject var viewModel = CalendarViewModel()
    @State var dateSelected : DateComponents?
    @State var showSheet = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Calendar")
                .font(Style.font.title)
                .foregroundColor(.foreground)
                .padding(.leading,.lg)
                .padding(.bottom,.md)
            
            CalendarView(interval: DateInterval(start: .distantPast, end: .distantFuture), viewModel: viewModel, dateSelected: $dateSelected, showSheet: $showSheet)
                
            Divider()
        }
        .padding(.lg)
        .sheet(isPresented: $showSheet) {
            JobPreviewSheet(dateSelected: $dateSelected)
                .environmentObject(viewModel)
                .presentationDetents([.large,])
        }
    }
}
struct TaskCard: View {
    var calendarItem: JobCalendarItem
    @State var job: JobPost?
    init(calendarItem: JobCalendarItem) {
        self.calendarItem = calendarItem
    }
    var body: some View {
        
        VStack {
            if let job, let user = AuthService.shared.user {
                NavigationLink(value: job) {
                    HStack {
                        Text(job.category)
                            .font(Style.font.title4)
                            .italic()
                        Spacer()
                        Chip(text: calendarItem.jobType.rawValue, style: .inverse)
                        Image(systemName: "arrow.forward")
                            .foregroundStyle(Color.background)
                    }
                    .padding(20)
                    .cornerRadius(20) // Apply corner radius for rounded corners
                    .background( // Overlay a rounded rectangle for the border
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.primary) // Stroke with desired color and width
                    )
                    .foregroundStyle(Color.background)
                }
                
            } else {
                ProgressView()
            }
            
            
        }.task {
            do {
                let j = try await JobService.standard.fetchJob(withId: calendarItem.jobProposal.jobID)
                DispatchQueue.main.async {
                    job = j
                }
            } catch {
                //TODO: Catch
            }
        }
        
    }
}
struct HourlyOrStoryCard: View {
    var calendarItem: JobCalendarItem
    @State var job: JobPost?
    init(calendarItem: JobCalendarItem) {
        self.calendarItem = calendarItem
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm a"
        let timeString = formatter.string(from: date)
        return timeString
    }
    var body: some View {
        VStack {
            if let job {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(job.category)
                                .font(Style.font.title4)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .italic()
                            Spacer()
                            Chip(text: calendarItem.jobType.rawValue, style: .inverse)
                        }
                        HStack {
                            if let startDate = calendarItem.startDate {
                                if let endDate = calendarItem.endDate {
                                    Text("\(formatDate(date: startDate)) - \(formatDate(date: startDate))")
                                        .font(Style.font.title2)
                                } else {
                                    Text(formatDate(date: startDate))
                                        .font(Style.font.title2)
                                }
                            }
                            Spacer()
                            Text( calendarItem.cost, format: .currency(code: "USD"))
                                .font(Style.font.title4)
                                .foregroundStyle(Color.background)
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.forward")
                                .foregroundStyle(Color.background)
                        }
                        
                    }
                    .padding(20)
                    .frame(maxHeight: 150)
                    .cornerRadius(20) // Apply corner radius for rounded corners
                    .background( // Overlay a rounded rectangle for the border
                          RoundedRectangle(cornerRadius: 20)
                            .fill(Color.primary) // Stroke with desired color and width
                        )
                    .foregroundStyle(Color.background)
                   
                }
            } else {
                ProgressView()
            }
        }.task {
            do {
                let j = try await JobService.standard.fetchJob(withId: calendarItem.jobProposal.jobID)
                DispatchQueue.main.async {
                    job = j
                }
            } catch {
                //TODO: Catch
            }
        }
    }
}
struct JobPreviewSheet: View {
    @EnvironmentObject var viewModel : CalendarViewModel
    @Environment(\.dismiss) var dismiss
    
    @Binding var dateSelected : DateComponents?

  
    func formatDateHeader(date: Date) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // MMM for Month (first 3 letters), d for day

        return formatter.string(from: date)
        
    }
    
    func taskScrollable(calendarItems: CalendarItem) -> some View {
    
        return ScrollView(.horizontal, showsIndicators: false) {
                ForEach(calendarItems.items, id: \.self) { item in
                    if item.jobType == .task {
                       
                            TaskCard(calendarItem: item)
                                .padding(.bottom, 20)
                        
                    }
                }
            }.padding(.leading, 20)
        
    }
    
    
    func hourlyStoryScrollable(calendarItems: CalendarItem) -> some View {
     
            return ScrollView(.vertical, showsIndicators: false) {
                ForEach(calendarItems.items, id: \.self) { item in
                    
                    if item.jobType == .hourly || item.jobType == .story {
                        HourlyOrStoryCard(calendarItem: item)
                    }
                }
               
            }.padding(.horizontal, 20)
        
    }
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if let date = dateSelected?.date {
                    Text(formatDateHeader(date: date))
                        .font(Style.font.display)
                        .padding(.horizontal, 20)
                }
                
                if let dateSelected,
                   let calendarItems = viewModel.calendarItems.first(where: {$0.key == dateSelected})?.value {
                    
                    taskScrollable(calendarItems: calendarItems)
                        
                    Text("Sorted by Time")
                        .font(Style.font.title)
                        .padding(.horizontal, 20)
                       
                    
                    if (calendarItems.items.filter({$0.jobType == .hourly || $0.jobType == .story}).count > 0) {
                        hourlyStoryScrollable(calendarItems: calendarItems)
                    } else {
                        Text("No Hourly or Story Jobs for Today")
                            .padding(.top, 10)
                            .padding(.horizontal, 20)
                            .font(Style.font.body)
                            .italic()
                            .foregroundColor(Color.lightBackground)
                    }
                    
                }
                
                Spacer()
                    
            }
            .navigationDestination<ProfileView?>(for: JobPost.self) { job in
//                if let user = job.user {
                //TODO: Make null safe
                return ProfileView(user: job.user!, selectedJob: job)
//                }
                
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Menu {
//                        Button {
//                            if let foundIndex = findTheIndex(dateSelected: dateSelected) {
//                                viewModel.calendarItems[foundIndex].type = .story
//                                viewModel.modifiedItem = viewModel.calendarItems[foundIndex]
//                                dismiss()
//                            }
//                        } label: {
//                            Label("Change", systemImage: "pencil")
//                        }
//                        
//                        Button {
//                            print("push delete")
//                            
//                            if let foundIndex = findTheIndex(dateSelected: dateSelected) {
//                                print("deleting it")
//                                
//                                // In addition to removing the element we also set it on the model so we can update the UI in the coordinator
//                                viewModel.modifiedItem = viewModel.calendarItems.remove(at: foundIndex)
//                                dismiss()
//                            }
//                        } label: {
//                            Label("Delete", systemImage: "trash")
//                        }
//                    } label: {
//                        Text("Menu")
//                    }
//                }
            }
        }
    }
    
    func findTheIndex(dateSelected : DateComponents?) -> Int? {
        var returnVal : Int? = nil
        
//        if let dateSelected,
//           let foundIndex = viewModel.calendarItems.firstIndex(where: { item in
//               if dateSelected == item.date {
//                   return true
//               } else {
//                   return false
//               }
//           }) {
//            returnVal = foundIndex
//        }
        
        return returnVal
    }
}

class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    var parent: CalendarView
    
    @ObservedObject var viewModel : CalendarViewModel
    @Binding var dateSelected : DateComponents?
    @Binding var showSheet : Bool
    
    // Your database implementation goes here.
    init(_ calendarStuff: CalendarView, viewModel : ObservedObject<CalendarViewModel>, dateSelected: Binding<DateComponents?>, showSheet: Binding<Bool>) {
        parent = calendarStuff
        self._viewModel = viewModel
        self._dateSelected = dateSelected
        self._showSheet = showSheet
    }
    
    // Create and return calendar decorations here.
    @MainActor func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
       
        guard let foundEvents = viewModel.calendarItems.first(where: {$0.key == dateComponents}) else {
            return nil
        }
        
        if dateComponents.date ?? Date() > Date() {
            return nil
        } else {
            return .default(color: UIColor(Color.primary), size: UICalendarView.DecorationSize.medium)
        }
        
        return nil
    }
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        dateSelected = dateComponents
        
        if let dateComponents,
           let _ = viewModel.calendarItems.first(where: {$0.key == dateComponents}) {
            showSheet.toggle()
        }
    }
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        return true
    }
}




struct CalendarView : UIViewRepresentable {
    
    public let interval : DateInterval
    @ObservedObject var viewModel : CalendarViewModel
    @Binding var dateSelected : DateComponents?
    @Binding var showSheet : Bool
    
    var view = UICalendarView()
    
    
    func makeCoordinator() -> Coordinator {
        // Create an instance of Coordinator
        return Coordinator(self, viewModel: _viewModel, dateSelected: $dateSelected, showSheet: $showSheet)
    }
    
    func makeUIView(context: Context) -> some UICalendarView {
        view.delegate = context.coordinator
        
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
        if let removedData = viewModel.modifiedItem {
            uiView.reloadDecorations(forDateComponents: [removedData.date], animated: true)
            viewModel.modifiedItem = nil
        }
        
        uiView.reloadDecorations(forDateComponents: viewModel.calendarItems.keys.map({$0}), animated: true)
        
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
    }
}

struct CalendarJobRow: View {
    
    var job: JobPost
    // State
    @State private var bottomSheet = false
    @State private var selectedImageIndex = 0
    
    // Private
    private let horizontalPadding: CGFloat = 28
    
    init(job: JobPost) {
        self.job = job
    }
    
    @ViewBuilder
    var cardHeader: some View {
        
        if let user = job.user {
            HStack(spacing: 0) {
                CircularProfileImageView(user: user)
                    .scaledToFill()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .padding(.trailing, .lg)
                
                NavigationLink(value: user) {
                    Chip(text: "@\(user.username)", style: .information)
                }
            }
        }
    }
    
    @ViewBuilder
    var cardTitle: some View {
        
        
            Text("\(job.category)")
                .textCase(.uppercase)
                .font(Style.font.title3)
                .foregroundColor(Color.foreground)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
       
    }

    @ViewBuilder
    var cardImage: some View {
        
       
            
            ZStack(alignment: .topTrailing) {
               
                
                   
                        ImageCarousel(urls: job.imageUrls, padding: .init(top: 0, leading: horizontalPadding, bottom: 0, trailing: horizontalPadding))
                            .preview()
                            .pageControllerOffset(x: 12)
                           
                
                Text("\u{2192}") //Side arrow (􀰑)
                    .font(Style.font.title2)
                    .padding(.sm)
                    .foregroundColor(Color.background)
                    
            }
        
    }
    
    @ViewBuilder
    var cardPriceOverlay: some View {
        
            
            HStack {
                Spacer()
                VStack {
                    Text("$\(job.task)")
                        .font(Style.font.caption)
                    Text("task")
                        .font(Style.font.caption2)
                }
                Spacer()
                Divider().frame(width: 1).overlay(Color.background)
                Spacer()
                VStack {
                    Text("$\(job.hr)")
                        .font(Style.font.caption)
                    Text("hour")
                        .font(Style.font.caption2)
                }
                Spacer()
                Divider().frame(width: 1).overlay(Color.background)
                Spacer()
                VStack {
                    Text("$\(job.storyPost)")
                        .font(Style.font.caption)
                    Text("story")
                        .font(Style.font.caption2)
                }
                Spacer()
            }
            .foregroundColor(Color.background)
            .background(RoundedRectangle(cornerRadius: .cornerS).fill(Color.primary))
            .frame(maxWidth: .infinity)
            
    }
    
    @ViewBuilder
    var cardBio: some View {
        Text("\(job.jobBio)")
            .font(Style.font.caption)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
    }
    

    var body: some View {
        Button(action: {
//            job = viewModel.job
            //TODO: Go to job
        }, label: {
            VStack(alignment: .leading) {
                
                HStack(spacing: CGFloat.md) {
                    cardImage
                    VStack {
                        cardTitle
                        cardPriceOverlay
                    }.frame(maxHeight: 120)
                }
            }
            .padding(.horizontal, horizontalPadding)
        })
        
    }
}


struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
//        CalendarView(interval: DateInterval(start: .now, end: .distantFuture))
        WrapperView()
    }
}
