package  {
	
	import flash.display.MovieClip;
	
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.media.SoundMixer;
	
	import flash.net.URLRequest;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	
	public class playbackDoc extends MovieClip {
		
		public var s:Sound = new Sound();
		public var sc:SoundChannel;
		public var st:SoundTransform;
		public var bytes:ByteArray = new ByteArray();
		public var leftBase:Number = 100;
		public var rightBase:Number = 200;
		public var startX:Number = 200;
		public var visualization:Sprite = new Sprite();
		
		public function playbackDoc() {
			// constructor code
			this.addChild(visualization);
			
			var req:URLRequest = new URLRequest("./songs/The-Offspring - Kristy-Are-You-Doing-Okay.mp3");
			st = new SoundTransform(1, 0);
			var context:SoundLoaderContext = new SoundLoaderContext(4000, false);
			s.load(req, context);
			sc = s.play(0, 1, st);
			
			stop_btn.addEventListener(MouseEvent.CLICK, stopClick);
			this.addEventListener(Event.ENTER_FRAME, createVisualization);
		}
				
		public function createVisualization(ev:Event):void{
			//24 times per second get the computeSpectrum and build a visualization
			SoundMixer.computeSpectrum(bytes);
			
			visualization.graphics.clear();
			visualization.graphics.lineStyle(0.5, 0x00FF00, 1);
			visualization.graphics.moveTo(startX, leftBase);
			
			for(var L:Number=0; L<256; L++){
				//left channel
				visualization.graphics.lineTo(startX+L, bytes.readFloat() * 100 + leftBase);
			}
			
			visualization.graphics.lineStyle(0.5, 0xFF0000, 1);
			visualization.graphics.lineStyle(0.5, 0xFF0000, 1);
			visualization.graphics.beginFill(0xFF0000, 0.32);
			visualization.graphics.moveTo(startX, rightBase + 100);
			visualization.graphics.lineTo(startX, rightBase);
			
			for(var R:Number=256; R<512; R++){
				//right channel
				visualization.graphics.lineTo(startX+R-255, bytes.readFloat() * 100 + rightBase);
			}
				visualization.graphics.lineTo(startX+255, rightBase + 100);
				visualization.graphics.lineTo(startX, rightBase + 100);
				visualization.graphics.endFill();
		}
		
		public function stopClick(ev:MouseEvent):void{
			sc.stop();
			this.removeEventListener(Event.ENTER_FRAME, createVisualization);
		}
	}
	
}
