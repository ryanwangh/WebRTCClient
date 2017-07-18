import Foundation


class PluginRTCPeerConnection : NSObject, RTCPeerConnectionDelegate {
	var rtcPeerConnectionFactory: RTCPeerConnectionFactory
	var rtcPeerConnection: RTCPeerConnection!
	var pluginRTCPeerConnectionConfig: PluginRTCPeerConnectionConfig
	var pluginRTCPeerConnectionConstraints: PluginRTCPeerConnectionConstraints
	// PluginRTCDataChannel dictionary.
	var pluginRTCDataChannels: [Int : PluginRTCDataChannel] = [:]
	var eventListener: (_ data: NSDictionary) -> Void
	var eventListenerForAddStream: (_ pluginMediaStream: PluginMediaStream) -> Void
	var eventListenerForRemoveStream: (_ id: String) -> Void
	var onCreateDescriptionSuccessCallback: ((_ rtcSessionDescription: RTCSessionDescription) -> Void)!
	var onCreateDescriptionFailureCallback: ((_ error: NSError) -> Void)!
	var onSetDescriptionSuccessCallback: (() -> Void)!
	var onSetDescriptionFailureCallback: ((_ error: NSError) -> Void)!


	init(
		rtcPeerConnectionFactory: RTCPeerConnectionFactory,
		pcConfig: NSDictionary?,
		pcConstraints: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForAddStream: @escaping (_ pluginMediaStream: PluginMediaStream) -> Void,
		eventListenerForRemoveStream: @escaping (_ id: String) -> Void
	) {
		NSLog("PluginRTCPeerConnection#init()")

		self.rtcPeerConnectionFactory = rtcPeerConnectionFactory
		self.pluginRTCPeerConnectionConfig = PluginRTCPeerConnectionConfig(pcConfig: pcConfig)
		self.pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: pcConstraints)
		self.eventListener = eventListener
		self.eventListenerForAddStream = eventListenerForAddStream
		self.eventListenerForRemoveStream = eventListenerForRemoveStream
	}


	deinit {
		NSLog("PluginRTCPeerConnection#deinit()")
	}


	func run() {
		NSLog("PluginRTCPeerConnection#run()")

        let configuration = RTCConfiguration()
        self.rtcPeerConnection = self.rtcPeerConnectionFactory.peerConnection(with: configuration, constraints: self.pluginRTCPeerConnectionConstraints.getConstraints(), delegate: self)
	}


	func createOffer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createOffer()")
        
		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | success callback")
            
			let data = [
				"type": self.getType(des: rtcSessionDescription),
				"sdp": rtcSessionDescription.sdp
			]

			callback(data as NSDictionary)
		}

		self.onCreateDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#createOffer() | failure callback: %@", String(describing: error))

			errback(error)
		}
        
        self.rtcPeerConnection.offer(for: pluginRTCPeerConnectionConstraints.getConstraints()) {  [unowned self] (des, error) in
            self.peerConnection(self.rtcPeerConnection, didCreateSessionDescription: des, error: error)
        }
	}


	func createAnswer(
		_ options: NSDictionary?,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createAnswer()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCPeerConnectionConstraints = PluginRTCPeerConnectionConstraints(pcConstraints: options)

		self.onCreateDescriptionSuccessCallback = { (rtcSessionDescription: RTCSessionDescription) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | success callback")
            
			let data = [
				"type": self.getType(des: rtcSessionDescription),
				"sdp": rtcSessionDescription.sdp
			]

			callback(data as NSDictionary)
		}

		self.onCreateDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#createAnswer() | failure callback: %@", String(describing: error))

			errback(error)
		}
        
        self.rtcPeerConnection.answer(for: pluginRTCPeerConnectionConstraints.getConstraints()) {  [unowned self] (des, error) in
            self.peerConnection(self.rtcPeerConnection, didCreateSessionDescription: des, error: error)
        }
	}


	func setLocalDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setLocalDescription()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

        guard let type = desc.object(forKey: "type") as? String else {
            return
        }
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
        var sdpType: RTCSdpType = .offer
        if type == "answer" {
            sdpType = .answer
        }
        
		let rtcSessionDescription = RTCSessionDescription(type: sdpType, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { [unowned self] () -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | success callback")

            if let des = self.rtcPeerConnection.localDescription {
                let data = [
                    "type": self.getType(des: des),
                    "sdp": des.sdp
                ]
                
                callback(data as NSDictionary)
            }
			
		}

		self.onSetDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#setLocalDescription() | failure callback: %@", String(describing: error))

			errback(error)
		}

        self.rtcPeerConnection.setLocalDescription(rtcSessionDescription) { [unowned self] (error) in
            self.peerConnection(self.rtcPeerConnection, didSetSessionDescriptionWithError: error)
        }
	}


	func setRemoteDescription(
		_ desc: NSDictionary,
		callback: @escaping (_ data: NSDictionary) -> Void,
		errback: @escaping (_ error: NSError) -> Void
	) {
		NSLog("PluginRTCPeerConnection#setRemoteDescription()")
        
        sleep(2)

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let type = desc.object(forKey: "type") as? String ?? ""
		let sdp = desc.object(forKey: "sdp") as? String ?? ""
        var sdpType: RTCSdpType = .offer
        if type == "answer" {
            sdpType = .answer
        }
		let rtcSessionDescription = RTCSessionDescription(type: sdpType, sdp: sdp)

		self.onSetDescriptionSuccessCallback = { [unowned self] () -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | success callback")

            if let des = self.rtcPeerConnection.remoteDescription {
                let data = [
                    "type": self.getType(des: des),
                    "sdp": des.sdp
                ]
                
                callback(data as NSDictionary)
            }
			
		}

		self.onSetDescriptionFailureCallback = { (error: NSError) -> Void in
			NSLog("PluginRTCPeerConnection#setRemoteDescription() | failure callback: %@", String(describing: error))

			errback(error)
		}
        
        self.rtcPeerConnection.setRemoteDescription(rtcSessionDescription) { [unowned self] (error) in
            self.peerConnection(self.rtcPeerConnection, didSetSessionDescriptionWithError: error)
        }
        
	}


	func addIceCandidate(
		_ candidate: NSDictionary,
		callback: (_ data: NSDictionary) -> Void,
		errback: () -> Void
	) {
        
		NSLog("PluginRTCPeerConnection#addIceCandidate()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let sdpMid = candidate.object(forKey: "sdpMid") as? String ?? ""
		let sdpMLineIndex = candidate.object(forKey: "sdpMLineIndex") as? Int ?? 0
		let candidate = candidate.object(forKey: "candidate") as? String ?? ""

        self.rtcPeerConnection.add(RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: Int32(sdpMLineIndex),
            sdpMid: sdpMid
        ))
        
		var data: NSDictionary

        if let des = self.rtcPeerConnection.remoteDescription {
            data = [
                "remoteDescription": [
                    "type": getType(des: des),
                    "sdp": des.sdp
                ]
            ]
        } else {
            data = [
                "remoteDescription": false
            ]
        }
        callback(data)
	}


	func addStream(_ pluginMediaStream: PluginMediaStream){
		NSLog("PluginRTCPeerConnection#addStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}
		self.rtcPeerConnection.add(pluginMediaStream.rtcMediaStream)
	}


	func removeStream(_ pluginMediaStream: PluginMediaStream) {
		NSLog("PluginRTCPeerConnection#removeStream()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.rtcPeerConnection.remove(pluginMediaStream.rtcMediaStream)
	}

    func getType(des: RTCSessionDescription) -> String {
        var type = "offer"
        if des.type == .answer {
            type = "answer"
        }
        return type
    }

	func createDataChannel(
		_ dcId: Int,
		label: String,
		options: NSDictionary?,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: NSData) -> Void
	) {
		NSLog("PluginRTCPeerConnection#createDataChannel()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = PluginRTCDataChannel(
			rtcPeerConnection: rtcPeerConnection,
			label: label,
			options: options,
			eventListener: eventListener,
			eventListenerForBinaryMessage: eventListenerForBinaryMessage
		)

		// Store the pluginRTCDataChannel into the dictionary.
		self.pluginRTCDataChannels[dcId] = pluginRTCDataChannel

		// Run it.
		pluginRTCDataChannel.run()
	}


	func RTCDataChannel_setListener(
		_ dcId: Int,
		eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForBinaryMessage: @escaping (_ data: NSData) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_setListener()")

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		// Set the eventListener.
		pluginRTCDataChannel!.setListener(eventListener,
			eventListenerForBinaryMessage: eventListenerForBinaryMessage
		)
	}


	func close() {
		NSLog("PluginRTCPeerConnection#close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		self.rtcPeerConnection.close()
	}


	func RTCDataChannel_sendString(
		_ dcId: Int,
		data: String,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendString()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendString(data, callback: callback)
	}


	func RTCDataChannel_sendBinary(
		_ dcId: Int,
		data: Data,
		callback: (_ data: NSDictionary) -> Void
	) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_sendBinary()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.sendBinary(data, callback: callback)
	}


	func RTCDataChannel_close(_ dcId: Int) {
		NSLog("PluginRTCPeerConnection#RTCDataChannel_close()")

		if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
			return
		}

		let pluginRTCDataChannel = self.pluginRTCDataChannels[dcId]

		if pluginRTCDataChannel == nil {
			return;
		}

		pluginRTCDataChannel!.close()

		// Remove the pluginRTCDataChannel from the dictionary.
		self.pluginRTCDataChannels[dcId] = nil
	}


	/**
	 * Methods inherited from RTCPeerConnectionDelegate.
	 */

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        let state_str = PluginRTCTypes.signalingStates[stateChanged.rawValue] as String!
        
        NSLog("PluginRTCPeerConnection | onsignalingstatechange [signalingState:%@]", String(describing: state_str))
        
        self.eventListener([
            "type": "signalingstatechange",
            "signalingState": state_str
            ])
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        let state_str = PluginRTCTypes.iceGatheringStates[newState.rawValue] as String!
        //            if String(state_str) == "complete"{
        //                sleep(10)
        //            }
        
        NSLog("PluginRTCPeerConnection | onicegatheringstatechange [iceGatheringState:%@]", String(describing: state_str))
        
        self.eventListener([
            "type": "icegatheringstatechange",
            "iceGatheringState": state_str
            ])
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
        
        // Emit an empty candidate if iceGatheringState is "complete".
        if newState.rawValue == RTCIceGatheringState.complete.rawValue,
            let des = self.rtcPeerConnection.localDescription {
            self.eventListener([
                "type": "icecandidate",
                // NOTE: Cannot set null as value.
                "candidate": false,
                "localDescription": [
                    "type": getType(des: des),
                    "sdp": des.sdp
                ]
                ])
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        NSLog("PluginRTCPeerConnection | onicecandidate [sdpMid:%@, sdpMLineIndex:%@, candidate:%@]",
              String(describing: candidate.sdpMid), String(candidate.sdpMLineIndex), String(candidate.sdp))
        
        if self.rtcPeerConnection.signalingState.rawValue == RTCSignalingState.closed.rawValue {
            return
        }
        
        if let des = self.rtcPeerConnection.localDescription {
            self.eventListener([
                "type": "icecandidate",
                "candidate": [
                    "sdpMid": candidate.sdpMid,
                    "sdpMLineIndex": candidate.sdpMLineIndex,
                    "candidate": candidate.sdp
                ],
                "localDescription": [
                    "type": getType(des: des),
                    "sdp": des.sdp
                ]
                ])
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let state_str = PluginRTCTypes.iceConnectionStates[newState.rawValue] as String!
        
        if String(describing: state_str) == "checking"{
            
            NSLog("checking---")
        }
        NSLog("PluginRTCPeerConnection | oniceconnectionstatechange [iceConnectionState:%@]", String(describing: state_str))
        
        self.eventListener([
            "type": "iceconnectionstatechange",
            "iceConnectionState": state_str
            ])
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        NSLog("PluginRTCPeerConnection | onaddstream")
        
        let pluginMediaStream = PluginMediaStream(rtcMediaStream: stream)
        
        //           sleep(1)
        pluginMediaStream.run()
        
        // Let the plugin store it in its dictionary.
        self.eventListenerForAddStream(pluginMediaStream)
        
        // Fire the 'addstream' event so the JS will create a new MediaStream.
        self.eventListener([
            "type": "addstream",
            "stream": pluginMediaStream.getJSON()
            ])
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        NSLog("PluginRTCPeerConnection | onremovestream")
        
        // Let the plugin remove it from its dictionary.
        self.eventListenerForRemoveStream(stream.streamId)
        
        self.eventListener([
            "type": "removestream",
            "streamId": stream.streamId  // NOTE: No "id" property yet.
            ])
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }

	func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
		NSLog("PluginRTCPeerConnection | onnegotiationeeded")

		self.eventListener([
			"type": "negotiationneeded"
		])
	}


    func peerConnection(_ peerConnection: RTCPeerConnection!,
                        didOpen rtcDataChannel: RTCDataChannel!) {
		NSLog("PluginRTCPeerConnection | ondatachannel")

		let dcId = PluginUtils.randomInt(10000, max:99999)
		let pluginRTCDataChannel = PluginRTCDataChannel(
			rtcDataChannel: rtcDataChannel
		)

		// Store the pluginRTCDataChannel into the dictionary.
		self.pluginRTCDataChannels[dcId] = pluginRTCDataChannel

		// Run it.
		pluginRTCDataChannel.run()

		// Fire the 'datachannel' event so the JS will create a new RTCDataChannel.
		self.eventListener([
			"type": "datachannel",
			"channel": [
				"dcId": dcId,
				"label": rtcDataChannel.label,
				"ordered": rtcDataChannel.isOrdered,
				"maxPacketLifeTime": rtcDataChannel.maxRetransmitTime,
				"maxRetransmits": rtcDataChannel.maxRetransmits,
				"protocol": rtcDataChannel.`protocol`,
				"negotiated": rtcDataChannel.isNegotiated,
				"id": rtcDataChannel.streamId,
				"readyState": PluginRTCTypes.dataChannelStates[rtcDataChannel.readyState.rawValue] as String!,
				"bufferedAmount": rtcDataChannel.bufferedAmount
                ] as [String: Any]
		])
        
	}


	/**
	 * Methods inherited from RTCSessionDescriptionDelegate.
	 */


	func peerConnection(_ rtcPeerConnection: RTCPeerConnection!,
		didCreateSessionDescription rtcSessionDescription: RTCSessionDescription!, error: Error!) {
		if error == nil {
            self.onCreateDescriptionSuccessCallback(rtcSessionDescription)
//			self.onCreateDescriptionSuccessCallback(rtcSessionDescription: rtcSessionDescription)
		} else {
//			self.onCreateDescriptionFailureCallback(error: error)
            
            self.onCreateDescriptionFailureCallback(NSError())
		}
	}


	func peerConnection(_ peerConnection: RTCPeerConnection!,
		didSetSessionDescriptionWithError error: Error!) {
		if error == nil {
			self.onSetDescriptionSuccessCallback()
		} else {
			self.onSetDescriptionFailureCallback(NSError())
		}
	}
}
