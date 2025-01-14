//
//  AlarmViewController.swift
//  FitnessAlarm
//
//  Created by Deividas Ovsianikovas on 25/12/2024.
//

import Foundation
import UIKit

class AlarmViewController: UIViewController {

    @IBOutlet weak var bpmThresholdTextField: UITextField!
    @IBOutlet weak var setAlarmButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        WatchSessionManager.shared.startSession()
    }

    @IBAction func setAlarmTapped(_ sender: UIButton) {
        guard let bpmString = bpmThresholdTextField.text, let bpmThreshold = Int(bpmString) else {
            showAlert("Invalid BPM Threshold")
            return
        }
        let message = ["bpmThreshold": bpmThreshold]
        WatchSessionManager.shared.sendMessage(message)
        showAlert("Alarm Set on Watch")
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
