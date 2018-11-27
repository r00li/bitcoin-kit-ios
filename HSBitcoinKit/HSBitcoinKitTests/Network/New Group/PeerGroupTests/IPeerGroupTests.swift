
import XCTest
import Cuckoo
import RealmSwift
import HSHDWalletKit
@testable import HSBitcoinKit

class IPeerGroupTests: PeerGroupTests {

    // For all tests peersCount = 3

    func testStart() {
        peerGroup.start()
        waitForMainQueue()

        verify(mockBlockSyncer).prepareForDownload()
        let expectedConnectTriggeredHosts = Array(peers.keys.sorted().prefix(peersCount))
        verify(mockPeerHostManager, times(peersCount)).peerHost.get
        verifyConnectTriggeredOnlyForPeers(withHosts: expectedConnectTriggeredHosts)

        for host in expectedConnectTriggeredHosts {
            let peerMock = peers[host]!
            verify(peerMock).delegate.set(any())
            verify(peerMock).localBestBlockHeight.set(equal(to: 0))
            verify(mockPeerManager).add(peer: equal(to: peerMock, equalWhen: { $0!.host == $1.host }))
        }
    }

    func testStart_OnlyOneProcessAtATime() {
        // First time
        stub(mockPeerHostManager) { mock in
            when(mock.peerHost.get).thenReturn(nil)
        }

        peerGroup.start()
        waitForMainQueue()

        verify(mockPeerHostManager, times(1)).peerHost.get

        // Second time
        reset(mockPeerHostManager)
        stub(mockPeerHostManager) { mock in
            when(mock.peerHost.get).thenReturn(nil)
        }

        peerGroup.start()
        waitForMainQueue()

        verify(mockPeerHostManager, never()).peerHost.get

        // But if you stop and start again
        reset(mockPeerHostManager)
        stub(mockPeerHostManager) { mock in
            when(mock.peerHost.get).thenReturn(nil)
        }

        peerGroup.stop()
        peerGroup.start()
        waitForMainQueue()

        verify(mockPeerHostManager, times(1)).peerHost.get
    }

    func testStart_AddedPeersIsEqualToPeersCount() {
        stub(mockPeerManager) { mock in
            when(mock.totalPeersCount()).thenReturn(peersCount)
        }
        peerGroup.start()
        waitForMainQueue()

        verify(mockPeerHostManager, never()).peerHost.get
        verifyConnectTriggeredOnlyForPeers(withHosts: [])
    }

    func testStart_SubscribeToReachabilityManager() {
        XCTAssertEqual(subject.hasObservers, false)
        peerGroup.start()
        waitForMainQueue()
        XCTAssertEqual(subject.hasObservers, true)
    }

    func testStart_NetworkIsNotReachable() {
        stub(mockReachabilityManager) { mock in
            when(mock.reachable()).thenReturn(false)
        }

        peerGroup.start()
        waitForMainQueue()

        verify(mockPeerHostManager, never()).peerHost.get
        verifyConnectTriggeredOnlyForPeers(withHosts: [])
    }

    func testStop() {
        peerGroup.stop()
        verify(mockPeerManager).disconnectAll()
    }

    func testSendPendingTransactions() {
        let transaction = TestData.p2pkTransaction
        let peer = peers["0"]!

        stub(mockTransactionSyncer) { mock in
            when(mock.pendingTransactions()).thenReturn([transaction])
        }
        stub(mockPeerManager) { mock in
            when(mock.connected()).thenReturn([peer])
            when(mock.nonSyncedPeer()).thenReturn(nil)
            when(mock.someReadyPeers()).thenReturn([peer])
        }

        try! peerGroup.sendPendingTransactions()
        waitForMainQueue()

        let task = SendTransactionTask(transaction: transaction)
        verify(peer).add(task: equal(to: task, equalWhen: { ($0 as! SendTransactionTask) == ($1 as! SendTransactionTask) }))
    }

    func testSendPendingTransactions_NoConnectedPeers() {
        let transaction = TestData.p2pkTransaction
        let peer = peers["0"]!

        stub(mockTransactionSyncer) { mock in
            when(mock.pendingTransactions()).thenReturn([transaction])
        }
        stub(mockPeerManager) { mock in
            when(mock.connected()).thenReturn([])
            when(mock.nonSyncedPeer()).thenReturn(nil)
            when(mock.someReadyPeers()).thenReturn([peer])
        }

        do {
            try peerGroup.sendPendingTransactions()
            waitForMainQueue()
            XCTFail("Should throw exception")
        } catch let error as PeerGroup.PeerGroupError {
            XCTAssertEqual(error, PeerGroup.PeerGroupError.noConnectedPeers)
        } catch {
            XCTFail("Unexpected exception thrown")
        }

        verify(peer, never()).add(task: any())
    }

    func testSendPendingTransactions_PeersAreNotSynced() {
        let transaction = TestData.p2pkTransaction
        let peer = peers["0"]!

        stub(mockTransactionSyncer) { mock in
            when(mock.pendingTransactions()).thenReturn([transaction])
        }
        stub(mockPeerManager) { mock in
            when(mock.connected()).thenReturn([peer])
            when(mock.nonSyncedPeer()).thenReturn(peer)
            when(mock.someReadyPeers()).thenReturn([peer])
        }

        do {
            try peerGroup.sendPendingTransactions()
            waitForMainQueue()
            XCTFail("Should throw exception")
        } catch let error as PeerGroup.PeerGroupError {
            XCTAssertEqual(error, PeerGroup.PeerGroupError.peersNotSynced)
        } catch {
            XCTFail("Unexpected exception thrown")
        }

        verify(peer, never()).add(task: any())
    }

    func testSendPendingTransactions_NoReadyPeers() {
        let transaction = TestData.p2pkTransaction
        let peer = peers["0"]!

        stub(mockTransactionSyncer) { mock in
            when(mock.pendingTransactions()).thenReturn([transaction])
        }
        stub(mockPeerManager) { mock in
            when(mock.connected()).thenReturn([peer])
            when(mock.nonSyncedPeer()).thenReturn(nil)
            when(mock.someReadyPeers()).thenReturn([])
        }

        try! peerGroup.sendPendingTransactions()
        waitForMainQueue()

        verify(peer, never()).add(task: any())
    }

}