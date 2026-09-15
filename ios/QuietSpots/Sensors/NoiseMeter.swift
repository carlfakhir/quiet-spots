/*
Abstract:
Reads the microphone's input level and converts it to an approximate sound level in dB.

iPhone microphones report level in dBFS (0 = loudest possible, about -160 = silence), not the dB SPL
that sound meters show. Adding a fixed offset gives a usable estimate: a quiet library lands around
35–45 and a busy atrium around 65–75. It isn't calibrated, but every phone is compared on the same scale.
*/

import AVFoundation

@Observable
class NoiseMeter {
    enum State: Equatable { case idle, measuring, finished, denied, failed(String) }

    private(set) var state = State.idle
    /// Latest smoothed reading, for the live display.
    private(set) var currentDb: Double = 0
    /// All readings taken during this measurement.
    private(set) var samples: [Double] = []
    private(set) var progress: Double = 0

    let duration: TimeInterval = 5
    private let sampleInterval: TimeInterval = 0.1
    private let calibrationOffset = 90.0

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var startedAt = Date()

    /// Energy average rather than an arithmetic mean, since decibels are logarithmic.
    var averageDb: Double? {
        guard !samples.isEmpty else { return nil }
        let meanPower = samples.map { pow(10, $0 / 10) }.reduce(0, +) / Double(samples.count)
        return 10 * log10(meanPower)
    }

    var peakDb: Double? { samples.max() }

    @MainActor
    func start() async {
        stop()
        samples = []
        progress = 0
        currentDb = 0

        guard await AVAudioApplication.requestRecordPermission() else {
            state = .denied
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)

            // Metering only: audio goes to /dev/null, nothing is saved or uploaded.
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
            ]
            let recorder = try AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null"), settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                state = .failed(String(localized: "The microphone couldn't start."))
                return
            }
            self.recorder = recorder
        } catch {
            state = .failed(error.localizedDescription)
            return
        }

        startedAt = .now
        state = .measuring
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    @MainActor
    private func tick() {
        guard let recorder else { return }
        recorder.updateMeters()
        let dbfs = Double(recorder.averagePower(forChannel: 0))
        let db = min(max(dbfs + calibrationOffset, 0), 130)
        samples.append(db)
        currentDb = currentDb == 0 ? db : currentDb * 0.7 + db * 0.3

        progress = min(Date.now.timeIntervalSince(startedAt) / duration, 1)
        if progress >= 1 {
            stop()
            state = .finished
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if state == .measuring { state = .idle }
    }
}
