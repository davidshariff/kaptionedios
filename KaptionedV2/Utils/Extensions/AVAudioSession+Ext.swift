import AVFoundation

extension AVAudioSession {
    
    func configurePlaybackSession(){
        print("Configuring playback session")
        do {
            try self.setCategory(.playback, mode: .default)
            try self.overrideOutputAudioPort(.none)
            try self.setActive(true)
            print("Current audio route: ", self.currentRoute.outputs)
        } catch let error as NSError {
            print("#configureAudioSessionToSpeaker Error \(error.localizedDescription)")
        }
    }

}
