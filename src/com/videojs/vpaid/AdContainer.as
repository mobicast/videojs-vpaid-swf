package com.videojs.vpaid {

    import com.videojs.*;
    import com.videojs.structs.ExternalErrorEventName;
    import com.videojs.structs.ExternalEventName;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import flash.utils.*;
    import com.videojs.vpaid.VPAIDWrapper;
    import com.videojs.events.VPAIDEvent;

    public class AdContainer extends Sprite {

        private var _model: VideoJSModel;
        private var _src: String;
        private var _displayObject:DisplayObject;
        private var _vpaidAd:VPAIDWrapper;
        private var _isPlaying:Boolean = false;
        private var _isPaused:Boolean = true;
        private var _hasEnded:Boolean = false;
        private var _loadStarted:Boolean = false;
        private var _ackTimer:Timer = new Timer(20000, 1);
        private var _idleTimer:Timer = new Timer(3000, 5);
        private var _lastAdVolumne:Number;

        public function AdContainer(model:VideoJSModel){
            _model = model;
            _ackTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAckTimeout);
            _idleTimer.addEventListener(TimerEvent.TIMER, onIdleCheck);
            _idleTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onIdleTimeout);
        }

        public function get hasActiveAdAsset(): Boolean {
            return _vpaidAd != null;
        }

        public function get playing(): Boolean {
            return _isPlaying;
        }

        public function get paused(): Boolean {
            return _isPaused && !_hasEnded;
        }

        public function get ended(): Boolean {
            return _hasEnded;
        }

        public function get loadStarted(): Boolean {
            return _loadStarted;
        }

        public function get time(): Number {
            if (_model.duration > 0 &&
                hasActiveAdAsset &&
                _vpaidAd.adRemainingTime >= 0 &&
                !isNaN(_vpaidAd.adRemainingTime)) {
                return _model.duration - _vpaidAd.adRemainingTime;
            } else {
                return 0;
            }
        }

        public function set src(pSrc:String): void {
            _src = pSrc;
        }

        public function get src():String {
            return _src;
        }

        public function get adWidth():int{
            return hasActiveAdAsset ? _vpaidAd.adWidth : 0;
        }

        public function get adHeight():int{
            return hasActiveAdAsset ? _vpaidAd.adHeight : 0;
        }

        public function resize(width: Number, height: Number, viewMode: String = "normal"): void {
            if (hasActiveAdAsset) {
                _vpaidAd.resizeAd(width, height, viewMode);
            }
        }

        public function pausePlayingAd(): void {
            if (playing && !paused) {
                _isPlaying = true;
                _isPaused = true;
                _vpaidAd.pauseAd();
                _model.broadcastEventExternally(ExternalEventName.ON_PAUSE);
            }
        }

        public function resumePlayingAd(): void {
            if (playing && paused) {
                _isPlaying = true;
                _isPaused = false;
                _vpaidAd.resumeAd();
                _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
            }
        }

        private function onAdSkipped(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdSkipped');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_SKIP);
        }

        private function onAdLoaded(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdLoaded');
            try {
                addChild(_displayObject);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "Unable to add vpaid to the stage");
            }

            _ackTimer.reset();
            _ackTimer.start();

            var duration:Number = -2;

            try {
                duration = _vpaidAd.adDuration;
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adDuration");
            }

            if (duration <= 0) {
                try {
                    duration = _vpaidAd.adRemainingTime;
                    ExternalInterface.call("console.info", "vpaidcontainer", 'adRemainingTime', String(duration));
                } catch(e:Error) {
                    ExternalInterface.call("console.error", "vpaidcontainer", "unable get adRemainingTime");
                }
            }

            if (!isNaN(duration) && duration > 0) {
                _model.duration = duration;
            }

            try {
                _lastAdVolumne = _vpaidAd.adVolume;
                ExternalInterface.call("console.info", "vpaidcontainer", 'adVolumne', String(_lastAdVolumne));
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adVolumne");
            }

            try {
                ExternalInterface.call("console.info", "vpaidcontainer", "startAd", "volume: " + _model.volume);
                _isPlaying = false;
                _isPaused = false;
                _vpaidAd.adVolume = _model.volume;
                _vpaidAd.startAd();
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "startAd error");
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
            }
        }

        private function onAdStarted(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdStarted');
            _ackTimer.reset();

            _isPlaying = true;
            _isPaused = false;
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_CREATIVE_VIEW);
            _model.broadcastEventExternally(ExternalEventName.ON_START);
        }

        private function onAdError(e:Object): void {
            _ackTimer.reset();

            _isPlaying = false;
            _isPaused = false;
            _hasEnded = true;

            if (_vpaidAd != null) {
                _vpaidAd.stopAd();
                _vpaidAd = null;
            }

            _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);

            ExternalInterface.call("console.error", "vpaidcontainer", "VPAID::AdError", e);
        }

        private function onAdStopped(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdStopped');
            _ackTimer.reset();

            if (_hasEnded) {
                ExternalInterface.call("console.warn", "vpaidcontainer", "onAdStopped", "AdStopped called even though the VPAID has already ended!");
                return
            }

            _isPlaying = false;
            _isPaused = false;
            _hasEnded = true;
            _vpaidAd = null;
            _model.broadcastEventExternally(ExternalEventName.ON_PLAYBACK_COMPLETE);
        }

        private function onAdLog(evt: Object): void {
            ExternalInterface.call("console.log", "vpaidcontainer", "AdLog");
        }

        private function onAdDurationChange(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdDurationChange');
            var duration:Number = _vpaidAd.adDuration;
            if (!isNaN(duration) && duration > 0) {
                _model.duration = duration;
            }

            ExternalInterface.call("console.info", "vpaidcontainer", 'adDuration: ' + duration + ", model duration: " + _model.duration);
        }

        private function onAdImpression(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdImpression');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_IMPRESSION);
        }

        private function onAdVideoStart(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdVideoStart');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_START);
        }

        private function onAdVideoFirstQuartile(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdVideoFirstQuartile');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_FIRST_QUARTILE);
        }

        private function onAdVideoMidpoint(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdVideoMidpoint');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_MIDPOINT);
        }

        private function onAdVideoThirdQuartile(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdVideoThirdQuartile');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_THIRD_QUARTILE);
        }

        private function onAdVideoComplete(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdVideoComplete');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_COMPLETE);
        }

        private function onAdClickThru(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdClickThru');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_CLICK_TRACKING);
        }

        private function onAdUserAcceptInvitation(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdUserAcceptInvitation');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_ACCEPT_INVITATION);
        }

        private function onAdUserMinimize(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdUserMinimize');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_COLLAPSE);
        }

        private function onAdUserClose(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdUserClose');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_CLOSE);
        }

        private function onAdPaused(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdPaused');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_PAUSE);
        }

        private function onAdPlaying(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdPlaying');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_RESUME);
        }

        private function updateVolumnChange(evt: Object): void {
            if (_vpaidAd.adVolume > 0 && _lastAdVolumne == 0) {
              ExternalInterface.call("console.info", "vpaidcontainer", 'unmuted');
                _model.broadcastEventExternally(ExternalEventName.ON_VAST_UNMUTE);
            } else if (_vpaidAd.adVolume == 0 && _lastAdVolumne > 0) {
              ExternalInterface.call("console.info", "vpaidcontainer", 'muted');
                _model.broadcastEventExternally(ExternalEventName.ON_VAST_MUTE);
            }

            _lastAdVolumne = _vpaidAd.adVolume;
        }

        private function onAdVolumeChange(evt: Object): void {
            ExternalInterface.call("console.info", "vpaidcontainer", 'AdVolumeChange');
            updateVolumnChange(evt);
        }

        private function onAckTimeout(evt: Object): void {
            if (_vpaidAd) {
                ExternalInterface.call("console.warn", "vpaidcontainer", 'ack timeout occured, but noop as VPAID has stopped!');
            } else {
                ExternalInterface.call("console.info", "vpaidcontainer", 'ack timeout occured!');
            }

            _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_TIMEOUT);
        }

        private function onIdleCheck(evt: Object): void {
            if (!_vpaidAd) {
                ExternalInterface.call("console.warn", "vpaidcontainer", 'idle check: noop, VPAID has stopped!');
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_TIMEOUT);
                return;
            } else if (playing) {
              ExternalInterface.call("console.info", "vpaidcontainer", 'idle check: not idle, adDuration: ' + _vpaidAd.adDuration + ', adRemainingTime: ' + _vpaidAd.adRemainingTime + ', adVolumne: ' + _vpaidAd.adVolume);
              _idleTimer.reset();
              _idleTimer.start();
            } else {
              ExternalInterface.call("console.info", "vpaidcontainer", 'idle check: IDLE, ticks: ' + _idleTimer.currentCount + '/' + _idleTimer.repeatCount);
            }

            // piggyback volume check
            updateVolumnChange(evt);
        }

        private function onIdleTimeout(evt: Object): void {
            _isPlaying = false;
            _isPaused = false;
            _hasEnded = true;

            if (!_vpaidAd) {
                ExternalInterface.call("console.warn", "vpaidcontainer", 'idle timeout occured, but noop as VPAID has stopped!');
            } else {
                _vpaidAd = null;
                ExternalInterface.call("console.info", "vpaidcontainer", 'idle timeout occured!');
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_TIMEOUT);
            }
        }

        public function loadAdAsset(): void {
            _idleTimer.reset();
            _idleTimer.start();

            _ackTimer.reset();
            _ackTimer.start();

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
            _ackTimer.reset();
            _ackTimer.start();

            try {
                _displayObject = evt.target.content;
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable to set display object");
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
                return;
            }

            try {
                var _ad:* = evt.target.content.getVPAID();
                _vpaidAd = new VPAIDWrapper(_ad);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable to set VPAID wrapper");
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
                return;
            }

            var width:Number;

            try {
                width = _vpaidAd.adWidth;
                ExternalInterface.call("console.info", "vpaidcontainer", 'adWidth', width);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adWidth");
            }

            if (!isNaN(width) && width > 0) {
                _model.width = width;
            }

            var height:Number;

            try {
                height = _vpaidAd.adHeight;
                ExternalInterface.call("console.info", "vpaidcontainer", 'adHeight', height);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adHeight");
            }

            if (!isNaN(height) && height > 0) {
                _model.height = height;
            }

            _vpaidAd.addEventListener(VPAIDEvent.AdSkipped, onAdSkipped);

            _vpaidAd.addEventListener(VPAIDEvent.AdLoaded, onAdLoaded);

            _vpaidAd.addEventListener(VPAIDEvent.AdStopped, onAdStopped);

            _vpaidAd.addEventListener(VPAIDEvent.AdError, onAdError);

            _vpaidAd.addEventListener(VPAIDEvent.AdStarted, onAdStarted);

            _vpaidAd.addEventListener(VPAIDEvent.AdLog, onAdLog);

            _vpaidAd.addEventListener(VPAIDEvent.AdDurationChange, onAdDurationChange);

            _vpaidAd.addEventListener(VPAIDEvent.AdImpression, onAdImpression);

            _vpaidAd.addEventListener(VPAIDEvent.AdVideoStart, onAdVideoStart);

            _vpaidAd.addEventListener(VPAIDEvent.AdVideoFirstQuartile, onAdVideoFirstQuartile);

            _vpaidAd.addEventListener(VPAIDEvent.AdVideoMidpoint, onAdVideoMidpoint);

            _vpaidAd.addEventListener(VPAIDEvent.AdVideoThirdQuartile, onAdVideoThirdQuartile);

            _vpaidAd.addEventListener(VPAIDEvent.AdVideoComplete, onAdVideoComplete);

            _vpaidAd.addEventListener(VPAIDEvent.AdClickThru, onAdClickThru);

            _vpaidAd.addEventListener(VPAIDEvent.AdUserAcceptInvitation, onAdUserAcceptInvitation);

            _vpaidAd.addEventListener(VPAIDEvent.AdUserMinimize, onAdUserMinimize);

            _vpaidAd.addEventListener(VPAIDEvent.AdUserClose, onAdUserClose);

            _vpaidAd.addEventListener(VPAIDEvent.AdPaused, onAdPaused);

            _vpaidAd.addEventListener(VPAIDEvent.AdPlaying, onAdPlaying);

            _vpaidAd.addEventListener(VPAIDEvent.AdVolumeChange, onAdVolumeChange);

            var ver:String = _vpaidAd.handshakeVersion("2.0");

            ExternalInterface.call("console.info", "vpaidcontainer", "handshakeVersion", ver);

            /*if (ver.indexOf("1.") == 0) {
                try {
                    ExternalInterface.call("console.info", "vpaidcontainer", "adLinear", _vpaidAd.adLinear);
                } catch(e:Error){
                    ExternalInterface.call("console.error", "vpaidcontainer", "adLinear error");
                    _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
                }
            }*/

            try {
                // ExternalInterface.call("console.info", "vpaidcontainer", "initAd", String(_model.bitrate), JSON.stringify(_model.adParameters));
                ExternalInterface.call("console.info", "vpaidcontainer", "initAd", String(_model.bitrate));
                // Use stage rect because current ad implementations do not currently provide width/height.
                _vpaidAd.initAd(_model.stageRect.width, _model.stageRect.height, "normal", _model.bitrate, _model.adParameters, "");
            } catch(e:Error){
                ExternalInterface.call("console.error", "vpaidcontainer", "initAd error");
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
            }
        }
    }
}