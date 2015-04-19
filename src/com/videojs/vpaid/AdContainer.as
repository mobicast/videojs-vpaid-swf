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
    private var _vpaidAd:VPAIDWrapper;
    private var _isPlaying:Boolean = false;
    private var _isPaused:Boolean = true;
    private var _hasEnded:Boolean = false;
    private var _loadStarted:Boolean = false;

    public function AdContainer(model:VideoJSModel){
      _model = model;
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
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_SKIP);
    }

    private function onAdLoaded(e:Object): void {
      try {
        addChild(_vpaidAd.getWrappedAd);
      } catch(e:Error) {
        ExternalInterface.call("console.error", "vpaidcontainer", "Unable to add vpaid to the stage", e);
      }

      try {
        ExternalInterface.call("console.debug", "vpaidcontainer", "startAd");
        _vpaidAd.startAd();
      } catch(e:Error) {
        ExternalInterface.call("console.error", "vpaidcontainer", "startAd error", e);
        _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
      }
    }

    private function onAdStarted(e:Object): void {
      _isPlaying = true;
      _isPaused = false;
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_CREATIVE_VIEW);
      _model.broadcastEventExternally(ExternalEventName.ON_START);
    }

    private function onAdError(e:Object): void {
      _model.broadcastErrorEventExternally(ExternalErrorEventName.AD_CREATIVE_VPAID_ERROR);
      _vpaidAd.stopAd();
    }

    private function onAdStopped(e:Object): void {
      if (_hasEnded) {
        ExternalInterface.call("console.warn", "vpaidcontainer", "onAdStopped", "AdStopped called even though the VPAID has already ended!");
        return
      }

      _isPlaying = false;
      _hasEnded = true;
      _vpaidAd = null;
      _model.broadcastEventExternally(ExternalEventName.ON_PLAYBACK_COMPLETE);
    }

    private function onAdLog(e:Object): void {
      ExternalInterface.call("console.log", "vpaidcontainer", "AdLog", e);
    }

    private function onAdVideoStart(e:Object): void {
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_START);
    }

    private function onAdVideoFirstQuartile(e:Object): void {
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_FIRST_QUARTILE);
    }

    private function onAdVideoMidpoint(e:Object): void {
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_MIDPOINT);
    }

    private function onAdVideoThirdQuartile(e:Object): void {
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_THIRD_QUARTILE);
    }

    private function onAdVideoComplete(e:Object): void {
      _model.broadcastEventExternally(ExternalEventName.ON_VAST_COMPLETE);
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
      _vpaidAd = new VPAIDWrapper(evt.target.content.getVPAID());

      var duration:Number = _vpaidAd.adDuration || _vpaidAd.adRemainingTime,
        width:Number = _vpaidAd.adWidth,
        height:Number = _vpaidAd.adHeight;

      if (!isNaN(duration) && duration > 0) {
        _model.duration = duration;
      }
      if (!isNaN(width) && width > 0) {
        _model.width = width;
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

      _vpaidAd.addEventListener(VPAIDEvent.AdVideoStart, onAdVideoStart);

      _vpaidAd.addEventListener(VPAIDEvent.AdVideoFirstQuartile, onAdVideoFirstQuartile);

      _vpaidAd.addEventListener(VPAIDEvent.AdVideoMidpoint, onAdVideoMidpoint);

      _vpaidAd.addEventListener(VPAIDEvent.AdVideoThirdQuartile, onAdVideoThirdQuartile);

      _vpaidAd.addEventListener(VPAIDEvent.AdVideoComplete, onAdVideoComplete);

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