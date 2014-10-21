package com.videojs {
    
    import flash.display.Sprite;
	import com.videojs.vpaid.AdContainer;
	import com.videojs.util.CreativeSourceLoader;
	import com.videojs.events.VideoJSEvent;
	
    public class VideoJSApp extends Sprite{
        
        private var _uiView:VideoJSView;
        private var _model:VideoJSModel;
		
        public function VideoJSApp(){
			_model = VideoJSModel.getInstance();
			
			_model.addEventListener(VideoJSEvent.INIT_DONE, function(evt:Object):void {
				new CreativeSourceLoader(loaderInfo.parameters.adMetadataSource, postAdRequestInit);
			});
        }
		
		public function init():void {
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