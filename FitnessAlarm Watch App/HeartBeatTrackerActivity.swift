import SwiftUI



/// Run this every 10 seconds after activating?
func isCurrHeartBeatLargerThanMaxToBeat(maxToBeat: Int) -> Bool {

    let currentHeartBeat = getCurrentHeartBeat();
    
    return currentHeartBeat >= maxToBeat;
}

/// Set the heartbeat to beat
func getCurrentHeartBeat() -> Int {
    
    return 0;
}
