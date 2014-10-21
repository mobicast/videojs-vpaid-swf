/**
 * Copyright (C) 2010 Brightcove, Inc.  All Rights Reserved.  No
 * use, copying or distribution of this work may be made except in
 * accordance with a valid license agreement from Brightcove, Inc.
 * This notice must be included on all copies, modifications and
 * derivatives of this work.
 *
 * Brightcove, Inc MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT
 * THE SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
 * NON-INFRINGEMENT. BRIGHTCOVE SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED
 * BY LICENSEE AS A RESULT OF USING, MODIFYING OR DISTRIBUTING THIS
 * SOFTWARE OR ITS DERIVATIVES.
 *
 * "Brightcove" is a trademark of Brightcove, Inc.
 **/
package {

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.system.Security;
    import flash.utils.Timer;

    /**
     * An example VPAID SWF.  This shows some of properties that can be overriden and events that
     * can be dispatched within a VPAID SWF.  To learn more about VPAID, please see
     * http://support.brightcove.com or http://www.iab.net/media/file/VPAIDFINAL51109.pdf
     */
    public class ExampleVPAID extends Sprite implements IVPAID {

        // NOTE for internal development at Brightcove.  Make sure to put changes to this file in the README
        
        // timer for deciding when the ad should end
        protected var timer:Timer;
        
        // the ad duration  
        protected var _adDuration:Number;
        
        // track how much time is left
        protected var timeRemaining:Number;
        
        // the width of the ad area as passed in to initAd()
        protected var initWidth:Number;
        
        // the height of the ad area as passed in to initAd()
        protected var initHeight:Number;
        
        // the view mode for the ad as passed in to initAd() or resizeAd()
        private var viewMode:String;
        
        // the FakeAd we use for display
        private var fakeAd:FakeAd;
        
        // whether or not the ad is linear. default is false (non-linear).
        // change this variable value to adjust the ad type for testing.
        protected var isLinearAd:Boolean = false;
        
        // VPAID version of this ad
        private static const VPAID_VERSION:String = "2.0";                
        
        public function ExampleVPAID() {            
            // As noted in the VPAID specification: "To implement unidirectional scripting in 
            // ActionScript 3, use Security.allowDomain(“<playerdomain or *>”). The ad swf 
            // must also be served from a domain whhere /crossdomain.xml allows the ad swf 
            // to be loaded by the player domain or *."            
            Security.allowDomain("*"); 
            // ignore mouse events here and instead have FakeAd handle them 
            mouseEnabled = false;            
        }

        /**
         * VPAID function.  Returns the real VPAID object, which is this object for the 
         * example.  
         */
        public function getVPAID():Object {
            return this;
        }
        
        /**
         * VPAID function.
         */ 

        public function get adLinear():Boolean {            
            return true;            
        }

        public function get adWidth():Number {            
            return 0;            
        }

        public function get adHeight():Number {            
            return 0;            
        }

        public function get adCompanions():String {            
            return "";            
        }

        public function get adIcons():Boolean {            
            return false;            
        }

        /**
         * VPAID function.  This ad is never expanded
         */                
        public function get adExpanded():Boolean {
            return false;            
        }
              
        public function get adSkippableState():Boolean {
            if (timer.currentCount < 5) return false;
            return true;
        }
        
        /**
         * VPAID function.  Returns the amount of time left in the ad play. 
         */                
        public function get adRemainingTime():Number {
            return timeRemaining;            
        }

        /**
         * VPAID function.  Returns the amount of time left in the ad play. 
         */                
        public function get adDuration():Number {
            return _adDuration;            
        }
        
        /**
         * VPAID function.  This ad never has a volume 
         */                
        public function get adVolume():Number {
            return -1;
        }

        /**
         * VPAID function.  This ad never has a volume 
         */                
        public function set adVolume(value:Number):void {
        }
        
        /**
         * VPAID function.  
         */                
        public function handshakeVersion(playerVPAIDVersion:String):String {
            log("The player supports VPAID version " + playerVPAIDVersion + " and the ad supports " + 
                VPAID_VERSION);
            // "1.0" MUST be returned for the VPAID version, otherwise the ad won't play.
            return VPAID_VERSION;
        }
        
        /**
         * Logs a message using the player's logging functionality which shows the message
         * here: http://admin.brightcove.com/viewer/BrightcoveDebugger.html
         */
        protected function log(mesg:String):void {
            var data:Object = { "message":mesg };
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdLog, data));            
        }
        
        /**
         * VPAID function.  
         */                
        public function initAd(initWidth:Number, initHeight:Number, viewMode:String, desiredBitrate:Number, 
            creativeData:String, environmentVars:String):void {
                
            // Uncomment the below if you'd like to use the <Duration> element in VAST to dynamically
            // set the duration of your VPAID ad.
            //getDurationValue(creativeData);
            resizeAd(initWidth, initHeight, viewMode);
            loadAd();
        }
        
        /**
        * Retrieves the VAST Duration, which is passed to VPAID via creativeData.
        */
        private function getDurationValue(creativeData:String):void {
            var startIndex:Number = creativeData.indexOf("duration=");
            var endIndex:Number = creativeData.indexOf(";");
            _adDuration = Number(creativeData.substring(startIndex + 9, endIndex));
        }

        /**
         * Load the needed libraries and an ad.  Nothing needs to be loaded in this example, 
         * since we don't have a real ad or library to load.  So we dispatch AdLoaded right away.  
         */
        protected function loadAd():void {
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdLoaded));
        }

        /**
         * VPAID function.  
         */                        
        public function startAd():void {
            log("Beginning the display of the example VPAID ad");

            // Get our fake ad instead of getting it from a Loader
            fakeAd = new FakeAd(0x4DB3B1, 0x38470B," I'm a VPAID Ad!");
            fakeAd.mouseEnabled = true;
            fakeAd.addEventListener(MouseEvent.CLICK, onAdClick);
            positionFakeAd();
            addChild(fakeAd);

            // After the ad is loaded and displayed, let the player know that the ad has started           
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStarted));
            // Since there's no video to buffer and the ad is displayed, we can also send on
            // the impression event at this point
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdImpression));
            
            // End the ad after 15 seconds.  This code is usually not needed and an ad ending 
            // will be managed a different way.  Usually the ad will send an event or 
            // disappear when it's done. This line can also be commented out if you choose
            // to pass the ad duration to VPAID via creativeData in initAd().
            _adDuration = 15;

            timer = new Timer(1000, _adDuration);
            timer.addEventListener(TimerEvent.TIMER, onTimer);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerComplete);
            timer.start();            
        }
        
        /**
        * Called every time the ad duration timer counts down one second.
        */
        protected function onTimer(pEvent:TimerEvent):void {
            timeRemaining--;
        }
        
        /**
         * Handler for clicking on ad, which dispatches an event for the player to handle
         * the click-thru
         */
        protected function onAdClick(event:MouseEvent):void {
            var data:Object = { "playerHandles":true };
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdClickThru, data));            
        }

        /**
         * Called to end the ad.  stopAd() is called because the ad is done
         */
        protected function timerComplete(event:Event):void {
            stopAd();
        }        
         
        /**
         * VPAID function.  You can use the stopAd() function to cleanup anything when 
         * the ad is done. The player may call stopAd() for you if needed.
         */
        public function stopAd():void {
            log("Stopping the display of the VPAID Ad");
            // stop the Timer since we're already at ad complete
            if (timer) {
                timer.removeEventListener(TimerEvent.TIMER, onTimer);
                timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerComplete);
                timer = null;
            }
            if (fakeAd) {
                removeChild(fakeAd);
                fakeAd = null;
            }
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdStopped));
        }

        public function skipAd():void {
            dispatchEvent(new VPAIDEvent(VPAIDEvent.AdSkipped));
            stopAd();
        }
                        
        /**
         * VPAID function.  
         */                                
        public function resizeAd(width:Number, height:Number, viewMode:String):void {
            log("resizeAd() width=" + width + ", height=" + height + ", viewMode=" + viewMode);             
            this.initWidth = width;
            this.initHeight = height;
            // nothing is done with viewMode in this ad, but we save the value anyways
            this.viewMode = viewMode;
            // resize the ad 
            positionFakeAd();
        }
        
        /**
         * Position FakeAd with the initWidth and initHeight.  The ad is put in the middle 
         * of the available area
         */
        protected function positionFakeAd():void {
            if (fakeAd) {
                var widthAndHeight:Number = Math.min(initHeight, initWidth);
                fakeAd.width = widthAndHeight; 
                fakeAd.height = widthAndHeight;
                fakeAd.x = (initWidth / 2) - (widthAndHeight / 2);
                fakeAd.y = (initHeight / 2) - (widthAndHeight / 2);
            }
        }
        
        /**
         * VPAID function.  Pauses the ad if necessary.  
         */                
        public function pauseAd():void {
            if (timer) {
                timer.stop();
            }
        }
        
        /**
         * VPAID function.  Resumes the ad if necessary.  
         */                
        public function resumeAd():void {
            if (timer) {
                timer.start();
            }
        }
        
        /**
         * VPAID function.  Nothing to expand in this ad  
         */                
        public function expandAd():void {
        }
        
        /**
         * VPAID function.  Nothing to collapse in this ad  
         */                
        public function collapseAd():void {            
        }        
    }
}

