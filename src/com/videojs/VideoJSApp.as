package com.videojs {
    
    import flash.display.Sprite;
	import com.videojs.util.AdContainer;
	import com.videojs.util.EncapsulatedURLLoader;
	import com.videojs.events.VideoJSEvent;
	
	import flash.external.ExternalInterface;
	
    public class VideoJSApp extends Sprite{
        
        private var _uiView:VideoJSView;
        private var _model:VideoJSModel;
		
        public function VideoJSApp(){
			ExternalInterface.call("console.log", "test")
			_model = VideoJSModel.getInstance();
			
			_model.addEventListener(VideoJSEvent.INIT_DONE, function(evt:Object):void {
				new EncapsulatedURLLoader(loaderInfo.parameters.adMetadataSource, postAdRequestInit);
			});
        }
		
		public function init():void {
			ExternalInterface.call("console.log", "test2")
			_uiView = new VideoJSView();
            addChild(_uiView);
		}
			
		
		private function postAdRequestInit(pSrc:Object): void {
			_model.adView.init(pSrc.path);
		}
        
        public function get model():VideoJSModel{
            return _model;
        }
    }
}