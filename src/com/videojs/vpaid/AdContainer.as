package com.videojs.vpaid {
    
    import com.videojs.*;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.*;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import com.videojs.vpaid.events.VPAIDEvent;
    import com.videojs.structs.ExternalEventName;

    public class AdContainer extends Sprite {
        
        private var _uiView: VideoJSView;
        private var _model: VideoJSModel;
        private var _creativeContent: Array;
        private var _vpaidAd: *;
        
        public function AdContainer(model: VideoJSModel){
            _model = model;
        }
        
        public function init(adAssets: Array):void {
            _creativeContent = adAssets;
        }
        
        public function adStarted(): void {
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStarted));
            _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
        }
        
        public function adLoaded(): void {
            addChild(_vpaidAd);
            _vpaidAd.resizeAd(stage.width, stage.height, "normal");
            _vpaidAd.startAd();
            adStarted();
        }
        
        private function adError(): void {
            _vpaidAd.stopAd();
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function adStopped(): void {
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function get hasPendingAdAsset(): Boolean {
            return _creativeContent.length > 0;
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
            
            _vpaidAd.addEventListener(VPAIDEvent.AdLoaded, function() {
                adLoaded();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdStopped, function() {
                adStopped();
            });
            
            _vpaidAd.addEventListener(VPAIDEvent.AdError, function() {
                adError();
            });

            //TODO: get rid of hardcoded bitrate
            _vpaidAd.initAd(asset.width, asset.height, "normal", 800, "", "");
        }
    }
}