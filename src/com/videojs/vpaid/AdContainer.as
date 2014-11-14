package com.videojs.vpaid {
    
    import com.videojs.*;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.utils.Timer;
    import flash.events.*;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import com.videojs.vpaid.events.VPAIDEvent;

    public class AdContainer extends Sprite {
        
        private var _model: VideoJSModel;
        private var _creativeContent: Array;
        private var _vpaidAd: *;
        private var _adIsPlaying: Boolean = false;

        private var _durationTimer: Timer;
        private var _adDuration: Number;
        
        public function AdContainer(){
            _model = VideoJSModel.getInstance();
        }

        public function get hasPendingAdAsset(): Boolean {
            return _creativeContent.length > 0;
        }

        public function get hasActiveAdAsset(): Boolean {
            return _vpaidAd != null;
        }

        public function get hasPlayingAdAsset(): Boolean {
            return _adIsPlaying;
        }

        public function get duration(): Number {
            return _adDuration;
        }

        public function get remainingTime(): Number {
            return _durationTimer.currentCount;
        }
        
        public function init(adAssets: Array): void {
            _creativeContent = adAssets;
        }

        public function resize(width: Number, height: Number, viewMode: String): void {
            if (hasActiveAdAsset) {
                _vpaidAd.resizeAd(width, height, viewMode);
            }
        }

        protected function startDurationTimer(): void {
            _durationTimer = new Timer(1000, _adDuration);
            _durationTimer.addEventListener(TimerEvent.TIMER, adDurationTick);
            _durationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, adDurationComplete);
            _durationTimer.start();
        }

        public function pausePlayingAd(): void {
            _adIsPlaying = false;
            _durationTimer.stop();
            _vpaidAd.pauseAd();
        }

        public function resumePlayingAd(): void {
            _adIsPlaying = true;
            _durationTimer.start();
            _vpaidAd.resumeAd();
        }
        
        public function adStarted(): void {
            _adIsPlaying = true;
            startDurationTimer();
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStarted));
            _model.broadcastEventExternally(VPAIDEvent.AdPluginEventStart);

            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdImpression));
            _model.broadcastEventExternally(VPAIDEvent.AdPluginEventImpression);
        }
        
        public function adLoaded(): void {
            addChild(_vpaidAd);
            resize(stage.width, stage.height, "normal");
            _vpaidAd.startAd();
            adStarted();
        }
        
        private function adError(): void {
            _vpaidAd.stopAd();
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function adStopped(): void {
            _adIsPlaying = false;
            _vpaidAd = null;
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function loadAdAsset(): void {
            if (_creativeContent.length) {
                var asset: Object = _creativeContent.shift();
                loadCreative(asset);
            }
        }
        
        private function loadCreative(asset: Object): void {
            var loader:Loader = new Loader();
            var loaderContext:LoaderContext = new LoaderContext();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(evt:Object): void {
                succesfullCreativeLoad(evt, asset);
            });
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
                function(evt:SecurityErrorEvent): void {
                    //throwAdError('initError: Security error '+evt.text);
                });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, 
                function(evt:IOErrorEvent): void {
                    //throwAdError('initError: Error loading '+evt.text);
                });
            loader.load(new URLRequest(asset.path), loaderContext);
        }
        
        private function succesfullCreativeLoad(evt: Object, asset: Object): void {
            _vpaidAd = evt.target.content.getVPAID();
            _adDuration = asset.duration;
            
            _vpaidAd.addEventListener(VPAIDEvent.AdLoaded, function():void {
                adLoaded();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdStopped, function():void {
                adStopped();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdError, function():void {
                adError();
            });

            //TODO: get rid of hardcoded bitrate
            _vpaidAd.initAd(asset.width, asset.height, "normal", 800, "", "");
        }

        private function adDurationTick(evt: Object): void {
            _model.broadcastEventExternally(VPAIDEvent.AdPluginEventTimeRemaining); 

            if (_vpaidAd.adSkippableState) {
                _model.broadcastEventExternally(VPAIDEvent.AdPluginEventCanSkip); 
            }

        }

        private function adDurationComplete(evt: Object): void {
           if (_durationTimer) {
                _durationTimer.removeEventListener(TimerEvent.TIMER, adDurationTick);
                _durationTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, adDurationComplete);
                _durationTimer = null;
            }

            adStopped();
        }
    }
}