package com.videojs.providers{

    import flash.events.*;
	import com.videojs.events.VPAIDEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import flash.external.ExternalInterface;

    public class VPAIDAwareHTTPVideoProvider extends HTTPVideoProvider{
		
		public function VPAIDAwareHTTPVideoProvider(): void {
			super();
			
			_model.adView.addEventListener(VPAIDEvent.AdStopped, function() {
				play();
			})
		}
		
		public override function play():void{
            // if this is a fresh playback request
            if(!_loadStarted){
				if (_model.adView.hasPendingAdAsset) {
					_model.adView.loadAdAsset();
				} else {
					super.play();
				}
            }
        }
    }
}
