package com.videojs.providers{

    import flash.events.*;
    import com.videojs.vpaid.AdContainer;
    import com.videojs.vpaid.events.VPAIDEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import com.videojs.structs.ExternalEventName;
    
    import flash.external.ExternalInterface;

    public class VPAIDAwareHTTPVideoProvider extends HTTPVideoProvider{
        
        protected var adView: AdContainer;

        public function VPAIDAwareHTTPVideoProvider(): void {
            super();
            adView = _model.adView;
            
            adView.addEventListener(VPAIDEvent.AdStopped, function(evt: Object):void {
                evt.currentTarget.removeEventListener(evt.type, arguments.callee);
                stop();
                play();
            })
        }
        
        public override function play(): void {
            if (adView.hasPlayingAdAsset) {
                pause();
                return;
            }

            if (adView.hasActiveAdAsset) {
                resume();
                return;
            }

            if (adView.hasPendingAdAsset) {
                adView.loadAdAsset();
                return;
            }

            super.play();
        }

        public override function pause(): void {
            if (adView.hasPlayingAdAsset) {
                adView.pausePlayingAd();
                _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
                return;
            }

            super.pause();
        }

        public override function resume(): void {
            if (adView.hasActiveAdAsset) {
                adView.resumePlayingAd();
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
                return;
            }

            super.resume();
        }
    }
}
