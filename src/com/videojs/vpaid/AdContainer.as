package com.videojs.vpaid {
    
    import com.videojs.*;
    import com.videojs.structs.ExternalEventName;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.utils.Timer;
    import flash.events.*;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import com.videojs.vpaid.events.VPAIDEvent;

    public class AdContainer extends Sprite {
        
        private var _model: VideoJSModel;
        private var _src: String;
        private var _vpaidAd: *;
        private var _isPlaying:Boolean = false;
        private var _isPaused:Boolean = true;
        private var _hasEnded:Boolean = false;
        private var _loadStarted:Boolean = false;
        private var _durationTimer: Timer;

        public function AdContainer(){
            _model = VideoJSModel.getInstance();
        }

        public function get hasActiveAdAsset(): Boolean {
            return _vpaidAd != null;
        }

        public function get playing(): Boolean {
            return _isPlaying;
        }

        public function get paused(): Boolean {
            return _isPaused;
        }

        public function get ended(): Boolean {
            return _hasEnded;
        }

        public function get loadStarted(): Boolean {
            return _loadStarted;
        }

        public function get remainingTime(): Number {
            return _durationTimer.currentCount;
        }

        public function set src(pSrc:String): void {
            _src = pSrc;
        }
        public function get src():String {
            return _src;
        }

        public function resize(width: Number, height: Number, viewMode: String = "normal"): void {
            if (hasActiveAdAsset) {
                _vpaidAd.resizeAd(width, height, viewMode);
            }
        }

        protected function startDurationTimer(): void {
            _durationTimer = new Timer(1000, _model.duration);
            _durationTimer.addEventListener(TimerEvent.TIMER_COMPLETE, adDurationComplete);
            _durationTimer.start();
        }

        public function pausePlayingAd(): void {
            _isPlaying = true;
            _isPaused = true;
            _durationTimer.stop();
            _vpaidAd.pauseAd();
            _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
        }

        public function resumePlayingAd(): void {
            _isPlaying = true;
            _isPaused = false;
            _durationTimer.start();
            _vpaidAd.resumeAd();
            _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
        }
        
        public function adStarted(): void {
            _isPlaying = true;
            _isPaused = false;
            startDurationTimer();
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStarted));
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdImpression));
        }
        
        public function adLoaded(): void {
            addChild(_vpaidAd);
            // Inform the model that the ad has loaded.
            _model.dispatchEvent(new VPAIDEvent(VPAIDEvent.AdLoaded));
            _vpaidAd.startAd();
            adStarted();
        }
        
        private function adError(): void {
            _vpaidAd.stopAd();
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function adStopped(): void {
            if (!_hasEnded) {
                _isPlaying = false;
                _hasEnded = true;
                _vpaidAd = null;
                dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
                _model.broadcastEventExternally(ExternalEventName.ON_PLAYBACK_COMPLETE);
            }
        }
        
        public function loadAdAsset(): void {
            _loadStarted = true;
            var loader:Loader = new Loader();
            var loaderContext:LoaderContext = new LoaderContext();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(evt:Object): void {
                succesfullCreativeLoad(evt);
            });
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
                function(evt:SecurityErrorEvent): void {
                    throw new Error(evt.text);
                });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, 
                function(evt:IOErrorEvent): void {
                    throw new Error(evt.text);
                });
            loader.load(new URLRequest(_src), loaderContext);
        }
        
        private function succesfullCreativeLoad(evt: Object): void {

            _vpaidAd = evt.target.content.getVPAID();
            var duration = _vpaidAd.adDuration,
                width = _vpaidAd.adWidth,
                height = _vpaidAd.adHeight;

            if (!isNaN(duration) && duration > 0) {
                _model.duration = duration;
            }
            if (!isNaN(width) && width > 0) {
                _model.width = width;
            }
            if (!isNaN(height) && height > 0) {
                _model.height = height;
            }

            _vpaidAd.addEventListener(VPAIDEvent.AdLoaded, function():void {
                adLoaded();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdStopped, function():void {
                adStopped();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdError, function():void {
                adError();
            });

            _vpaidAd.handshakeVersion("2.0");
            _vpaidAd.initAd(_model.width, _model.height, "normal", _model.bitrate, _model.adParameters);
        }

        private function adDurationComplete(evt: Object): void {
           if (_durationTimer) {
                _durationTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, adDurationComplete);
                _durationTimer = null;
           }
           adStopped();
        }
    }
}