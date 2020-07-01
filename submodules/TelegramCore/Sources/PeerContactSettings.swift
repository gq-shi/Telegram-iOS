import Foundation
import Postbox
import TelegramApi
import SwiftSignalKit
import SyncCore

extension PeerStatusSettings {
    init(apiSettings: Api.PeerSettings) {
        switch apiSettings {
            case let .peerSettings(flags, geoDistance):
                var result = PeerStatusSettings.Flags()
                if (flags & (1 << 1)) != 0 {
                    result.insert(.canAddContact)
                }
                if (flags & (1 << 0)) != 0 {
                    result.insert(.canReport)
                }
                if (flags & (1 << 2)) != 0 {
                    result.insert(.canBlock)
                }
                if (flags & (1 << 3)) != 0 {
                    result.insert(.canShareContact)
                }
                if (flags & (1 << 4)) != 0 {
                    result.insert(.addExceptionWhenAddingContact)
                }
                if (flags & (1 << 5)) != 0 {
                    result.insert(.canReportIrrelevantGeoLocation)
                }
                if (flags & (1 << 7)) != 0 {
                    result.insert(.autoArchived)
                }
                self = PeerStatusSettings(flags: result, geoDistance: geoDistance)
        }
    }
}

public func unarchiveAutomaticallyArchivedPeer(account: Account, peerId: PeerId) {
    let _ = (account.postbox.transaction { transaction -> Void in
        updatePeerGroupIdInteractively(transaction: transaction, peerId: peerId, groupId: .root)
        transaction.updatePeerCachedData(peerIds: Set([peerId]), update: { _, current in
            guard let currentData = current as? CachedUserData, let currentStatusSettings = currentData.peerStatusSettings else {
                return current
            }
            var statusSettings = currentStatusSettings
            statusSettings.flags.remove(.canBlock)
            statusSettings.flags.remove(.canReport)
            statusSettings.flags.remove(.autoArchived)
            return currentData.withUpdatedPeerStatusSettings(statusSettings)
        })
    }
    |> deliverOnMainQueue).start()
    
    let _ = updatePeerMuteSetting(account: account, peerId: peerId, muteInterval: nil).start()
}
