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
        private var _idleTimer:Timer = new Timer(3000, 10);

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

        private function onAdSkipped(e:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdSkipped');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_SKIP);
        }

        private function onAdLoaded(e:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdLoaded');
            try {
                addChild(_displayObject);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "Unable to add vpaid to the stage", e);
            }

            _ackTimer.reset();
            _ackTimer.start();

            var duration:Number = -2;

            try {
                duration = _vpaidAd.adDuration;
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adDuration", e);
            }

            if (duration <= 0) {
                try {
                    duration = _vpaidAd.adRemainingTime;
                    ExternalInterface.call("console.debug", "vpaidcontainer", 'adRemainingTime', duration);
                } catch(e:Error) {
                    ExternalInterface.call("console.error", "vpaidcontainer", "unable get adRemainingTime", e);
                }
            }

            if (!isNaN(duration) && duration > 0) {
                _model.duration = duration;
            }

            try {
                ExternalInterface.call("console.debug", "vpaidcontainer", "startAd");
                _isPlaying = false;
                _isPaused = false;
                _vpaidAd.startAd();
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "startAd error", e);
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
            }
        }

        private function onAdStarted(e:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdStarted');
            _ackTimer.reset();

            _isPlaying = true;
            _isPaused = false;
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_CREATIVE_VIEW);
            _model.broadcastEventExternally(ExternalEventName.ON_START);
        }

        private function onAdError(e:Object): void {
            _ackTimer.reset();

            ExternalInterface.call("console.error", "vpaidcontainer", "VPAID::AdError", e);
            _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
            _vpaidAd.stopAd();
        }

        private function onAdStopped(e:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdStopped');
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

        private function onAdLog(evt:Object): void {
            //logType('log', evt);
            ExternalInterface.call("console.log", "vpaidcontainer", "AdLog", evt.data ? evt.data.message : "");
        }

        private function onAdDurationChange(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdDurationChange');
            var duration:Number = _vpaidAd.adDuration;
            if (!isNaN(duration) && duration > 0) {
                _model.duration = duration;
            }

            ExternalInterface.call("console.debug", "vpaidcontainer", 'adDuration: ', duration, ", model duration: ", _model.duration);
        }

        private function onAdVideoStart(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdVideoStart');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_START);
        }

        private function onAdVideoFirstQuartile(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdVideoFirstQuartile');
            onAdDurationChange(evt);
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_FIRST_QUARTILE);
        }

        private function onAdVideoMidpoint(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdVideoMidpoint');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_MIDPOINT);
        }

        private function onAdVideoThirdQuartile(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdVideoThirdQuartile');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_THIRD_QUARTILE);
        }

        private function onAdVideoComplete(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'AdVideoComplete');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_COMPLETE);
        }

        private function onAdClickThru(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'onAdClickThru');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_CLICK_TRACKING);
        }

        private function onAdUserAcceptInvitation(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'onAdUserAcceptInvitation');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_ACCEPT_INVITATION);
        }

        private function onAdUserMinimize(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'onAdUserMinimize');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_COLLAPSE);
        }

        private function onAdUserClose(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'onAdUserClose');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_CLOSE);
        }

        private function onAdPaused(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'onAdPaused');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_PAUSE);
        }

        private function onAdPlaying(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'onAdPlaying');
            _model.broadcastEventExternally(ExternalEventName.ON_VAST_RESUME);
        }

        private function onAckTimeout(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'ack timeout occured!', evt);
            _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_TIMEOUT);
        }

        private function onIdleCheck(evt:Object): void {
            if (playing) {
              ExternalInterface.call("console.debug", "vpaidcontainer", 'idle check: not idle, adDuration: ' + _vpaidAd.adDuration + ', adRemainingTime: ' + _vpaidAd.adRemainingTime);
              _idleTimer.reset();
              _idleTimer.start();
            } else {
              ExternalInterface.call("console.debug", "vpaidcontainer", 'idle check: IDLE, ticks: ' + _idleTimer.currentCount + '/' + _idleTimer.repeatCount);
            }
        }

        private function onIdleTimeout(evt:Object): void {
            ExternalInterface.call("console.debug", "vpaidcontainer", 'idle timeout occured!', evt);
            _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_TIMEOUT);
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

        private static function logType(objLabel:String, obj:*) {
            var info:String = describeType(obj);
            ExternalInterface.call("console.debug", "vpaidcontainer", "logType", objLabel, info);
        }

        private function successfulCreativeLoad(evt: Object): void {
            _ackTimer.reset();
            _ackTimer.start();

            try {
                _displayObject = evt.target.content;
                //logType('displayobject', _displayObject);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable to set display object", e);
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
                return;
            }

            try {
                var _ad:* = evt.target.content.getVPAID();
                //logType('vpaidObj', _ad);

                _vpaidAd = new VPAIDWrapper(_ad);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable to set VPAID wrapper", e);
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
                return;
            }

            var width:Number;

            try {
                width = _vpaidAd.adWidth;
                ExternalInterface.call("console.debug", "vpaidcontainer", 'adWidth', width);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adWidth", e);
            }

            if (!isNaN(width) && width > 0) {
                _model.width = width;
            }

            var height:Number;

            try {
                height = _vpaidAd.adHeight;
                ExternalInterface.call("console.debug", "vpaidcontainer", 'adHeight', height);
            } catch(e:Error) {
                ExternalInterface.call("console.error", "vpaidcontainer", "unable get adHeight", e);
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

            ExternalInterface.call("console.debug", "vpaidcontainer", 'request handshakeVersion');

            var ver:String = _vpaidAd.handshakeVersion("2.0");

            ExternalInterface.call("console.debug", "vpaidcontainer", "handshakeVersion", ver);

            if (ver.indexOf("1.") == 0) {
                try {
                    ExternalInterface.call("console.debug", "vpaidcontainer", "adLinear", _vpaidAd.adLinear);
                } catch(e:Error){
                    ExternalInterface.call("console.error", "vpaidcontainer", "adLinear error", e);
                    _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
                }
            }

            try {
                ExternalInterface.call("console.debug", "vpaidcontainer", "initAd", _model.bitrate, _model.adParameters);
                // Use stage rect because current ad implementations do not currently provide width/height.
                _vpaidAd.initAd(_model.stageRect.width, _model.stageRect.height, "normal", _model.bitrate, _model.adParameters, "");
            } catch(e:Error){
                ExternalInterface.call("console.error", "vpaidcontainer", "initAd error", e);
                _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
            }
        }
    }
}