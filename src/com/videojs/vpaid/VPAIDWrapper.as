package com.videojs.vpaid
{
  import flash.display.DisplayObject;
  import flash.external.ExternalInterface;
  import flash.events.EventDispatcher;
  import flash.events.Event;
  import com.videojs.events.VPAIDEvent;

  // Player wrapper for untyped loaded swf
  public class VPAIDWrapper extends EventDispatcher
  {
    private var _ad:*;
    public function VPAIDWrapper(ad:*) {
      _ad = ad;
    }

    // Properties
    public function get adLinear():Boolean {
      return _ad.adLinear;
    }
    public function get adExpanded():Boolean {
      return _ad.adExpanded;
    }
    public function get adRemainingTime():Number {
      return _ad.hasOwnProperty("adRemainingTime") ? _ad.adRemainingTime : -1;
    }
    public function get adVolume():Number {
      return _ad.adVolume;
    }
    public function set adVolume(value:Number):void {
      _ad.adVolume = value;
    }

    // 2.0 Properties
    public function get adWidth():Number {
      return _ad.hasOwnProperty("adWidth") ? _ad.adWidth: 0;
    }
    public function get adHeight():Number {
      return _ad.hasOwnProperty("adHeight") ? _ad.adHeight: 0;
    }
    public function get adDuration():Number {
      return _ad.hasOwnProperty("adDuration") ? _ad.adDuration : -1;
    }

    // Methods
    public function handshakeVersion(playerVPAIDVersion : String):String {
      return _ad.handshakeVersion(playerVPAIDVersion);
    }
    public function initAd(width:Number, height:Number, viewMode:String, desiredBitrate:Number,
      creativeData:String, environmentVars : String):void {
      _ad.initAd(width, height, viewMode, desiredBitrate, creativeData, environmentVars);
    }
    public function resizeAd(width:Number, height:Number, viewMode:String):void {
      _ad.resizeAd(width, height, viewMode);
    }
    public function startAd():void {
      _ad.startAd();
    }
    public function stopAd():void {
      _ad.stopAd();
    }
    public function pauseAd():void {
      _ad.pauseAd();
    }
    public function resumeAd():void {
      _ad.resumeAd();
    }
    public function expandAd():void {
      _ad.expandAd();
    }
    public function collapseAd():void {
      _ad.collapseAd();
    }
    // EventDispatcher overrides
    override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false,
      priority:int=0, useWeakReference:Boolean=false):void {
      _ad.addEventListener(type, listener, useCapture, priority, useWeakReference);
    }
    override public function removeEventListener(type:String, listener:Function,
      useCapture:Boolean=false):void {
      _ad.removeEventListener(type, listener, useCapture);
    }
    override public function dispatchEvent(event:Event):Boolean {
      return _ad.dispatchEvent(event);
    }
    override public function hasEventListener(type:String):Boolean {
      return _ad.hasEventListener(type);
    }
    override public function willTrigger(type:String):Boolean {
      return _ad.willTrigger(type);
    }
  }
}