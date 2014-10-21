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
        
        private var _uiView:VideoJSView;
        private var _model:VideoJSModel;
        private var _creativePath:String;
        private var _creativeData:*;
        
        public function AdContainer(model: VideoJSModel){
            _model = model;
        }
        
        public function init(path: String):void {
            _creativePath = path;
        }
        
        public function adStarted(): void {
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStarted));
            _model.broadcastEventExternally(ExternalEventName.ON_RESUME);
        }
        
        public function adLoaded(): void {
            addChild(_creativeData);
            _creativeData.startAd();
            adStarted();
        }
        
        private function adError(): void {
            _creativeData.stopAd();
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function adStopped(): void {
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }
        
        public function get hasPendingAdAsset():Boolean {
            return _creativePath.length > 0 && !_creativeData;
        }
        
        public function loadAdAsset():void {
            if (_creativePath) {
                loadCreative(_creativePath);
            }
        }
        
        private function loadCreative(path: String):void {
            var loader:Loader = new Loader();
            var loaderContext:LoaderContext = new LoaderContext();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, succesfullCreativeLoad );
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
                function(evt:SecurityErrorEvent):void {
                    //throwAdError('initError: Security error '+evt.text);
                });
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, 
                function(evt:IOErrorEvent):void {
                    //throwAdError('initError: Error loading '+evt.text);
                });
            loader.load(new URLRequest(path), loaderContext);
        }
        
        private function succesfullCreativeLoad(evt:Object):void {
            _creativeData = evt.target.content;
            
            _creativeData.addEventListener(VPAIDEvent.AdLoaded, function() {
                adLoaded();
            });
            
            _creativeData.addEventListener(VPAIDEvent.AdStopped, function() {
                adStopped();
            });
            
            _creativeData.addEventListener(VPAIDEvent.AdError, function() {
                adError();
            });
            
            //TODO: get rid of hardcoded values
            _creativeData.initAd(600, 350, "normal", 800,  "foobar", "param1, param2");
        }
    }
}