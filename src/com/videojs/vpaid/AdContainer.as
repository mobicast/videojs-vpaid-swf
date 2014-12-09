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
            if (_durationTimer) {
                return _durationTimer.currentCount;
            }
            return _model.duration;
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
            if (playing && !paused) {
                _isPlaying = true;
                _isPaused = true;
                _durationTimer.stop();
                _vpaidAd.pauseAd();
                _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
            }
        }

        public function resumePlayingAd(): void {
            if (playing && paused) {
                _isPlaying = true;
                _isPaused = false;
                _durationTimer.start();
                _vpaidAd.resumeAd();
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
            }
        }
        
        private function onAdLoaded(): void {
            addChild(_vpaidAd);
            _vpaidAd.startAd();
        }

        private function onAdStarted(): void {
            startDurationTimer();
            _isPlaying = true;
            _isPaused = false;
        }
        
        private function onAdError(): void {
            _vpaidAd.stopAd();
        }
        
        private function onAdStopped(): void {
            if (!_hasEnded) {
                _isPlaying = false;
                _hasEnded = true;
                _vpaidAd = null;
                _model.broadcastEventExternally(ExternalEventName.ON_PLAYBACK_COMPLETE);
            }
        }
        
        public function loadAdAsset(): void {
            _loadStarted = true;
            var loader:Loader = new Loader();
            var loaderContext:LoaderContext = new LoaderContext();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(evt:Object): void {
                successfulCreativeLoad(evt);
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
        
        private function successfulCreativeLoad(evt: Object): void {

            _vpaidAd = evt.target.content.getVPAID();
            var duration = _vpaidAd.hasOwnProperty("adDuration") ? _vpaidAd.adDuration : 0,
                width    = _vpaidAd.hasOwnProperty("adWidth") ? _vpaidAd.adWidth : 0,
                height   = _vpaidAd.hasOwnProperty("adHeight") ? _vpaidAd.adHeight : 0;

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
                onAdLoaded();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdStopped, function():void {
                onAdStopped();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdError, function():void {
                onAdError();
            });

            _vpaidAd.addEventListener(VPAIDEvent.AdStarted, function():void {
                onAdStarted();
            });

            _vpaidAd.handshakeVersion("2.0");

            // Use stage rect because current ad implementations do not currently provide width/height.
            _vpaidAd.initAd(_model.stageRect.width, _model.stageRect.height, "normal", _model.bitrate, _model.adParameters);
        }

        private function adDurationComplete(evt: Object): void {
           if (_durationTimer) {
                _durationTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, adDurationComplete);
                _durationTimer = null;
           }
           onAdStopped();
        }
    }
}