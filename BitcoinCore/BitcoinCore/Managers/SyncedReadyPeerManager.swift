import RxSwift

public class SyncedReadyPeerManager {
    private let disposeBag = DisposeBag()
    private let peerGroup: IPeerGroup
    private let initialBlockDownload: IInitialBlockDownload
    private var peerStates = [String: Bool]()

    private let peerSyncedAndReadySubject = PublishSubject<IPeer>()

    init(peerGroup: IPeerGroup, initialBlockDownload: IInitialBlockDownload) {
        self.peerGroup = peerGroup
        self.initialBlockDownload = initialBlockDownload
    }

    private func set(state: Bool, to peer: IPeer) {
        let oldState = peerStates[peer.host] ?? false
        peerStates[peer.host] = state

        if oldState != state {
            if state {
                peerSyncedAndReadySubject.onNext(peer)
            } else {
            }
        }
    }

    func subscribeTo(observable: Observable<PeerGroupEvent>) {
        observable.subscribe(
                        onNext: { [weak self] in
                            switch $0 {
                            case .onPeerConnect(let peer): self?.onPeerConnect(peer: peer)
                            case .onPeerDisconnect(let peer, let error): self?.onPeerDisconnect(peer: peer, error: error)
                            case .onPeerReady(let peer): self?.onPeerReady(peer: peer)
                            case .onPeerBusy(let peer): self?.onPeerBusy(peer: peer)
                            default: ()
                            }
                        }
                )
                .disposed(by: disposeBag)
    }

    func subscribeTo(observable: Observable<InitialBlockDownloadEvent>) {
        observable.subscribe(
                        onNext: { [weak self] in
                            switch $0 {
                            case .onPeerSynced(let peer): self?.onPeerSynced(peer: peer)
                            case .onPeerNotSynced(let peer): self?.onPeerNotSynced(peer: peer)
                            }
                        }
                )
                .disposed(by: disposeBag)
    }
}

extension SyncedReadyPeerManager: ISyncedReadyPeerManager {

    public var peers: [IPeer] {
        return initialBlockDownload.syncedPeers.filter {
            self.peerGroup.isReady(peer: $0)
        }
    }

    public var observable: Observable<IPeer> {
        return peerSyncedAndReadySubject.asObservable()
    }

}

extension SyncedReadyPeerManager {

    private func onPeerConnect(peer: IPeer) {
        set(state: false, to: peer)
    }

    private func onPeerDisconnect(peer: IPeer, error: Error?) {
        peerStates.removeValue(forKey: peer.host)
    }

    private func onPeerReady(peer: IPeer) {
        if initialBlockDownload.isSynced(peer: peer) {
            set(state: true, to: peer)
        }
    }

    private func onPeerBusy(peer: IPeer) {
        set(state: false, to: peer)
    }

}

extension SyncedReadyPeerManager {

    private func onPeerSynced(peer: IPeer) {
        if peerGroup.isReady(peer: peer) {
            set(state: true, to: peer)
        }
    }

    private func onPeerNotSynced(peer: IPeer) {
        set(state: false, to: peer)
    }

}
