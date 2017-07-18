import Foundation


class PluginMediaStream : NSObject {
	var rtcMediaStream: RTCMediaStream
	var id: String
	var audioTracks: [String : PluginMediaStreamTrack] = [:]
	var videoTracks: [String : PluginMediaStreamTrack] = [:]
	var eventListener: ((_ data: NSDictionary) -> Void)?
	var eventListenerForAddTrack: ((_ pluginMediaStreamTrack : PluginMediaStreamTrack) -> Void)?
	var eventListenerForRemoveTrack: ((_ id: String) -> Void)?


	/**
	 * Constructor for pc.onaddstream event and getUserMedia().
	 */
	init(rtcMediaStream: RTCMediaStream) {
		NSLog("PluginMediaStream#init()")

		self.rtcMediaStream = rtcMediaStream
		// ObjC API does not provide id property, so let's set a random one.
		self.id = rtcMediaStream.streamId + "-" + UUID().uuidString

		for track: RTCMediaStreamTrack in (self.rtcMediaStream.audioTracks as! Array<RTCMediaStreamTrack>) {
			let pluginMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track)

			pluginMediaStreamTrack.run()
			self.audioTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}

		for track: RTCMediaStreamTrack in (self.rtcMediaStream.videoTracks as! Array<RTCMediaStreamTrack>) {
			let pluginMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track)

			pluginMediaStreamTrack.run()
			self.videoTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}
	}


	deinit {
		NSLog("PluginMediaStream#deinit()")
	}


	func run() {
		NSLog("PluginMediaStream#run()")

		//self.rtcMediaStream.delegate = self
	}


	func getJSON() -> NSDictionary {
		let json: NSMutableDictionary = [
			"id": self.id,
			"audioTracks": NSMutableDictionary(),
			"videoTracks": NSMutableDictionary()
		]

		for (id, pluginMediaStreamTrack) in self.audioTracks {
			(json["audioTracks"] as! NSMutableDictionary)[id] = pluginMediaStreamTrack.getJSON()
		}

		for (id, pluginMediaStreamTrack) in self.videoTracks {
			(json["videoTracks"] as! NSMutableDictionary)[id] = pluginMediaStreamTrack.getJSON()
		}

		return json as NSDictionary
	}


	func setListener(
		_ eventListener: @escaping (_ data: NSDictionary) -> Void,
		eventListenerForAddTrack: ((_ pluginMediaStreamTrack: PluginMediaStreamTrack) -> Void)?,
		eventListenerForRemoveTrack: ((_ id: String) -> Void)?
	) {
		NSLog("PluginMediaStream#setListener()")

		self.eventListener = eventListener
		self.eventListenerForAddTrack = eventListenerForAddTrack
		self.eventListenerForRemoveTrack = eventListenerForRemoveTrack
	}


	func addTrack(_ pluginMediaStreamTrack: PluginMediaStreamTrack) {
		NSLog("PluginMediaStream#addTrack()")

		if pluginMediaStreamTrack.kind == "audio" {
            self.rtcMediaStream.addAudioTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCAudioTrack)
            NSLog("PluginMediaStream#addTrack() | audio track added")
            self.audioTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		} else if pluginMediaStreamTrack.kind == "video" {
            self.rtcMediaStream.addVideoTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCVideoTrack)
            NSLog("PluginMediaStream#addTrack() | video track added")
            self.videoTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack
		}
	}


	func removeTrack(_ pluginMediaStreamTrack: PluginMediaStreamTrack) {
		NSLog("PluginMediaStream#removeTrack()")

		if pluginMediaStreamTrack.kind == "audio" {
			self.audioTracks[pluginMediaStreamTrack.id] = nil
            self.rtcMediaStream.removeAudioTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCAudioTrack)
            NSLog("PluginMediaStream#removeTrack() | audio track removed")
		} else if pluginMediaStreamTrack.kind == "video" {
			self.videoTracks[pluginMediaStreamTrack.id] = nil
            self.rtcMediaStream.removeVideoTrack(pluginMediaStreamTrack.rtcMediaStreamTrack as! RTCVideoTrack)
            NSLog("PluginMediaStream#removeTrack() | video track removed")
		}
	}


	/**
	 * Methods inherited from RTCMediaStreamDelegate.
	 */

    /*

	func onAddAudioTrack(_ rtcMediaStream: RTCMediaStream!, track: RTCMediaStreamTrack!) {
		NSLog("PluginMediaStream | OnAddAudioTrack [label:%@]", String(track.label))

		let pluginMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track)

		pluginMediaStreamTrack.run()
		self.audioTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack

		if self.eventListener != nil {
			self.eventListenerForAddTrack!(pluginMediaStreamTrack)

			self.eventListener!([
				"type": "addtrack",
				"track": pluginMediaStreamTrack.getJSON()
			])
		}
	}


	func onAddVideoTrack(_ rtcMediaStream: RTCMediaStream!, track: RTCMediaStreamTrack!) {
		NSLog("PluginMediaStream | OnAddVideoTrack [label:%@]", String(track.label))

		let pluginMediaStreamTrack = PluginMediaStreamTrack(rtcMediaStreamTrack: track)

		pluginMediaStreamTrack.run()
		self.videoTracks[pluginMediaStreamTrack.id] = pluginMediaStreamTrack

		if self.eventListener != nil {
			self.eventListenerForAddTrack!(pluginMediaStreamTrack)

			self.eventListener!([
				"type": "addtrack",
				"track": pluginMediaStreamTrack.getJSON()
			])
		}
	}


	func onRemoveAudioTrack(_ rtcMediaStream: RTCMediaStream!, track: RTCMediaStreamTrack!) {
		NSLog("PluginMediaStream | OnRemoveAudioTrack [label:%@]", String(track.label))

		// It may happen that track was removed due to user action (removeTrack()).
		if self.audioTracks[track.label] == nil {
			return
		}

		self.audioTracks[track.label] = nil

		if self.eventListener != nil {
			self.eventListenerForRemoveTrack!(track.label)

			self.eventListener!([
				"type": "removetrack",
				"track": [
					"id": track.label,
					"kind": "audio"
				]
			])
		}
	}


	func onRemoveVideoTrack(_ rtcMediaStream: RTCMediaStream!, track: RTCMediaStreamTrack!) {
		NSLog("PluginMediaStream | OnRemoveVideoTrack [label:%@]", String(track.label))

		// It may happen that track was removed due to user action (removeTrack()).
		if self.videoTracks[track.label] == nil {
			return
		}

		self.videoTracks[track.label] = nil

		if self.eventListener != nil {
			self.eventListenerForRemoveTrack!(track.label)

			self.eventListener!([
				"type": "removetrack",
				"track": [
					"id": track.label,
					"kind": "video"
				]
			])
		}
	}
 */
}
