package
{
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;    
    /**
     * Displays a happy ad.  Normally you would load in another ad server SWF or load in an ad using 
     * the Loader class.  Instead, we just draw something without a load, since this is an example. 
     */
    public class FakeAd extends Sprite {

        // NOTE for internal Brightcove development: make sure to make the same changes to the other
        // FakeAd classes
        
        public function FakeAd(lineColor:Number, fillColor:Number, label:String) {
            graphics.lineStyle(2, lineColor);
            graphics.beginFill(fillColor);
            graphics.drawCircle(150, 150, 140);
            graphics.moveTo(50, 170);
            graphics.lineTo(110, 220);
            graphics.curveTo(160, 270, 210, 210);
            graphics.lineTo(260, 170);
            graphics.drawCircle(200, 70, 20);
            graphics.drawCircle(110, 70, 20);
            graphics.endFill();
            
            var format:TextFormat = new TextFormat();
            format.font = "Verdana";
            format.color = lineColor;
            format.size = 12;
            format.align =  "center";
            
            var textField:TextField = new TextField();
            textField.x = 50;
            textField.y = 110;
            textField.width = 200;
            textField.wordWrap = true;
            textField.autoSize = TextFieldAutoSize.LEFT;
            textField.text = label;
            textField.setTextFormat(format);
            addChild(textField);
        }        
    }
}
