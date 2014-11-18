package com.videojs.providers{

    import com.videojs.VideoJSModel;
    import com.videojs.vpaid.AdContainer;
    import flash.media.Video;
    import flash.utils.ByteArray;

    public class VpaidProvider implements IProvider{

        protected var _adContainer: AdContainer;

        public function VpaidProvider(): void {
            _adContainer = VideoJSModel.getInstance().adContainer;
        }

        public function get loop():Boolean {
            return false;
        }

        public function set loop(pLoop:Boolean):void {
        }

        public function get time():Number {
            if (_adContainer.hasActiveAdAsset) {
                return _adContainer.remainingTime;
            } else {
                return 0;
            }
        }

        public function get duration():Number {
            if (_adContainer.hasActiveAdAsset) {
                return _adContainer.duration;
            } else {
                return 0;
            }
        }

        public function appendBuffer(bytes:ByteArray):void {}

        public function endOfStream():void {}

        public function abort():void {}

        public function get readyState():int {
            return 0;
        }

        public function get networkState():int {
            if(!_adContainer.loadStarted){
                return 0;
            }
            else{
                return 2;
            }
        }

        public function get buffered():Number {
            return 0;
        }

        public function get bufferedBytesEnd():int {
            return 0;
        }

        public function get bytesLoaded():int {
            return 0;
        }

        public function get bytesTotal():int {
            return 0;
        }

        public function get playing():Boolean {
            return _adContainer.playing;
        }

        public function get paused():Boolean {
            return _adContainer.paused;
        }

        public function get ended():Boolean {
            return _adContainer.ended;
        }

        public function get seeking():Boolean {
            return false;
        }

        public function get usesNetStream():Boolean {
            return false;
        }

        public function get metadata():Object {
            return {};
        }

        public function set src(pSrc:Object):void{
            init(pSrc, false);
        }

        public function get srcAsString():String{
            if(_adContainer.src != null){
                return _adContainer.src;
            }
            return "";
        }

        public function init(pSrc:Object, pAutoplay:Boolean):void {
            _adContainer.src = pSrc.path;
        }

        public function load():void{
            _adContainer.loadAdAsset();
        }

        public function play(): void {

            if(!_adContainer.loadStarted){
                load();
            }

            if (_adContainer.hasActiveAdAsset) {
                resume();
            }
        }

        public function pause(): void {
            if (_adContainer.playing) {
                _adContainer.pausePlayingAd();
                return;
            }
        }

        public function resume(): void {
            if (_adContainer.hasActiveAdAsset) {
                _adContainer.resumePlayingAd();
                return;
            }
        }

        public function seekBySeconds(pTime:Number):void {}
        public function seekByPercent(pPercent:Number):void {}
        public function stop():void {}
        public function attachVideo(pVideo:Video):void {};
        public function die():void {};
    }
}
