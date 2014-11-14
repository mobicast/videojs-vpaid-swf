package com.videojs.providers{

    import com.videojs.vpaid.AdContainer;
    import com.videojs.vpaid.events.VPAIDEvent;
    import com.videojs.structs.ExternalEventName;

    public class VPAIDAwareHTTPVideoProvider extends HTTPVideoProvider{
        
        private var adContainer: AdContainer;

        public function VPAIDAwareHTTPVideoProvider(): void {
            super();
            adContainer = _model.adContainer;
            
            adContainer.addEventListener(VPAIDEvent.AdStopped, function(evt: Object):void {
                evt.currentTarget.removeEventListener(evt.type, arguments.callee);
                stop();
                play();
            })
        }
        
        public override function play(): void {
            if (adContainer.hasPlayingAdAsset) {
                pause();
                return;
            }

            if (adContainer.hasActiveAdAsset) {
                resume();
                return;
            }

            if (adContainer.hasPendingAdAsset) {
                adContainer.loadAdAsset();
                return;
            }

            super.play();
        }

        public override function pause(): void {
            if (adContainer.hasPlayingAdAsset) {
                adContainer.pausePlayingAd();
                _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
                return;
            }

            super.pause();
        }

        public override function resume(): void {
            if (adContainer.hasActiveAdAsset) {
                adContainer.resumePlayingAd();
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
                return;
            }

            super.resume();
        }
    }
}
