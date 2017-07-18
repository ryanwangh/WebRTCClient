import Foundation


class PluginRTCPeerConnectionConstraints {
	fileprivate var constraints: RTCMediaConstraints


	init(pcConstraints: NSDictionary?) {
		NSLog("PluginRTCPeerConnectionConstraints#init()")

		if pcConstraints == nil {
			self.constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
			return
		}

		var	offerToReceiveAudio = pcConstraints?.object(forKey: "offerToReceiveAudio") as? Bool
		var	offerToReceiveVideo = pcConstraints?.object(forKey: "offerToReceiveVideo") as? Bool

		if offerToReceiveAudio == nil && offerToReceiveVideo == nil {
			self.constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
			return
		}

		if offerToReceiveAudio == nil {
			offerToReceiveAudio = false
		}

		if offerToReceiveVideo == nil {
			offerToReceiveVideo = false
		}

		NSLog("PluginRTCPeerConnectionConstraints#init() | [offerToReceiveAudio:%@, offerToReceiveVideo:%@]",
			String(offerToReceiveAudio!), String(offerToReceiveVideo!))

		self.constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio" : offerToReceiveAudio == true ? "true" : "false",
                "OfferToReceiveVideo" : offerToReceiveVideo == true ? "true" : "false"
			],
			optionalConstraints: [:]
		)
	}


	deinit {
		NSLog("PluginRTCPeerConnectionConstraints#deinit()")
	}


	func getConstraints() -> RTCMediaConstraints {
		NSLog("PluginRTCPeerConnectionConstraints#getConstraints()")
        print(self.constraints.description)
		return self.constraints
	}
}
