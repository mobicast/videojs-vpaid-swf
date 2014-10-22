package com.videojs.providers{

    import flash.events.*;
    import com.videojs.vpaid.events.VPAIDEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    
    import flash.external.ExternalInterface;

    public class VPAIDAwareHTTPVideoProvider extends HTTPVideoProvider{
        
        public function VPAIDAwareHTTPVideoProvider(): void {
            super();
            
            _model.adView.addEventListener(VPAIDEvent.AdStopped, function():void {
                play();
            })
        }
        
        public override function play():void {
            if (_model.adView.hasPendingAdAsset) {
                return _model.adView.loadAdAsset();
            }
            
            super.play();
        }
    }
}
