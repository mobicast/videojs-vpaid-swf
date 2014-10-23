package com.videojs.util {
    import flash.events.*
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.external.ExternalInterface;
    import flash.utils.getQualifiedClassName;

    public class CreativeSourceLoader {
        protected var _callback:Function;

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
                    var creatives: XMLList = xmlData.descendants().(name() == "Creatives");

                    var adSource: Array = [];
                    for each (var creative: XML in creatives.Creative) {
                        //support only linear for now
                        if (!creative.Linear.MediaFiles.length()) {
                            continue;
                        }

                        var rawDuration: Array = creative.descendants().(name() == "Duration").text()
                            .split(":")
                            .map(function(s:*, idx:int, arr:Array): Number {
                                if (idx == 0) return parseInt(s, 10) * 3600;
                                if (idx == 1) return parseInt(s, 10) * 60;
                                return parseInt(s, 10);
                            })

                        var creativeMedia: XMLList = creative.descendants().(name() == "MediaFiles");

                        var duration: Number = 0;
                        for (var dur:String in rawDuration) duration += rawDuration[dur];

                        for each(var file:XML in creativeMedia.children()) {
                            adSource.push({
                                path: file.text().toString(),
                                height: file.@height,
                                width: file.@width,
                                type: file.@type,
                                duration: duration,
                                creativeSource: creative.toXMLString()
                            })
                        }
                    }

                    _callback.call(null, adSource);
                } catch(e:Error) {
                    //ExternalInterface.call("console.log", e.message)
                }
            } else {
                //ExternalInterface.call("console.log", "nothing to load")
            }
        }
    }
}