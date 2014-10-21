package com.videojs.util {
    import flash.events.*
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.external.ExternalInterface;

    public class CreativeSourceLoader {
        protected var _callback:Function;
        protected var adSource: String = "";

        public function CreativeSourceLoader(source: String, callback: Function) {
            _callback = callback;
            var adCreativeLoader: URLLoader = new URLLoader();
            adCreativeLoader.addEventListener(Event.COMPLETE, creativeLoadComplete);
            adCreativeLoader.addEventListener(IOErrorEvent.IO_ERROR, creativeLoadFailure);
            adCreativeLoader.load(new URLRequest(source));
        }

        private function creativeLoadComplete(e:Event): void {
            e.target.removeEventListener(Event.COMPLETE, creativeLoadComplete);
            parseAdSource(e.target.data)
        }
        
        private function creativeLoadFailure(e:Event): void {
            
        }
        
        private function parseAdSource(source:String): void {
            var xmlData:XML = null;
            var creativeData:String = source;
            if (creativeData != null) {
                try {
                    xmlData = new XML(creativeData);
                    adSource = xmlData.descendants().(name() == "MediaFile").text()
                } catch(e:Error) {
                    //ExternalInterface.call("console.log", e.message)
                }
            } else {
                //ExternalInterface.call("console.log", "nothing to load")
            }
            
            _callback.call(null, {
                path: adSource
            });
        }
    }
}