package com.videojs.vpaid {
	public interface VPAIDTrait {
		function init(path: String) : void;
		//function get adRemainingTime() : Number;
		function adStarted() : void;
		//function adStopped() : void;
		//function addPaused() : void;
		//function adResumed() : void;
	}
}