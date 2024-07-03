//
//  ActiveNowView.swift
//  featrrrnew
//
//  Created by Buddie Booking on 8/9/23.
//

import SwiftUI

struct InboxRowView: View {
    //let user: User
    let message: Message
    var body: some View {
        HStack {
            ZStack {
                
                CircularProfileImageView()
            }
            
            
            
            VStack(alignment: .leading, spacing: CGFloat.xxsm) {
                Text(message.user?.fullname ?? message.user?.username ?? "")
                    .font(Style.font.messageBody)
                    .fontWeight(.semibold)
                
                Text(message.text)
                    .font(Style.font.messageCaption)
                    .foregroundColor(Color.lightBackground)
                    .lineLimit(2)
            }
            .padding(.leading, 12)
            Spacer()
            
            Text(message.timestamp.dateValue().timestampString())
                .font(Style.font.messageCaption)
                .foregroundColor(Color.lightBackground)
            
            if !message.read {
                VStack {
                    Color.primary
                }
                .frame(width: 12, height: 12)
                .cornerRadius(6, corners: .allCorners)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(Color.lightBackground)
            
        }
        .padding(.horizontal)
        .frame(height: 72)
    }
}
